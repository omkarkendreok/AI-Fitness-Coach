// lib/screens/exercise_screen.dart
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

import '../utils/rep_counter.dart';
import '../widgets/pose_painter.dart';
import '../services/db_service.dart';
import '../services/auth_service.dart';

class ExerciseScreen extends StatefulWidget {
  final String exercise;
  const ExerciseScreen({super.key, required this.exercise});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  CameraController? _camera;
  late PoseDetector _poseDetector;
  bool _isProcessing = false;
  bool _useFrontCamera = false;
  Pose? _currentPose;
  Size? _currentImageSize;
  RepCounter? _counter;
  final FlutterTts tts = FlutterTts();

  int reps = 0;
  String form = "unknown";
  String suggestion = "";

  @override
  void initState() {
    super.initState();
    _counter = RepCounter(exercise: widget.exercise);
    _poseDetector =
        PoseDetector(options: PoseDetectorOptions(mode: PoseDetectionMode.stream));
    tts.setSpeechRate(0.5);
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cams = await availableCameras();
    final chosen = _useFrontCamera
        ? cams.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
            orElse: () => cams.first)
        : cams.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
            orElse: () => cams.first);

    await _camera?.dispose();

    _camera = CameraController(
      chosen,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _camera!.initialize();

    _camera!.startImageStream((CameraImage img) {
      if (!_isProcessing) _handleCameraImage(img);
    });

    if (mounted) setState(() {});
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final int total = planes.fold<int>(0, (s, p) => s + p.bytes.length);
    final bytes = Uint8List(total);
    int offset = 0;
    for (final p in planes) {
      bytes.setRange(offset, offset + p.bytes.length, p.bytes);
      offset += p.bytes.length;
    }
    return bytes;
  }

  Uint8List yuv420ToNv21(CameraImage image) {
    final int width = image.width;
    final int height = image.height;

    final int yPlaneLength = width * height;
    final int totalLength = (width * height * 3 / 2).toInt();
    final nv21Buffer = Uint8List(totalLength);

    final yPlane = image.planes[0];
    if (yPlane.bytes.length == yPlaneLength) {
      nv21Buffer.setRange(0, yPlaneLength, yPlane.bytes);
    } else {
      int dstOffset = 0;
      final bytesPerRow = yPlane.bytesPerRow;
      final heightPlane = image.height;
      for (int row = 0; row < heightPlane; row++) {
        final rowStart = row * bytesPerRow;
        nv21Buffer.setRange(dstOffset, dstOffset + width,
            yPlane.bytes.sublist(rowStart, rowStart + width));
        dstOffset += width;
      }
    }

    final planeU = image.planes.length > 1 ? image.planes[1] : null;
    final planeV = image.planes.length > 2 ? image.planes[2] : null;

    int chromaOffset = yPlaneLength;

    if (planeU == null || planeV == null) return nv21Buffer;

    for (int row = 0; row < height ~/ 2; row++) {
      final int vRowStart = row * planeV.bytesPerRow;
      final int uRowStart = row * planeU.bytesPerRow;

      for (int col = 0; col < width ~/ 2; col++) {
        final int vIndex = vRowStart + col * (planeV.bytesPerPixel ?? 1);
        final int uIndex = uRowStart + col * (planeU.bytesPerPixel ?? 1);

        nv21Buffer[chromaOffset++] = planeV.bytes[vIndex];
        nv21Buffer[chromaOffset++] = planeU.bytes[uIndex];
      }
    }

    return nv21Buffer;
  }

  Future<void> _handleCameraImage(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final size = Size(image.width.toDouble(), image.height.toDouble());
      final sensorOrientation = _camera?.description.sensorOrientation ?? 0;
      final rotation =
          InputImageRotationValue.fromRawValue(sensorOrientation) ??
              InputImageRotation.rotation0deg;

      final format = InputImageFormatValue.fromRawValue(image.format.raw) ??
          InputImageFormat.nv21;

      Uint8List bytes = (image.planes.length == 1)
          ? image.planes.first.bytes
          : yuv420ToNv21(image);

      final metadata = InputImageMetadata(
        size: size,
        rotation: rotation,
        format: format,
        bytesPerRow:
            image.planes.isNotEmpty ? image.planes[0].bytesPerRow : image.width,
      );

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: metadata,
      );

      final poses = await _poseDetector.processImage(inputImage);

      _currentImageSize = size;

      if (poses.isNotEmpty) {
        final pose = poses.first;
        _currentPose = pose;

        final result = _counter!.processPose(pose);

        setState(() {
          reps = result['reps'] ?? reps;
          form = result['form'] ?? form;
          suggestion = result['suggestion'] ?? '';
        });

        if (suggestion.isNotEmpty) tts.speak(suggestion);
      }
    } catch (_) {} finally {
      _isProcessing = false;
    }
  }

  Future<void> _toggleCamera() async {
    _useFrontCamera = !_useFrontCamera;
    try {
      await _camera?.stopImageStream();
    } catch (_) {}
    await _camera?.dispose();
    _camera = null;
    setState(() {});
    await _initCamera();
  }

 Future<void> _saveSession() async {
  final uid = AuthService().currentUser?.uid;
  if (uid == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Not logged in")),
    );
    return;
  }

  final now = DateTime.now();

  final session = {
    "exercise": widget.exercise,
    "reps": reps,
    "form": form,
    "timestamp": now.toIso8601String(),
    "date": "${now.year}-${now.month}-${now.day}",
  };

  // REQUIRED FOR DASHBOARD
  await DbService().saveSessionProgress(uid, session);

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Session saved")),
  );

  Navigator.pop(context);
}


  @override
  Widget build(BuildContext context) {
    if (_camera == null || !_camera!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final camPreviewSize = _camera!.value.previewSize;
    final previewSize = camPreviewSize != null
        ? Size(camPreviewSize.width, camPreviewSize.height)
        : (_currentImageSize ?? const Size(480, 640));

    final paintImageSize = _currentImageSize ?? previewSize;
    final isFront =
        _camera!.description.lensDirection == CameraLensDirection.front;

    return Scaffold(
      appBar: AppBar(
        title: Text("Exercise: ${widget.exercise}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: _toggleCamera,
          ),
        ],
      ),
      body: Stack(
        children: [
          CameraPreview(_camera!),

          if (_currentPose != null)
            Positioned.fill(
              child: CustomPaint(
                painter: PosePainter(
                  pose: _currentPose!,
                  absoluteImageSize: paintImageSize,
                  isFrontCamera: isFront,
                ),
              ),
            ),

          Positioned(
            top: 20,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _infoCard("Reps", reps.toString()),
                _infoCard("Form", form),
              ],
            ),
          ),

          Positioned(
            bottom: 120,
            left: 16,
            right: 16,
            child: Card(
              color: Colors.black.withOpacity(0.75),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  suggestion.isEmpty ? "—" : suggestion,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await _saveSession();
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Session saved")));
          Navigator.pop(context);
        },
        label: const Text("End Session"),
        icon: const Icon(Icons.stop),
      ),
    );
  }

  Widget _infoCard(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 6),
            Text(
              value,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// lib/widgets/pose_painter.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Draws pose landmarks (points) and connecting lines.
/// Accepts:
///  - pose: the ML Kit Pose
///  - absoluteImageSize: size (width,height) of the image ML Kit used
///  - isFrontCamera: whether feed is mirrored (true for selfie)
class PosePainter extends CustomPainter {
  final Pose pose;
  final Size absoluteImageSize;
  final bool isFrontCamera;

  PosePainter({
    required this.pose,
    required this.absoluteImageSize,
    this.isFrontCamera = false,
  });

  // Pairs of landmark types to draw skeleton lines
  static const List<List<PoseLandmarkType>> _connections = [
    // torso
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
    [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
    // left side
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
    [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
    [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
    [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
    // right side
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
    [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
    [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
    [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
    // neck/head approximate
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftEar],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightEar],
    [PoseLandmarkType.leftEar, PoseLandmarkType.rightEar],
  ];

  Offset _mapToCanvas(double x, double y, Size canvasSize) {
    // ML Kit uses image coordinates (origin top-left). We need to scale to canvas.
    final scaleX = canvasSize.width / absoluteImageSize.width;
    final scaleY = canvasSize.height / absoluteImageSize.height;

    double cx = x * scaleX;
    double cy = y * scaleY;

    if (isFrontCamera) {
      // Mirror horizontally
      cx = canvasSize.width - cx;
    }

    return Offset(cx, cy);
  }

  PoseLandmark? _get(PoseLandmarkType t) {
    return pose.landmarks[t];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paintPoint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;
    final paintLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // draw lines
    for (final pair in _connections) {
      final a = _get(pair[0]);
      final b = _get(pair[1]);
      if (a != null && b != null) {
        final p1 = _mapToCanvas(a.x, a.y, size);
        final p2 = _mapToCanvas(b.x, b.y, size);
        paintLine.color = Colors.greenAccent.withOpacity(0.9);
        canvas.drawLine(p1, p2, paintLine);
      }
    }

    // draw points
    for (final entry in pose.landmarks.entries) {
      final lm = entry.value;
      final pt = _mapToCanvas(lm.x, lm.y, size);
      paintPoint.color = Colors.white;
      canvas.drawCircle(pt, 6, paintPoint);

      // small accent showing left/right color
      paintPoint.color = (entry.key.name.contains("left")) ? Colors.blueAccent : Colors.redAccent;
      canvas.drawCircle(pt, 3, paintPoint);
    }
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.pose != pose || oldDelegate.isFrontCamera != isFrontCamera;
  }
}

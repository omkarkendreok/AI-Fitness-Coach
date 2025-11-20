import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseUtils {
  static List<Map<String, dynamic>> convertLandmarks(Pose pose) {
    final List<Map<String, dynamic>> out = [];

    pose.landmarks.entries.forEach((entry) {
      final type = entry.key;
      final lm = entry.value;

      out.add({
        'type': type.name,
        'x': lm.x,
        'y': lm.y,
        'z': lm.z,
        'likelihood': lm.likelihood,
      });
    });

    return out;
  }
}

// lib/utils/rep_counter.dart
import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Simple private point type used for averaging / fallbacks.
class _Pt {
  final double x, y, z;
  const _Pt(this.x, this.y, this.z);
}

/// RepCounter: returns a map { "reps": int, "form": String, "suggestion": String }
class RepCounter {
  final String exercise;
  int _stage = 0; // 0 = expanded/standing, 1 = flexed/down
  int _reps = 0;

  RepCounter({required this.exercise});

  Map<String, dynamic> processPose(Pose pose) {
    switch (exercise.toLowerCase()) {
      case "squat":
        return _processSquat(pose);
      case "pushup":
      case "push-up":
        return _processPushup(pose);
      case "bicepcurl":
      case "bicep curl":
      case "biceps":
        return _processBicep(pose);
      case "lunge":
      case "lunges":
        return _processLunge(pose);
      case "plank":
        return _processPlank(pose);
      default:
        return {"reps": _reps, "form": "unknown", "suggestion": ""};
    }
  }

  // Safe landmark accessor (may return null)
  PoseLandmark? _lm(Pose pose, PoseLandmarkType t) {
    try {
      // pose.landmarks is a Map<PoseLandmarkType, PoseLandmark> in recent ML Kit
      return pose.landmarks[t];
    } catch (_) {
      return null;
    }
  }

  // Accepts PoseLandmark or _Pt (both expose x,y,z)
  double? _angle(dynamic a, dynamic b, dynamic c) {
    if (a == null || b == null || c == null) return null;

    double ax = _getX(a), ay = _getY(a);
    double bx = _getX(b), by = _getY(b);
    double cx = _getX(c), cy = _getY(c);

    final abx = ax - bx, aby = ay - by;
    final cbx = cx - bx, cby = cy - by;

    final dot = abx * cbx + aby * cby;
    final mag1 = math.sqrt(abx * abx + aby * aby);
    final mag2 = math.sqrt(cbx * cbx + cby * cby);
    if (mag1 == 0 || mag2 == 0) return null;
    final cosv = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
    final angleRad = math.acos(cosv);
    return angleRad * 180 / math.pi;
  }

  double _getX(dynamic p) {
    if (p is PoseLandmark) return p.x;
    if (p is _Pt) return p.x;
    // fallback
    return 0.0;
  }

  double _getY(dynamic p) {
    if (p is PoseLandmark) return p.y;
    if (p is _Pt) return p.y;
    return 0.0;
  }

  double _getZ(dynamic p) {
    if (p is PoseLandmark) {
      // newer PoseLandmark includes z, but may be nullable
      return p.z ?? 0.0;
    }
    if (p is _Pt) return p.z;
    return 0.0;
  }

  // --- Exercise processors ------------------------------------------------

  Map<String, dynamic> _processSquat(Pose pose) {
    final leftHip = _lm(pose, PoseLandmarkType.leftHip);
    final leftKnee = _lm(pose, PoseLandmarkType.leftKnee);
    final leftAnkle = _lm(pose, PoseLandmarkType.leftAnkle);
    final rightHip = _lm(pose, PoseLandmarkType.rightHip);
    final rightKnee = _lm(pose, PoseLandmarkType.rightKnee);
    final rightAnkle = _lm(pose, PoseLandmarkType.rightAnkle);

    final leftAngle = _angle(leftHip, leftKnee, leftAnkle);
    final rightAngle = _angle(rightHip, rightKnee, rightAnkle);

    final kneeAngle = ((leftAngle ?? rightAngle ?? 180) + (rightAngle ?? leftAngle ?? 180)) / 2.0;

    String form = "unknown";
    String suggestion = "";

    if (kneeAngle < 90) {
      form = "good";
    } else if (kneeAngle < 120) {
      form = "ok";
      suggestion = "Push hips back and lower a bit more for full depth.";
    } else {
      form = "bad";
      suggestion = "Knees not bending enough — lower down while keeping chest up.";
    }

    if (kneeAngle < 110 && _stage == 0) {
      _stage = 1;
    }
    if (kneeAngle > 160 && _stage == 1) {
      _reps += 1;
      _stage = 0;
      suggestion = "Nice squat — keep your chest up.";
    }

    return {"reps": _reps, "form": form, "suggestion": suggestion};
  }

  Map<String, dynamic> _processPushup(Pose pose) {
    final lShoulder = _lm(pose, PoseLandmarkType.leftShoulder);
    final lElbow = _lm(pose, PoseLandmarkType.leftElbow);
    final lWrist = _lm(pose, PoseLandmarkType.leftWrist);

    final rShoulder = _lm(pose, PoseLandmarkType.rightShoulder);
    final rElbow = _lm(pose, PoseLandmarkType.rightElbow);
    final rWrist = _lm(pose, PoseLandmarkType.rightWrist);

    final leftAngle = _angle(lShoulder, lElbow, lWrist);
    final rightAngle = _angle(rShoulder, rElbow, rWrist);

    final elbowAngle = ((leftAngle ?? rightAngle ?? 180) + (rightAngle ?? leftAngle ?? 180)) / 2.0;

    String form = "unknown";
    String suggestion = "";

    if (elbowAngle < 100) {
      form = "good";
    } else if (elbowAngle < 130) {
      form = "ok";
      suggestion = "Try to lower more — keep body straight.";
    } else {
      form = "bad";
      suggestion = "Hips too high — keep a straight plank from head to heels.";
    }

    if (elbowAngle < 90 && _stage == 0) {
      _stage = 1;
    }
    if (elbowAngle > 160 && _stage == 1) {
      _reps += 1;
      _stage = 0;
      suggestion = "Good push-up.";
    }

    return {"reps": _reps, "form": form, "suggestion": suggestion};
  }

  Map<String, dynamic> _processBicep(Pose pose) {
    final lShoulder = _lm(pose, PoseLandmarkType.leftShoulder);
    final lElbow = _lm(pose, PoseLandmarkType.leftElbow);
    final lWrist = _lm(pose, PoseLandmarkType.leftWrist);

    final rShoulder = _lm(pose, PoseLandmarkType.rightShoulder);
    final rElbow = _lm(pose, PoseLandmarkType.rightElbow);
    final rWrist = _lm(pose, PoseLandmarkType.rightWrist);

    final leftAngle = _angle(lShoulder, lElbow, lWrist) ?? 180;
    final rightAngle = _angle(rShoulder, rElbow, rWrist) ?? 180;

    String form = "unknown";
    String suggestion = "";

    bool leftFlex = leftAngle < 60;
    bool leftExt = leftAngle > 150;
    bool rightFlex = rightAngle < 60;
    bool rightExt = rightAngle > 150;

    if (leftFlex && rightFlex) {
      form = "good";
    } else if (leftFlex || rightFlex) {
      form = "ok";
      suggestion = "One arm didn't fully curl — try to control the other arm too.";
    } else {
      form = "bad";
      suggestion = "Keep elbows anchored and curl with controlled motion.";
    }

    if ((leftFlex || rightFlex) && _stage == 0) {
      _stage = 1;
    }
    if ((leftExt && rightExt) && _stage == 1) {
      _reps += 1;
      _stage = 0;
      suggestion = "Good curl — control the descent.";
    }

    return {"reps": _reps, "form": form, "suggestion": suggestion};
  }

  Map<String, dynamic> _processLunge(Pose pose) {
    final lHip = _lm(pose, PoseLandmarkType.leftHip);
    final lKnee = _lm(pose, PoseLandmarkType.leftKnee);
    final lAnkle = _lm(pose, PoseLandmarkType.leftAnkle);

    final rHip = _lm(pose, PoseLandmarkType.rightHip);
    final rKnee = _lm(pose, PoseLandmarkType.rightKnee);
    final rAnkle = _lm(pose, PoseLandmarkType.rightAnkle);

    final leftAngle = _angle(lHip, lKnee, lAnkle) ?? 180;
    final rightAngle = _angle(rHip, rKnee, rAnkle) ?? 180;

    final kneeAngle = math.min(leftAngle, rightAngle);

    String form = "unknown";
    String suggestion = "";

    if (kneeAngle < 100) {
      form = "good";
    } else if (kneeAngle < 130) {
      form = "ok";
      suggestion = "Lower the front knee more so it reaches approx 90°.";
    } else {
      form = "bad";
      suggestion = "Step further and lower your back knee.";
    }

    if (kneeAngle < 110 && _stage == 0) _stage = 1;
    if (kneeAngle > 160 && _stage == 1) {
      _reps += 1;
      _stage = 0;
      suggestion = "Good lunge.";
    }

    return {"reps": _reps, "form": form, "suggestion": suggestion};
  }

  Map<String, dynamic> _processPlank(Pose pose) {
    final lShoulder = _lm(pose, PoseLandmarkType.leftShoulder);
    final rShoulder = _lm(pose, PoseLandmarkType.rightShoulder);
    final lHip = _lm(pose, PoseLandmarkType.leftHip);
    final rHip = _lm(pose, PoseLandmarkType.rightHip);
    final lAnkle = _lm(pose, PoseLandmarkType.leftAnkle);
    final rAnkle = _lm(pose, PoseLandmarkType.rightAnkle);

    final avgShoulder = _avgPoint(lShoulder, rShoulder);
    final avgHip = _avgPoint(lHip, rHip);
    final avgAnkle = _avgPoint(lAnkle, rAnkle);

    final hipAngle = _angle(avgShoulder, avgHip, avgAnkle) ?? 180;

    String form = "unknown";
    String suggestion = "";

    if (hipAngle > 165) {
      form = "good";
      suggestion = "Good plank — keep it steady.";
    } else if (hipAngle > 140) {
      form = "ok";
      suggestion = "Try to lower your hips a bit to form a straight line.";
    } else {
      form = "bad";
      suggestion = "Hips are too low or too high — tighten core and align body.";
    }

    return {"reps": _reps, "form": form, "suggestion": suggestion};
  }

  // average two landmarks (may be null) into a simple _Pt
  _Pt _avgPoint(PoseLandmark? a, PoseLandmark? b) {
    if (a == null && b == null) return const _Pt(0.0, 0.0, 0.0);
    if (a == null) return _Pt(b!.x, b.y, b.z ?? 0.0);
    if (b == null) return _Pt(a.x, a.y, a.z ?? 0.0);
    return _Pt((a.x + b.x) / 2.0, (a.y + b.y) / 2.0, ((a.z ?? 0.0) + (b.z ?? 0.0)) / 2.0);
  }
}

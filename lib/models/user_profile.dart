import 'dart:math';

class UserProfile {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final double heightCm;
  final double weightKg;
  final String workoutPref;
  final String level;
  final String photoUrl;

  UserProfile({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.heightCm,
    required this.weightKg,
    required this.workoutPref,
    required this.level,
    required this.photoUrl,
  });

  double get bmi {
    if (heightCm == 0) return 0;
    double m = heightCm / 100;
    return weightKg / pow(m, 2);
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'workoutPref': workoutPref,
        'level': level,
        'photoUrl': photoUrl,
      };

  factory UserProfile.fromMap(Map<dynamic, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      heightCm: (map['heightCm'] as num?)?.toDouble() ?? 0,
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? 0,
      workoutPref: map['workoutPref'] ?? '',
      level: map['level'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
    );
  }
}

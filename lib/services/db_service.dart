// lib/services/db_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DbService {
  final FirebaseFirestore _fire = FirebaseFirestore.instance;

  /// Ensure a lightweight profile exists; if missing create using provided email.
  /// Returns the profile map.
  Future<Map<String, dynamic>> getOrCreateUserProfile(String uid, {String email = ''}) async {
    final docRef = _fire.collection('users').doc(uid);
    final snap = await docRef.get();
    if (snap.exists) {
      final data = snap.data()!;
      return _normaliseProfile(data);
    } else {
      final profile = {
        'uid': uid,
        'email': email,
        'firstName': '',
        'lastName': '',
        'heightCm': null,
        'weightKg': null,
        'workoutLevel': 'beginner',
        'photoURL': null,
        'createdAt': FieldValue.serverTimestamp(),
      };
      await docRef.set(profile);
      return _normaliseProfile(profile);
    }
  }

  Map<String, dynamic> _normaliseProfile(Map<String, dynamic> raw) {
    // Convert Timestamp values to simple types if needed.
    final out = Map<String, dynamic>.from(raw);
    // Example normalization (Firestore returns Timestamp).
    if (out['createdAt'] is Timestamp) {
      out['createdAt'] = (out['createdAt'] as Timestamp).toDate().toIso8601String();
    }
    return out;
  }

  /// Update user's profile partial map
  Future<void> updateUserProfile(String uid, Map<String, dynamic> update) async {
    final docRef = _fire.collection('users').doc(uid);
    await docRef.set(update, SetOptions(merge: true));
  }

  /// Called by exercise_screen to save session progress
  Future<void> saveSessionProgress(String uid, Map<String, dynamic> session) async {
    // store session in user's subcollection 'sessions'
    final col = _fire.collection('users').doc(uid).collection('sessions');
    // add server timestamp for reliable sorting
    final toSave = Map<String, dynamic>.from(session);
    toSave['createdAt'] = FieldValue.serverTimestamp();
    await col.add(toSave);
  }

  /// Retrieve recent sessions (limit defaults to 10)
  Future<List<Map<String, dynamic>>> getRecentSessions(String uid, {int limit = 10}) async {
    final col = _fire.collection('users').doc(uid).collection('sessions');
    final q = await col.orderBy('createdAt', descending: true).limit(limit).get();
    return q.docs.map((d) {
      final m = d.data();
      m['id'] = d.id;
      // convert Timestamp to ISO if necessary
      if (m['createdAt'] is Timestamp) {
        m['createdAtIso'] = (m['createdAt'] as Timestamp).toDate().toIso8601String();
      }
      return m;
    }).toList();
  }

  /// Weekly plan stored at users/{uid}/meta/weekly_plan (or create default)
  Future<List<Map<String, dynamic>>> getWeeklyPlan(String uid) async {
    final doc = _fire.collection('users').doc(uid).collection('meta').doc('weekly_plan');
    final snap = await doc.get();
    if (snap.exists) {
      final data = snap.data()!;
      // Expecting structure: { "monday": [...], "tuesday": [...], ... }
      final days = [
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
        'sunday'
      ];
      return days.map((d) {
        final list = (data[d] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
        return {'day': d, 'exercises': list};
      }).toList();
    } else {
      // create default plan
      final defaultPlan = {
        'monday': [
          {'name': 'Push-ups', 'sets': 3, 'reps': 12}
        ],
        'tuesday': [
          {'name': 'Squats', 'sets': 3, 'reps': 15}
        ],
        'wednesday': [
          {'name': 'Bicep Curls', 'sets': 3, 'reps': 12}
        ],
        'thursday': [
          {'name': 'Lunges', 'sets': 3, 'reps': 12}
        ],
        'friday': [
          {'name': 'Plank', 'sets': 3, 'durationSec': 45}
        ],
        'saturday': [
          {'name': 'Active rest', 'sets': 1, 'reps': 0}
        ],
        'sunday': [
          {'name': 'Rest', 'sets': 0, 'reps': 0}
        ],
      };
      await doc.set(defaultPlan);
      return defaultPlan.keys.map((d) {
        final list = (defaultPlan[d] as List<dynamic>).cast<Map<String, dynamic>>();
        return {'day': d, 'exercises': list};
      }).toList();
    }
  }

  /// Replace weekly plan doc with newPlan map with same shape as defaultPlan
  Future<void> updateWeeklyPlan(String uid, Map<String, dynamic> newPlan) async {
    final doc = _fire.collection('users').doc(uid).collection('meta').doc('weekly_plan');
    await doc.set(newPlan, SetOptions(merge: false));
  }
}

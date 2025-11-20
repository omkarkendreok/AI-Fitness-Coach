import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _fire = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> login(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signup({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required double heightCm,
    required double weightKg,
    required String workoutLevel,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = cred.user!;
    await _fire.collection("users").doc(user.uid).set({
      "uid": user.uid,
      "email": email,
      "firstName": firstName,
      "lastName": lastName,
      "heightCm": heightCm,
      "weightKg": weightKg,
      "workoutLevel": workoutLevel,
      "createdAt": FieldValue.serverTimestamp(),
    });

    return cred;
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// NEW GOOGLE SIGN-IN (2025 API)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope("email");
      googleProvider.addScope("profile");

      return await _auth.signInWithProvider(googleProvider);
    } catch (e) {
      print("Google Sign-in error: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

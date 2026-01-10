import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'debug_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<User?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      DebugService.info("Signed in anonymously: ${userCredential.user?.uid}");
      return userCredential.user;
    } catch (e) {
      DebugService.error("Error signing in anonymously", e);
      // In a real app, rethrow or handle error
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

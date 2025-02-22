import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  GoogleSignIn? _googleSignIn;
  FirebaseFirestore? _firestore;

  AuthService() {
    if (!kIsWeb) {
      // Only initialize GoogleSignIn for mobile
      _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
    }
  }

  // Initialize Firestore lazily
  FirebaseFirestore get firestore {
    _firestore ??= FirebaseFirestore.instance;
    return _firestore!;
  }

  // Check if user exists in database
  Future<bool> isNewUser(String userId) async {
    try {
      final userDoc = await firestore.collection('users').doc(userId).get();
      return !userDoc.exists;
    } catch (e) {
      // If Firestore is terminated, reinitialize it
      _firestore = FirebaseFirestore.instance;
      final userDoc = await _firestore!.collection('users').doc(userId).get();
      return !userDoc.exists;
    }
  }

  // Sign up with email and password
  Future<UserCredential> signUp(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send email verification
      await userCredential.user?.sendEmailVerification();

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential> signIn(String email, String password) async {
    try {
      // Ensure Firestore is initialized
      _firestore = FirebaseFirestore.instance;

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if email is verified
      if (!userCredential.user!.emailVerified) {
        throw 'Please verify your email before logging in';
      }

      return userCredential;
    } catch (e) {
      if (e is FirebaseException && e.code == 'failed-precondition') {
        // If Firestore is terminated, reinitialize it and try again
        _firestore = FirebaseFirestore.instance;
        return await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Ensure Firestore is initialized
      _firestore = FirebaseFirestore.instance;

      if (kIsWeb) {
        // Web implementation using Firebase Auth directly
        final provider = GoogleAuthProvider();
        provider.addScope('email');
        provider.addScope('profile');

        // Use signInWithPopup for web
        return await _auth.signInWithPopup(provider);
      } else {
        // Mobile implementation
        final GoogleSignInAccount? googleUser = await _googleSignIn?.signIn();
        if (googleUser == null) {
          throw 'Google sign in was cancelled';
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      // Ensure we're signed out of Google if anything fails
      try {
        if (!kIsWeb) {
          await _googleSignIn?.signOut();
        }
      } catch (_) {}
      throw 'Google sign in failed: $e';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Sign out from all providers first
      if (!kIsWeb) {
        try {
          await _googleSignIn?.signOut();
        } catch (_) {}
      }

      // Clear any cached Firestore data safely
      if (_firestore != null) {
        try {
          await _firestore!.terminate();
          await _firestore!.clearPersistence();
        } catch (_) {}
      }

      // Finally, sign out from Firebase
      await _auth.signOut();

      // Reset Firestore instance
      _firestore = null;
    } catch (e) {
      rethrow;
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}

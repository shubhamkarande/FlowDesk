import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  FirebaseAuth? _auth;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool _isFirebaseAvailable = false;
  bool _initialized = false;

  void _initializeFirebase() {
    if (_initialized) return;

    try {
      // Check if Firebase is available before trying to access it
      _auth = FirebaseAuth.instance;
      _isFirebaseAvailable = true;
      debugPrint('Firebase Auth initialized successfully');
    } catch (e) {
      debugPrint('Firebase Auth not available: $e');
      _isFirebaseAvailable = false;
      _auth = null;
    }
    _initialized = true;
  }

  User? get currentUser {
    _initializeFirebase();
    return _isFirebaseAvailable ? _auth?.currentUser : null;
  }

  bool get isSignedIn {
    _initializeFirebase();
    return _isFirebaseAvailable ? (_auth?.currentUser != null) : false;
  }

  Stream<User?> get authStateChanges {
    _initializeFirebase();
    return _isFirebaseAvailable
        ? _auth!.authStateChanges()
        : Stream.value(null);
  }

  // Email/Password Authentication
  Future<UserCredential?> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    _initializeFirebase();
    if (!_isFirebaseAvailable) {
      throw Exception(
        'Firebase Auth is not available. Please configure Firebase.',
      );
    }

    try {
      return await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential?> signUpWithEmailPassword(
    String email,
    String password,
  ) async {
    _initializeFirebase();
    if (!_isFirebaseAvailable) {
      throw Exception(
        'Firebase Auth is not available. Please configure Firebase.',
      );
    }

    try {
      return await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Google Sign-In
  Future<UserCredential?> signInWithGoogle() async {
    _initializeFirebase();
    if (!_isFirebaseAvailable) {
      throw Exception(
        'Firebase Auth is not available. Please configure Firebase.',
      );
    }

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth!.signInWithCredential(credential);
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
  }

  // Sign Out
  Future<void> signOut() async {
    _initializeFirebase();
    if (_isFirebaseAvailable) {
      await Future.wait([_auth!.signOut(), _googleSignIn.signOut()]);
    }
  }

  // Guest Mode
  Future<void> enableGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('guest_mode', true);
  }

  Future<void> disableGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('guest_mode', false);
  }

  Future<bool> isGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('guest_mode') ?? false;
  }

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    _initializeFirebase();
    if (!_isFirebaseAvailable) {
      throw Exception(
        'Firebase Auth is not available. Please configure Firebase.',
      );
    }

    try {
      await _auth!.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }
}

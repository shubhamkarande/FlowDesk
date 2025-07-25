import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/encryption_service.dart';
import '../services/sync_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final EncryptionService _encryptionService = EncryptionService();
  final SyncService _syncService = SyncService();

  User? _user;
  bool _isGuestMode = false;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isGuestMode => _isGuestMode;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null || _isGuestMode;

  AuthProvider() {
    _init();
  }

  void _init() {
    // Initialize auth state listening with error handling
    _initAuthStateListener();

    // Check guest mode
    _checkGuestMode();
  }

  void _initAuthStateListener() async {
    try {
      // Add a small delay to ensure Firebase is initialized
      await Future.delayed(const Duration(milliseconds: 200));

      _authService.authStateChanges.listen(
        (user) {
          _user = user;
          notifyListeners();

          if (user != null) {
            try {
              _syncService.startPeriodicSync();
            } catch (e) {
              debugPrint('Error starting sync: $e');
            }
          }
        },
        onError: (error) {
          debugPrint('Auth state change error: $error');
        },
      );
    } catch (e) {
      debugPrint('Firebase Auth not available: $e');
      // Continue without Firebase auth - app will work in offline mode
    }
  }

  Future<void> _checkGuestMode() async {
    try {
      _isGuestMode = await _authService.isGuestMode();
      notifyListeners();
    } catch (e) {
      debugPrint('Error checking guest mode: $e');
      // Default to guest mode if there's an error
      _isGuestMode = true;
      notifyListeners();
    }
  }

  Future<bool> signInWithEmailPassword(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.signInWithEmailPassword(
        email,
        password,
      );
      if (result != null) {
        await _authService.disableGuestMode();
        _isGuestMode = false;
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUpWithEmailPassword(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.signUpWithEmailPassword(
        email,
        password,
      );
      if (result != null) {
        await _authService.disableGuestMode();
        _isGuestMode = false;
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.signInWithGoogle();
      if (result != null) {
        await _authService.disableGuestMode();
        _isGuestMode = false;
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);

    try {
      await _authService.signOut();
      await _encryptionService.clearEncryptionData();
      _isGuestMode = false;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> enableGuestMode() async {
    await _authService.enableGuestMode();
    _isGuestMode = true;
    notifyListeners();
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> setEncryptionPassphrase(String passphrase) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _encryptionService.setPassphrase(passphrase);
      if (success && _user != null) {
        // Trigger initial sync after setting passphrase
        await _syncService.syncAll();
      }
      return success;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyEncryptionPassphrase(String passphrase) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _encryptionService.verifyPassphrase(passphrase);
      if (success && _user != null) {
        // Trigger sync after successful verification
        await _syncService.syncAll();
      }
      return success;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  bool get isPassphraseSet => _encryptionService.isInitialized;

  Future<bool> checkPassphraseSet() async {
    return await _encryptionService.isPassphraseSet();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() => _clearError();
}

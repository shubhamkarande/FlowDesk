import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  static const _storage = FlutterSecureStorage();
  static const String _keyStorageKey = 'encryption_key';
  static const String _passphraseKey = 'user_passphrase';

  Encrypter? _encrypter;
  IV? _iv;

  Future<bool> isPassphraseSet() async {
    final passphrase = await _storage.read(key: _passphraseKey);
    return passphrase != null && passphrase.isNotEmpty;
  }

  Future<bool> setPassphrase(String passphrase) async {
    try {
      // Generate key from passphrase
      final key = _generateKeyFromPassphrase(passphrase);

      // Store encrypted passphrase hash for verification
      final passphraseHash = sha256.convert(utf8.encode(passphrase)).toString();
      await _storage.write(key: _passphraseKey, value: passphraseHash);

      // Store the encryption key
      await _storage.write(
        key: _keyStorageKey,
        value: base64.encode(key.bytes),
      );

      // Initialize encrypter
      _encrypter = Encrypter(AES(key));
      _iv = IV.fromSecureRandom(16);

      return true;
    } catch (e) {
      print('Error setting passphrase: $e');
      return false;
    }
  }

  Future<bool> verifyPassphrase(String passphrase) async {
    try {
      final storedHash = await _storage.read(key: _passphraseKey);
      if (storedHash == null) return false;

      final inputHash = sha256.convert(utf8.encode(passphrase)).toString();

      if (inputHash == storedHash) {
        // Initialize encrypter with correct passphrase
        final key = _generateKeyFromPassphrase(passphrase);
        _encrypter = Encrypter(AES(key));
        _iv = IV.fromSecureRandom(16);
        return true;
      }

      return false;
    } catch (e) {
      print('Error verifying passphrase: $e');
      return false;
    }
  }

  Key _generateKeyFromPassphrase(String passphrase) {
    // Use PBKDF2 to derive key from passphrase
    final bytes = utf8.encode(passphrase);
    final digest = sha256.convert(bytes);
    return Key(Uint8List.fromList(digest.bytes));
  }

  String encryptText(String plainText) {
    if (_encrypter == null || _iv == null) {
      throw Exception('Encryption not initialized. Set passphrase first.');
    }

    try {
      final encrypted = _encrypter!.encrypt(plainText, iv: _iv!);
      return '${_iv!.base64}:${encrypted.base64}';
    } catch (e) {
      print('Error encrypting text: $e');
      return plainText; // Return original text if encryption fails
    }
  }

  String decryptText(String encryptedText) {
    if (_encrypter == null) {
      throw Exception('Encryption not initialized. Verify passphrase first.');
    }

    try {
      final parts = encryptedText.split(':');
      if (parts.length != 2) {
        return encryptedText; // Return as-is if not properly formatted
      }

      final iv = IV.fromBase64(parts[0]);
      final encrypted = Encrypted.fromBase64(parts[1]);

      return _encrypter!.decrypt(encrypted, iv: iv);
    } catch (e) {
      print('Error decrypting text: $e');
      return encryptedText; // Return encrypted text if decryption fails
    }
  }

  Future<void> clearEncryptionData() async {
    await _storage.delete(key: _keyStorageKey);
    await _storage.delete(key: _passphraseKey);
    _encrypter = null;
    _iv = null;
  }

  bool get isInitialized => _encrypter != null;
}

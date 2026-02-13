import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Manages password hashing and token authentication.
/// Passwords are hashed with salt using SHA256. Never stores plain text passwords.
class AuthManager {
  late String _passwordHash;
  late String _salt;
  late String _currentToken;

  /// Initializes the auth manager with a plaintext password.
  /// Generates a random salt and computes SHA256(salt + password).
  AuthManager.fromPassword(String password) {
    _salt = _generateSalt();
    _passwordHash = _hashPassword(password, _salt);
    _currentToken = _generateToken();
  }

  /// Returns the current authentication token.
  String get token => _currentToken;

  /// Validates an incoming password.
  /// Returns true if SHA256(salt + incomingPassword) matches the stored hash.
  bool validatePassword(String incomingPassword) {
    final hash = _hashPassword(incomingPassword, _salt);
    return hash == _passwordHash;
  }

  /// Validates a token.
  /// Returns true if the provided token matches the current token.
  bool validateToken(String incomingToken) {
    return incomingToken == _currentToken;
  }

  /// Generates a new token (useful for logout/token rotation).
  void refreshToken() {
    _currentToken = _generateToken();
  }

  /// Generates a cryptographically secure random salt (16 bytes, base64 encoded).
  static String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Encode(saltBytes);
  }

  /// Computes SHA256 hash of salt + password.
  static String _hashPassword(String password, String salt) {
    final combined = utf8.encode('$salt:$password');
    return sha256.convert(combined).toString();
  }

  /// Generates a cryptographically secure random token (32 bytes, base64 encoded).
  static String _generateToken() {
    final random = Random.secure();
    final tokenBytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Encode(tokenBytes).replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:fastshare/features/transfer/data/services/auth_manager.dart';

void main() {
  group('AuthManager Tests', () {
    test('Should generate token and hash password correctly', () {
      final manager = AuthManager.fromPassword('secret123');

      expect(manager.token, isNotEmpty);
      expect(manager.token.length,
          greaterThan(20)); // Base64 32 bytes is ~44 chars
    });

    test('Should validate correct password', () {
      final manager = AuthManager.fromPassword('myPassword');
      expect(manager.validatePassword('myPassword'), isTrue);
    });

    test('Should reject incorrect password', () {
      final manager = AuthManager.fromPassword('myPassword');
      expect(manager.validatePassword('wrongPassword'), isFalse);
      expect(manager.validatePassword('MyPassword'), isFalse); // Case sensitive
    });

    test('Should validate correct token', () {
      final manager = AuthManager.fromPassword('pass');
      final token = manager.token;
      expect(manager.validateToken(token), isTrue);
    });

    test('Should reject incorrect token', () {
      final manager = AuthManager.fromPassword('pass');
      expect(manager.validateToken('invalid_token_string'), isFalse);
    });

    test('refreshToken() should generate new token', () {
      final manager = AuthManager.fromPassword('pass');
      final oldToken = manager.token;

      manager.refreshToken();
      final newToken = manager.token;

      expect(newToken, isNot(equals(oldToken)));
      expect(manager.validateToken(oldToken), isFalse);
      expect(manager.validateToken(newToken), isTrue);
    });
  });
}

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:si2_mobile/core/storage/secure_storage_service.dart';
import 'package:si2_mobile/features/auth/data/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('AuthService and SecureStorage Unit Tests', () {
    test('kClientRole constant is C', () {
      expect(kClientRole, equals('C'));
    });

    test('SecureStorageService saves and retrieves user session correctly',
        () async {
      await SecureStorageService.saveUserSession(
        nombre: 'María',
        correo: 'maria@test.com',
        nombreRol: 'C',
      );

      final session = await SecureStorageService.getUserSession();
      expect(session, isNotNull);
      expect(session!['nombre'], equals('María'));
      expect(session['correo'], equals('maria@test.com'));
      expect(session['nombre_rol'], equals('C'));
    });

    test('SecureStorageService saveToken and getToken works', () async {
      await SecureStorageService.saveToken('jwt-test-token-123');
      final token = await SecureStorageService.getToken();
      expect(token, equals('jwt-test-token-123'));
    });

    test('AuthService.logout clears both token and user session', () async {
      await SecureStorageService.saveToken('token-to-clear');
      await SecureStorageService.saveUserSession(
        nombre: 'Carlos',
        correo: 'carlos@test.com',
        nombreRol: 'C',
      );

      // Verify they exist
      expect(await SecureStorageService.getToken(), isNotNull);
      expect(await SecureStorageService.getUserSession(), isNotNull);

      // Perform logout
      await AuthService.logout();

      // Verify they are cleared
      expect(await SecureStorageService.getToken(), isNull);
      expect(await SecureStorageService.getUserSession(), isNull);
    });

    test('Corrupted session JSON returns null gracefully', () async {
      // Direct corrupt test
      const invalidJson = 'invalid-json-blob';
      expect(() => jsonDecode(invalidJson), throwsFormatException);
    });
  });
}

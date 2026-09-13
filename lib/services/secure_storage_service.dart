import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper around [FlutterSecureStorage] for persisting the JWT
/// access token returned by the API.
///
/// Tokens MUST be stored in secure storage (encrypted keystore/keychain),
/// never in [SharedPreferences] or any plaintext storage: a leaked access
/// token grants full access to the user's account.
class SecureStorageService {
  SecureStorageService._();

  /// Key under which the access token is persisted.
  static const String _tokenKey = 'access_token';

  /// Singleton-ish platform storage backend.
  static final FlutterSecureStorage _storage = FlutterSecureStorage();

  /// Persists [token] securely so it survives app restarts.
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Returns the stored access token, or `null` when none was saved.
  static Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  /// Removes the stored access token (used on logout or session expiry).
  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }
}

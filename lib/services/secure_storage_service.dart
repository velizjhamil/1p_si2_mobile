import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper around [FlutterSecureStorage] for persisting the JWT
/// access token and the lightweight user session returned by the API.
///
/// Tokens MUST be stored in secure storage (encrypted keystore/keychain),
/// never in [SharedPreferences] or any plaintext storage: a leaked access
/// token grants full access to the user's account.
class SecureStorageService {
  SecureStorageService._();

  /// Key under which the access token is persisted.
  static const String _tokenKey = 'access_token';

  /// Key under which the user session JSON blob is persisted.
  static const String _sessionKey = 'user_session';

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

  /// Removes the stored access token (kept for compatibility; prefer
  /// [clearAll] so token and session never get out of sync).
  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  /// Persists the authenticated user's basic profile as a JSON blob.
  ///
  /// The mobile app targets clients only and does not need the full user
  /// payload: name, email and role name are enough to personalize the UI
  /// and re-validate the session on startup.
  static Future<void> saveUserSession({
    required String nombre,
    required String correo,
    required String nombreRol,
  }) async {
    final session = jsonEncode({
      'nombre': nombre,
      'correo': correo,
      'nombre_rol': nombreRol,
    });
    await _storage.write(key: _sessionKey, value: session);
  }

  /// Returns the stored session map, or `null` when none was saved or the
  /// blob is corrupted.
  static Future<Map<String, dynamic>?> getUserSession() async {
    final raw = await _storage.read(key: _sessionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      // Corrupted blob: treat it as no session.
    }
    return null;
  }

  /// Removes token AND session (used on logout or session expiry).
  static Future<void> clearAll() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _sessionKey);
  }
}

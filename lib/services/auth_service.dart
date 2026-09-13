import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'secure_storage_service.dart';

/// Service that talks to the Attention backend authentication endpoints.
class AuthService {
  AuthService._();

  /// Base URL of the API.
  ///
  /// `10.0.2.2` is the host machine's loopback interface (127.0.0.1) as
  /// seen from inside the Android emulator. Retarget by changing only this
  /// constant:
  /// - iOS Simulator: http://127.0.0.1:8000/api/v1
  /// - Physical device: use the host machine's LAN IP (e.g. http://192.168.1.50:8000/api/v1)
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

  /// Attempts to log in with [email] and [password].
  ///
  /// Never throws. Always returns a map of one of these shapes:
  /// - `{'success': true, 'data': Map<String, dynamic>}` on a successful login
  ///   (the token has already been persisted via [SecureStorageService]).
  /// - `{'success': false, 'message': String}` with a user-facing Spanish
  ///   message on any failure.
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return await _handleSuccess(response.body);
      }
      return _handleHttpError(response.statusCode, response.body);
    } on TimeoutException {
      return {
        'success': false,
        'message': 'El servidor tardó demasiado en responder. Intenta nuevamente.',
      };
    } on SocketException {
      return {
        'success': false,
        'message': 'No se pudo conectar con el servidor. Verifica tu conexión.',
      };
    } on http.ClientException {
      return {
        'success': false,
        'message': 'No se pudo conectar con el servidor. Verifica tu conexión.',
      };
    } on FormatException {
      return _invalidResponse();
    } on TypeError {
      return _invalidResponse();
    } catch (e) {
      return {
        'success': false,
        'message': 'Ocurrió un error inesperado. Intenta nuevamente.',
      };
    }
  }

  /// Parses a successful (200/201) response body and persists the token.
  static Future<Map<String, dynamic>> _handleSuccess(String body) async {
    if (body.trim().isEmpty) {
      return _noToken();
    }

    final Map<String, dynamic> decodedBody;
    try {
      final dynamic decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        return _noToken();
      }
      decodedBody = decoded;
    } on FormatException {
      return _noToken();
    }

    final String? token = _extractToken(decodedBody);
    if (token == null || token.isEmpty) {
      return _noToken();
    }

    await SecureStorageService.saveToken(token);
    return {'success': true, 'data': decodedBody};
  }

  /// Searches the payload for an access token under the known keys,
  /// checking the top level first and then the nested `data` map.
  static String? _extractToken(Map<String, dynamic> body) {
    const tokenKeys = ['access_token', 'token', 'accessToken'];
    for (final key in tokenKeys) {
      final dynamic value = body[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }

    final dynamic nested = body['data'];
    if (nested is Map<String, dynamic>) {
      for (final key in tokenKeys) {
        final dynamic value = nested[key];
        if (value is String && value.isNotEmpty) {
          return value;
        }
      }
    }
    return null;
  }

  /// Builds the failure result for HTTP error statuses (4xx/5xx).
  static Map<String, dynamic> _handleHttpError(int statusCode, String body) {
    String? serverMessage;
    try {
      final dynamic decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        for (final key in ['message', 'detail', 'error']) {
          final dynamic value = decoded[key];
          if (value is String && value.isNotEmpty) {
            serverMessage = value;
            break;
          }
        }
      }
    } catch (_) {
      // Body was not valid JSON; fall through to the fallback message.
    }

    if (serverMessage != null) {
      return {'success': false, 'message': serverMessage};
    }

    if (statusCode == 400 || statusCode == 401) {
      return {'success': false, 'message': 'Credenciales incorrectas.'};
    }

    return {
      'success': false,
      'message': 'Error del servidor (código $statusCode)',
    };
  }

  static Map<String, dynamic> _noToken() {
    return {
      'success': false,
      'message': 'La respuesta del servidor no incluye un token de acceso.',
    };
  }

  static Map<String, dynamic> _invalidResponse() {
    return {'success': false, 'message': 'Respuesta del servidor inválida.'};
  }
}

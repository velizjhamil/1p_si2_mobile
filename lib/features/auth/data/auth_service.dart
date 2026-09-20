import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../../core/storage/secure_storage_service.dart';

/// Role name the backend assigns to clients (Rol.nombre_rol == "C").
///
/// The mobile app is clients-only: any other role (ASU/GS/V/D) must be
/// rejected before a token is ever persisted.
const String kClientRole = 'C';

/// Service that talks to the Attention backend authentication endpoints.
class AuthService {
  AuthService._();

  /// Attempts to log in with [email] and [password].
  ///
  /// Clients-only app: a successful login whose role is not `C` is turned
  /// into a failure — the token is NOT persisted for staff accounts.
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
    final String baseUrl = await ApiConfig.resolveBaseUrl();

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            // Backend contract (LoginRequest): field names in Spanish.
            body: jsonEncode({'correo': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      final bodyDecoded = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return await _handleSuccess(bodyDecoded);
      }
      return _handleHttpError(response.statusCode, bodyDecoded);
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

  /// Registers a new client account (CU1).
  ///
  /// Sends [nombre], optional [apellido], [email], and [password] to
  /// `POST /usuarios` with `nombre_rol: 'C'` (the client role).
  ///
  /// Never throws. Always returns:
  /// - `{'success': true, 'data': Map<String, dynamic>, 'message': String}`
  /// - `{'success': false, 'message': String}` on failure.
  static Future<Map<String, dynamic>> register({
    required String nombre,
    String? apellido,
    required String email,
    required String password,
  }) async {
    final String baseUrl = await ApiConfig.resolveBaseUrl();

    try {
      final payload = <String, dynamic>{
        'nombre': nombre.trim(),
        if (apellido != null && apellido.trim().isNotEmpty)
          'apellido': apellido.trim(),
        'correo': email.trim(),
        'password': password,
        'nombre_rol': kClientRole,
        'estado': true,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/usuarios'),
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      final bodyDecoded = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic decoded = jsonDecode(bodyDecoded);
        return {
          'success': true,
          'data': decoded is Map<String, dynamic> ? decoded : <String, dynamic>{},
          'message': 'Cuenta creada exitosamente.',
        };
      }
      return _handleHttpError(response.statusCode, bodyDecoded);
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
    } catch (e) {
      return {
        'success': false,
        'message': 'Ocurrió un error inesperado. Intenta nuevamente.',
      };
    }
  }

  /// Clears stored access token and user session (CU3).
  static Future<void> logout() async {
    await SecureStorageService.clearAll();
  }

  /// Parses a successful (200/201) response body, enforces the clients-only
  /// policy and persists the token + user session.
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

    // Clients-only policy: staff roles are rejected before persisting
    // anything. The response shape is {status, data: {access_token, user}}.
    final dynamic data = decodedBody['data'];
    if (data is! Map<String, dynamic>) {
      return _noToken();
    }
    final String? nombreRol = _extractRoleName(data);
    if (nombreRol == null) {
      return _invalidResponse();
    }
    if (nombreRol != kClientRole) {
      return {
        'success': false,
        'message': 'Esta aplicación es exclusiva para clientes. '
            'Ingresa desde la plataforma web.',
      };
    }

    // Persist token + lightweight session before reporting success.
    final dynamic user = data['user'];
    final String nombre = user is Map<String, dynamic>
        ? (user['nombre'] as String? ?? '')
        : '';
    final String correo = user is Map<String, dynamic>
        ? (user['correo'] as String? ?? '')
        : '';

    await SecureStorageService.saveToken(token);
    await SecureStorageService.saveUserSession(
      nombre: nombre,
      correo: correo,
      nombreRol: nombreRol,
    );

    return {'success': true, 'data': decodedBody};
  }

  /// Extracts `data.user.rol.nombre_rol` from the login payload.
  static String? _extractRoleName(Map<String, dynamic> data) {
    final dynamic user = data['user'];
    if (user is! Map<String, dynamic>) return null;

    final dynamic rol = user['rol'];
    if (rol is! Map<String, dynamic>) return null;

    final dynamic nombreRol = rol['nombre_rol'];
    if (nombreRol is String && nombreRol.isNotEmpty) return nombreRol;
    return null;
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
          } else if (value is List && value.isNotEmpty) {
            final first = value.first;
            if (first is Map && first.containsKey('msg')) {
              serverMessage = first['msg'].toString();
              break;
            }
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

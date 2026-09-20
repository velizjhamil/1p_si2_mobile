import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';
import '../../../../core/storage/secure_storage_service.dart';
import 'notificacion_model.dart';

/// Servicio HTTP para consumir y gestionar las Notificaciones del Cliente (CU10).
class NotificacionesService {
  const NotificacionesService._();

  /// Headers autenticados con Bearer JWT.
  static Future<Map<String, String>> _getHeaders() async {
    final token = await SecureStorageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Obtiene la lista de notificaciones del usuario autenticado.
  /// Intenta primero `/notificaciones/mis-notificaciones` y recurre a `/notificaciones`.
  static Future<Map<String, dynamic>> obtenerNotificaciones({
    bool soloNoLeidas = false,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final baseUrl = await ApiConfig.resolveBaseUrl();
      final headers = await _getHeaders();

      final query = 'solo_no_leidas=$soloNoLeidas&page=$page&limit=$limit';
      var uri = Uri.parse('$baseUrl/notificaciones/mis-notificaciones?$query');

      http.Response response;
      try {
        response = await http.get(uri, headers: headers).timeout(
              const Duration(seconds: 10),
            );
        // Fallback a ruta estándar si el endpoint alias retornara 404
        if (response.statusCode == 404) {
          final fallbackUri = Uri.parse('$baseUrl/notificaciones?$query');
          response = await http.get(fallbackUri, headers: headers).timeout(
                const Duration(seconds: 10),
              );
        }
      } on SocketException {
        return {
          'success': false,
          'message': 'Sin conexión al servidor. Revisa tu acceso a internet.',
          'notificaciones': <NotificacionModel>[],
          'total_no_leidas': 0,
        };
      } on TimeoutException {
        return {
          'success': false,
          'message': 'El servidor tardó demasiado en responder.',
          'notificaciones': <NotificacionModel>[],
          'total_no_leidas': 0,
        };
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        final dynamic rawData = body['data'];
        final int totalNoLeidas = body['total_no_leidas'] as int? ?? 0;
        final int total = body['total'] as int? ?? 0;

        List<NotificacionModel> notificaciones = [];
        if (rawData is List) {
          notificaciones = rawData
              .whereType<Map<String, dynamic>>()
              .map(NotificacionModel.fromJson)
              .toList();
        }

        return {
          'success': true,
          'notificaciones': notificaciones,
          'total_no_leidas': totalNoLeidas,
          'total': total,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Sesión expirada. Inicia sesión nuevamente.',
          'notificaciones': <NotificacionModel>[],
          'total_no_leidas': 0,
        };
      } else {
        return {
          'success': false,
          'message': 'Error al cargar notificaciones (${response.statusCode}).',
          'notificaciones': <NotificacionModel>[],
          'total_no_leidas': 0,
        };
      }
    } catch (e) {
      debugPrint('Error en obtenerNotificaciones: $e');
      return {
        'success': false,
        'message': 'Ocurrió un error inesperado al consultar tus avisos.',
        'notificaciones': <NotificacionModel>[],
        'total_no_leidas': 0,
      };
    }
  }

  /// Obtiene solo el conteo de notificaciones no leídas para el badge del AppBar.
  static Future<int> obtenerContadorNoLeidas() async {
    try {
      final baseUrl = await ApiConfig.resolveBaseUrl();
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/notificaciones/contador-no-leidas');

      final response = await http.get(uri, headers: headers).timeout(
            const Duration(seconds: 8),
          );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        final data = body['data'] as Map<String, dynamic>?;
        return (data?['total_no_leidas'] as int?) ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('Error en obtenerContadorNoLeidas: $e');
      return 0;
    }
  }

  /// Marca una notificación individual como leída.
  static Future<bool> marcarComoLeida(int idNotificacion) async {
    try {
      final baseUrl = await ApiConfig.resolveBaseUrl();
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/notificaciones/$idNotificacion/leer');

      final response = await http.patch(uri, headers: headers).timeout(
            const Duration(seconds: 8),
          );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error en marcarComoLeida: $e');
      return false;
    }
  }

  /// Marca todas las notificaciones del usuario como leídas.
  static Future<int> marcarTodasComoLeidas() async {
    try {
      final baseUrl = await ApiConfig.resolveBaseUrl();
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/notificaciones/leer-todas');

      final response = await http.patch(uri, headers: headers).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        final data = body['data'] as Map<String, dynamic>?;
        return (data?['marcadas'] as int?) ?? 1;
      }
      return 0;
    } catch (e) {
      debugPrint('Error en marcarTodasComoLeidas: $e');
      return 0;
    }
  }

  /// Elimina una notificación de la bandeja.
  static Future<bool> eliminarNotificacion(int idNotificacion) async {
    try {
      final baseUrl = await ApiConfig.resolveBaseUrl();
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/notificaciones/$idNotificacion');

      final response = await http.delete(uri, headers: headers).timeout(
            const Duration(seconds: 8),
          );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error en eliminarNotificacion: $e');
      return false;
    }
  }
}

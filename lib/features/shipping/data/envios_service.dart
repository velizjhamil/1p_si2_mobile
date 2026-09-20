import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';
import '../../../../core/storage/secure_storage_service.dart';
import 'envio_tracking_model.dart';

/// Servicio HTTP para consultar el seguimiento de envíos en tiempo real (CU18).
class EnviosService {
  const EnviosService._();

  static Future<Map<String, String>> _getHeaders() async {
    final token = await SecureStorageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Obtiene la trazabilidad detallada del envío para una venta específica.
  static Future<Map<String, dynamic>> obtenerSeguimiento(int idVenta) async {
    try {
      final baseUrl = await ApiConfig.resolveBaseUrl();
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/envios/seguimiento/$idVenta');

      final response = await http.get(uri, headers: headers).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        final data = body['data'] as Map<String, dynamic>?;

        if (data != null) {
          final tracking = EnvioTrackingModel.fromJson(data);
          return {
            'success': true,
            'tracking': tracking,
          };
        }
        return {
          'success': false,
          'message': 'Datos de seguimiento incompletos o vacíos.',
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'No se encontró información de envío para este pedido.',
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': 'No tienes autorización para consultar este envío.',
        };
      } else {
        return {
          'success': false,
          'message': 'Error al consultar el rastreo (${response.statusCode}).',
        };
      }
    } on SocketException {
      return {
        'success': false,
        'message': 'Sin conexión al servidor. Verifica tu conexión a internet.',
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Tiempo de espera agotado al consultar el seguimiento.',
      };
    } catch (e) {
      debugPrint('Error en obtenerSeguimiento: $e');
      return {
        'success': false,
        'message': 'Ocurrió un error inesperado al rastrear tu compra.',
      };
    }
  }

  /// Lista todos los envíos asociados al cliente autenticado.
  static Future<Map<String, dynamic>> obtenerMisEnvios() async {
    try {
      final baseUrl = await ApiConfig.resolveBaseUrl();
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/envios/mis-envios');

      final response = await http.get(uri, headers: headers).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        final dynamic rawData = body['data'];
        List<EnvioTrackingModel> envios = [];

        if (rawData is List) {
          envios = rawData
              .whereType<Map<String, dynamic>>()
              .map(EnvioTrackingModel.fromJson)
              .toList();
        }

        return {
          'success': true,
          'envios': envios,
        };
      } else {
        return {
          'success': false,
          'message': 'No se pudo cargar la lista de envíos (${response.statusCode}).',
          'envios': <EnvioTrackingModel>[],
        };
      }
    } on SocketException {
      return {
        'success': false,
        'message': 'Sin conexión al servidor.',
        'envios': <EnvioTrackingModel>[],
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Tiempo de espera agotado.',
        'envios': <EnvioTrackingModel>[],
      };
    } catch (e) {
      debugPrint('Error en obtenerMisEnvios: $e');
      return {
        'success': false,
        'message': 'Error al obtener tus envíos.',
        'envios': <EnvioTrackingModel>[],
      };
    }
  }
}

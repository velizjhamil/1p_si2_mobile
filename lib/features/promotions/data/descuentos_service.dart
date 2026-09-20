import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../../core/storage/secure_storage_service.dart';
import 'descuento_model.dart';

/// Servicio HTTP para la consulta de Descuentos y Promociones activas (CU12).
class DescuentosService {
  DescuentosService._();

  /// Obtiene los descuentos y cupones vigentes en la plataforma.
  ///
  /// Consume prioritariamente `GET /api/v1/descuentos/activos` (acceso público para clientes),
  /// con fallback a `GET /api/v1/descuentos?activo=true&vigente_hoy=true`.
  static Future<Map<String, dynamic>> obtenerDescuentosActivos({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final String baseUrl = await ApiConfig.resolveBaseUrl();
      final String? token = await SecureStorageService.getToken();

      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        'activo': 'true',
        'vigente_hoy': 'true',
      };

      final headers = <String, String>{
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      // Intentar primero endpoint público /descuentos/activos
      final uriActivos = Uri.parse('$baseUrl/descuentos/activos').replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      var response = await http
          .get(uriActivos, headers: headers)
          .timeout(const Duration(seconds: 12));

      // Si el token almacenado fuese rechazado con 401 (ej. expirado en el cliente),
      // reintentar de forma pública sin token, ya que las ofertas activas son públicas
      if (response.statusCode == 401 && headers.containsKey('Authorization')) {
        final publicHeaders = <String, String>{'Accept': 'application/json'};
        response = await http
            .get(uriActivos, headers: publicHeaders)
            .timeout(const Duration(seconds: 12));
      }

      // Fallback a /descuentos con query params si el alias respondiera 404
      if (response.statusCode == 404) {
        final uriFallback = Uri.parse('$baseUrl/descuentos').replace(
          queryParameters: queryParams,
        );
        response = await http
            .get(uriFallback, headers: headers)
            .timeout(const Duration(seconds: 12));
      }

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is! Map<String, dynamic> || decoded['data'] is! List) {
          return {
            'success': false,
            'message': 'Formato de respuesta del servidor no reconocido.',
            'descuentos': <DescuentoModel>[],
            'total': 0,
          };
        }

        final items = (decoded['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map(DescuentoModel.fromJson)
            .where((d) => d.activo)
            .toList();

        final total = (decoded['total'] as num?)?.toInt() ?? items.length;

        return {
          'success': true,
          'descuentos': items,
          'total': total,
        };
      }

      String mensajeServidor = 'Error al consultar promociones (código ${response.statusCode}).';
      try {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          if (decoded['detail'] != null) {
            mensajeServidor = decoded['detail'].toString();
          } else if (decoded['message'] != null) {
            mensajeServidor = decoded['message'].toString();
          }
        }
      } catch (_) {}

      return {
        'success': false,
        'message': mensajeServidor,
        'descuentos': <DescuentoModel>[],
        'total': 0,
      };
    } on SocketException {
      return {
        'success': false,
        'message': 'Sin conexión con el servidor. Revisa tu conexión a internet o red local.',
        'descuentos': <DescuentoModel>[],
        'total': 0,
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'El servidor tardó demasiado en responder al consultar promociones.',
        'descuentos': <DescuentoModel>[],
        'total': 0,
      };
    } on http.ClientException {
      return {
        'success': false,
        'message': 'Error de comunicación con el servidor. Verifica tu conexión.',
        'descuentos': <DescuentoModel>[],
        'total': 0,
      };
    } on FormatException {
      return {
        'success': false,
        'message': 'Formato de promociones no reconocido por la aplicación.',
        'descuentos': <DescuentoModel>[],
        'total': 0,
      };
    } on TypeError {
      return {
        'success': false,
        'message': 'Error al procesar los datos de las promociones.',
        'descuentos': <DescuentoModel>[],
        'total': 0,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Ocurrió un error inesperado al cargar los descuentos: $e',
        'descuentos': <DescuentoModel>[],
        'total': 0,
      };
    }
  }
}

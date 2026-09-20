import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../../core/storage/secure_storage_service.dart';
import 'models/ia_chat_message.dart';
import 'models/producto_resumen_ia.dart';

/// Structured response returned by [AsistenteIAService.enviarMensaje].
class IAChatResult {
  const IAChatResult({
    required this.success,
    this.respuesta = '',
    this.productosRecomendados = const [],
    this.productosDetalle = const [],
    this.sugerencias = const [],
    this.mensajeError,
  });

  factory IAChatResult.exito({
    required String respuesta,
    required List<int> productosRecomendados,
    required List<ProductoResumenIA> productosDetalle,
    required List<String> sugerencias,
  }) {
    return IAChatResult(
      success: true,
      respuesta: respuesta,
      productosRecomendados: productosRecomendados,
      productosDetalle: productosDetalle,
      sugerencias: sugerencias,
    );
  }

  factory IAChatResult.error(String mensaje) {
    return IAChatResult(
      success: false,
      mensajeError: mensaje,
    );
  }

  final bool success;
  final String respuesta;
  final List<int> productosRecomendados;
  final List<ProductoResumenIA> productosDetalle;
  final List<String> sugerencias;
  final String? mensajeError;
}

/// Service handling communication with the Attention AI assistant endpoint (CU25).
class AsistenteIAService {
  AsistenteIAService._();

  static const Duration _timeout = Duration(seconds: 35);

  /// Sends a user prompt and optional conversation history to `POST /api/v1/ia/chat`.
  static Future<IAChatResult> enviarMensaje({
    required String mensaje,
    List<IAChatMessage> historial = const [],
  }) async {
    try {
      final String baseUrl = await ApiConfig.resolveBaseUrl();
      final String? token = await SecureStorageService.getToken();

      final Uri uri = Uri.parse('$baseUrl/ia/chat');

      // Filter and map previous messages for conversation context (up to last 10 messages)
      final List<Map<String, String>> historialPayload = historial
          .where((m) => !m.isError && m.contenido.trim().isNotEmpty)
          .toList()
          .reversed
          .take(10)
          .toList()
          .reversed
          .map((m) => m.toHistorialMap())
          .toList();

      final Map<String, dynamic> bodyPayload = {
        'mensaje': mensaje.trim(),
        'historial': historialPayload,
      };

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode(bodyPayload),
          )
          .timeout(_timeout);

      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>) {
          final Map<String, dynamic> data = decoded['data'] as Map<String, dynamic>;

          final String respuesta = data['respuesta'] as String? ?? '';
          
          final List<int> recomendados = (data['productos_recomendados'] as List?)
                  ?.map((e) => (e as num).toInt())
                  .toList() ??
              const [];

          final List<ProductoResumenIA> detalles = (data['productos_detalle'] as List?)
                  ?.whereType<Map<String, dynamic>>()
                  .map(ProductoResumenIA.fromJson)
                  .toList() ??
              const [];

          final List<String> sugerencias = (data['sugerencias'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const [];

          return IAChatResult.exito(
            respuesta: respuesta,
            productosRecomendados: recomendados,
            productosDetalle: detalles,
            sugerencias: sugerencias,
          );
        } else {
          return IAChatResult.error('Formato de respuesta no reconocido por el servidor.');
        }
      }

      // Handle HTTP error responses
      String errorMessage = 'No pudimos procesar tu consulta (código ${response.statusCode}).';
      if (decoded is Map<String, dynamic>) {
        if (decoded['detail'] != null) {
          errorMessage = decoded['detail'].toString();
        } else if (decoded['message'] != null) {
          errorMessage = decoded['message'].toString();
        }
      }
      return IAChatResult.error(errorMessage);

    } on TimeoutException {
      return IAChatResult.error(
        'El asistente tardó demasiado en responder. Por favor intenta de nuevo.',
      );
    } on SocketException {
      return IAChatResult.error(
        'No hay conexión con el servidor. Revisa tu conexión a internet o red local.',
      );
    } on http.ClientException {
      return IAChatResult.error(
        'Error de comunicación con el servicio de Inteligencia Artificial.',
      );
    } on FormatException {
      return IAChatResult.error(
        'Respuesta inesperada recibida del servidor.',
      );
    } catch (e) {
      return IAChatResult.error('Ocurrió un error imprevisto: $e');
    }
  }

  /// Verifies if the AI service and Gemini model are online (`GET /api/v1/ia/status`).
  static Future<bool> verificarEstado() async {
    try {
      final String baseUrl = await ApiConfig.resolveBaseUrl();
      final response = await http
          .get(Uri.parse('$baseUrl/ia/status'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>) {
          return decoded['data']['estado'] == 'activo';
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

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

/// Service handling communication with the Attention AI assistant endpoint.
class AsistenteIAService {
 AsistenteIAService._();

 static const Duration _timeout = Duration(seconds: 35);

 /// Sends a user prompt and optional conversation history to `POST /api/v1/ia/chat` (or `/api/v1/chat`).
 static Future<IAChatResult> enviarMensaje({
 required String mensaje,
 List<IAChatMessage> historial = const [],
 int? idSucursal,
 String? nombreSucursal,
 String? generoUsuario,
 String? nombreUsuario,
 }) async {
 try {
 final String baseUrl = await ApiConfig.resolveBaseUrl();
 final String? token = await SecureStorageService.getToken();

 // Excluir el mensaje actual si ya se agregó al final del historial en la UI
 final List<IAChatMessage> previousMessages = historial
 .where((m) => !m.isError && m.contenido.trim().isNotEmpty)
 .toList();

 if (previousMessages.isNotEmpty &&
 previousMessages.last.isUser &&
 previousMessages.last.contenido.trim() == mensaje.trim()) {
 previousMessages.removeLast();
 }

 final List<Map<String, String>> historialPayload = previousMessages
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

 if (idSucursal != null) {
 bodyPayload['id_sucursal'] = idSucursal;
 }
 if (nombreSucursal != null && nombreSucursal.isNotEmpty) {
 bodyPayload['nombre_sucursal'] = nombreSucursal;
 }
 if (generoUsuario != null && generoUsuario.isNotEmpty) {
 bodyPayload['genero_usuario'] = generoUsuario;
 }
 if (nombreUsuario != null && nombreUsuario.isNotEmpty) {
 bodyPayload['nombre_usuario'] = nombreUsuario;
 }

 final headers = <String, String>{
 'Content-Type': 'application/json',
 'Accept': 'application/json',
 if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
 };

 // Intentar primero con /ia/chat, con fallback a /chat si el router está en raíz
 Uri uri = Uri.parse('$baseUrl/ia/chat');
 http.Response response = await http
 .post(
 uri,
 headers: headers,
 body: jsonEncode(bodyPayload),
 )
 .timeout(_timeout);

 if (response.statusCode == 404) {
 uri = Uri.parse('$baseUrl/chat');
 response = await http
 .post(
 uri,
 headers: headers,
 body: jsonEncode(bodyPayload),
 )
 .timeout(_timeout);
 }

 final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));

 if (response.statusCode >= 200 && response.statusCode < 300) {
 Map<String, dynamic>? dataMap;
 if (decoded is Map<String, dynamic>) {
 if (decoded['data'] is Map<String, dynamic>) {
 dataMap = decoded['data'] as Map<String, dynamic>;
 } else if (decoded.containsKey('respuesta')) {
 dataMap = decoded;
 }
 }

 if (dataMap != null) {
 final String respuesta = dataMap['respuesta'] as String? ?? '';

 final List<int> recomendados = (dataMap['productos_recomendados'] as List?)
 ?.map((e) => (e as num).toInt())
 .toList() ??
 const [];

 final List<ProductoResumenIA> detalles = (dataMap['productos_detalle'] as List?)
 ?.whereType<Map<String, dynamic>>()
 .map(ProductoResumenIA.fromJson)
 .toList() ??
 const [];

 final List<String> sugerencias = (dataMap['sugerencias'] as List?)
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
 if (decoded is Map<String, dynamic>) {
 final dynamic data = decoded['data'];
 if (data is Map<String, dynamic>) {
 return data['database_online'] == true || data['estado'] == 'activo';
 }
 return decoded['status'] == 'success';
 }
 }
 return false;
 } catch (_) {
 return false;
 }
 }
}

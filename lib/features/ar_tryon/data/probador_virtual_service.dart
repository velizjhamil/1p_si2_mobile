import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../../core/storage/secure_storage_service.dart';

/// User photograph record registered in the AI virtual fitting room.
class FotoUsuario {
 const FotoUsuario({
 required this.idFoto,
 required this.urlImagen,
 required this.complexion,
 this.estaturaCm,
 this.pesoKg,
 this.fechaSubida,
 });

 factory FotoUsuario.fromJson(Map<String, dynamic> json) {
 DateTime? fecha;
 if (json['fecha_subida'] != null) {
 fecha = DateTime.tryParse(json['fecha_subida'] as String);
 }

 return FotoUsuario(
 idFoto: (json['id_foto'] as num?)?.toInt() ?? 0,
 urlImagen: json['url_imagen'] as String? ?? '',
 complexion: json['complexion'] as String? ?? 'NO_INDICADA',
 estaturaCm: (json['estatura_cm'] as num?)?.toInt(),
 pesoKg: (json['peso_kg'] as num?)?.toInt(),
 fechaSubida: fecha,
 );
 }

 final int idFoto;
 final String urlImagen;
 final String complexion;
 final int? estaturaCm;
 final int? pesoKg;
 final DateTime? fechaSubida;
}

/// Result of an AI virtual fitting simulation.
class SimulacionProbadorResult {
 const SimulacionProbadorResult({
 required this.idSimulacion,
 required this.productoId,
 required this.productoNombre,
 required this.tallaSeleccionada,
 required this.tallaRecomendada,
 required this.ajusteEstimado,
 this.prendaImagenUrl,
 this.resultadoImagenUrl,
 this.colorSeleccionado,
 this.colorHex,
 this.precio,
 this.categoria,
 this.fechaSimulacion,
 this.guardada = false,
 });

 factory SimulacionProbadorResult.fromJson(Map<String, dynamic> json) {
 DateTime? fecha;
 if (json['fecha_simulacion'] != null) {
 fecha = DateTime.tryParse(json['fecha_simulacion'] as String);
 }

 return SimulacionProbadorResult(
 idSimulacion: json['id_simulacion'] as int? ?? 0,
 productoId: json['producto_id'] as int? ?? 0,
 productoNombre: json['producto_nombre'] as String? ?? 'Prenda',
 prendaImagenUrl: json['prenda_imagen_url'] as String?,
 resultadoImagenUrl: json['resultado_imagen_url'] as String?,
 tallaSeleccionada: json['talla_seleccionada'] as String? ?? 'M',
 tallaRecomendada: json['talla_recomendada'] as String? ?? 'M',
 ajusteEstimado: json['ajuste_estimado'] as String? ?? 'PERFECTO',
 colorSeleccionado: json['color_seleccionado'] as String?,
 colorHex: json['color_hex'] as String?,
 precio: (json['precio'] as num?)?.toDouble(),
 categoria: json['categoria'] as String?,
 fechaSimulacion: fecha,
 guardada: json['guardada'] as bool? ?? false,
 );
 }

 final int idSimulacion;
 final int productoId;
 final String productoNombre;
 final String? prendaImagenUrl;
 final String? resultadoImagenUrl;
 final String tallaSeleccionada;
 final String tallaRecomendada;
 final String ajusteEstimado; // PERFECTO, AJUSTADO, HOLGADO
 final String? colorSeleccionado;
 final String? colorHex;
 final double? precio;
 final String? categoria;
 final DateTime? fechaSimulacion;
 final bool guardada;
}

/// Service connecting Attention Mobile to the FastAPI AI Virtual Try-On endpoints.
///
/// Endpoints:
/// - POST /api/v1/probador-virtual/subir-foto
/// - POST /api/v1/probador-virtual/probar
/// - GET /api/v1/probador-virtual/fotos
class ProbadorVirtualService {
 ProbadorVirtualService._();

 /// Submits the client's photograph as a data URL (base64) along with optional
 /// anthropometric measurements (estatura in cm, peso in kg).
 static Future<Map<String, dynamic>> subirFoto({
 required String imagenDataUrl,
 int? estatura,
 int? peso,
 http.Client? client,
 }) async {
 final String baseUrl = await ApiConfig.resolveBaseUrl();
 final String? token = await SecureStorageService.getToken();

 if (token == null || token.isEmpty) {
 return {
 'success': false,
 'message': 'No hay sesión activa. Inicie sesión para usar el probador.',
 };
 }

 // Ensure proper Data URL scheme prefix
 String formattedUrl = imagenDataUrl.trim();
 if (!formattedUrl.startsWith('data:image/')) {
 formattedUrl = 'data:image/jpeg;base64,$formattedUrl';
 }

 final payload = <String, dynamic>{
 'imagen_data_url': formattedUrl,
 if (estatura != null && estatura >= 100 && estatura <= 230)
 'estatura': estatura,
 if (peso != null && peso >= 25 && peso <= 250) 'peso': peso,
 };

 final httpClient = client ?? http.Client();
 try {
 final response = await httpClient
 .post(
 Uri.parse('$baseUrl/probador-virtual/subir-foto'),
 headers: {
 'Content-Type': 'application/json',
 'Authorization': 'Bearer $token',
 },
 body: jsonEncode(payload),
 )
 .timeout(const Duration(seconds: 60));

 final Map<String, dynamic> body =
 jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

 if (response.statusCode == 201 && body['status'] == 'success') {
 final data = body['data'] as Map<String, dynamic>;
 return {
 'success': true,
 'foto': FotoUsuario.fromJson(data),
 'message': body['message'] ?? 'Foto analizada con éxito.',
 };
 }

 final errorMsg = body['detail'] ?? body['message'] ?? 'Error al subir foto.';
 return {
 'success': false,
 'message': errorMsg.toString(),
 };
 } on TimeoutException {
 return {
 'success': false,
 'message': 'Tiempo de espera agotado al conectar con el motor de IA.',
 };
 } on SocketException {
 return {
 'success': false,
 'message': 'Sin conexión al servidor del probador virtual.',
 };
 } on http.ClientException {
 return {
 'success': false,
 'message': 'Error de comunicación con el servidor. Verifica tu conexión.',
 };
 } on FormatException {
 return {
 'success': false,
 'message': 'Respuesta no válida del motor de IA.',
 };
 } on TypeError {
 return {
 'success': false,
 'message': 'Error al procesar la respuesta del análisis corporal.',
 };
 } catch (_) {
 return {
 'success': false,
 'message': 'Ocurrió un error inesperado al procesar la fotografía.',
 };
 } finally {
 if (client == null) {
 httpClient.close();
 }
 }
 }

 /// Sends the selected garment, size and color to simulate try-on over the user's photo.
 static Future<Map<String, dynamic>> probarPrenda({
 required int fotoId,
 required int productoId,
 required String talla,
 String? colorNombre,
 String? colorHex,
 String? prendaImagenUrl,
 http.Client? client,
 }) async {
 final String baseUrl = await ApiConfig.resolveBaseUrl();
 final String? token = await SecureStorageService.getToken();

 if (token == null || token.isEmpty) {
 return {
 'success': false,
 'message': 'Sesión caducada. Vuelva a iniciar sesión.',
 };
 }

 String? sanitizedHex = colorHex?.trim();
 if (sanitizedHex != null && !sanitizedHex.startsWith('#')) {
 sanitizedHex = '#$sanitizedHex';
 }
 if (sanitizedHex != null && sanitizedHex.length != 7) {
 sanitizedHex = null; // Backend expects #RRGGBB
 }

 final payload = <String, dynamic>{
 'foto_id': fotoId,
 'producto_id': productoId,
 'talla_seleccionada': talla.trim().toUpperCase(),
 if (colorNombre != null && colorNombre.isNotEmpty)
 'color_nombre': colorNombre.trim(),
 'color_hex': ?sanitizedHex,
 if (prendaImagenUrl != null && prendaImagenUrl.isNotEmpty)
 'prenda_imagen_url': prendaImagenUrl.trim(),
 };

 final httpClient = client ?? http.Client();
 try {
 final response = await httpClient
 .post(
 Uri.parse('$baseUrl/probador-virtual/probar'),
 headers: {
 'Content-Type': 'application/json',
 'Authorization': 'Bearer $token',
 },
 body: jsonEncode(payload),
 )
 .timeout(const Duration(seconds: 90));

 final Map<String, dynamic> body =
 jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

 if (response.statusCode == 201 && body['status'] == 'success') {
 final data = body['data'] as Map<String, dynamic>;
 return {
 'success': true,
 'simulacion': SimulacionProbadorResult.fromJson(data),
 'message': body['message'] ?? 'Simulación procesada.',
 };
 }

 final errorMsg =
 body['detail'] ?? body['message'] ?? 'No se pudo procesar la simulación.';
 return {
 'success': false,
 'message': errorMsg.toString(),
 };
 } on TimeoutException {
 return {
 'success': false,
 'message': 'La simulación tomó más tiempo del esperado. Por favor intente nuevamente.',
 };
 } on SocketException {
 return {
 'success': false,
 'message': 'Sin conexión con el servidor del probador virtual.',
 };
 } on http.ClientException {
 return {
 'success': false,
 'message': 'Error de comunicación con el servidor al simular.',
 };
 } on FormatException {
 return {
 'success': false,
 'message': 'Formato no reconocido en el resultado de simulación.',
 };
 } on TypeError {
 return {
 'success': false,
 'message': 'Error al procesar la simulación de la prenda.',
 };
 } catch (_) {
 return {
 'success': false,
 'message': 'Ocurrió un error inesperado al realizar la simulación.',
 };
 } finally {
 if (client == null) {
 httpClient.close();
 }
 }
 }

 /// Retrieves previously uploaded photos for the active client.
 static Future<Map<String, dynamic>> obtenerFotosRecientes({
 int limit = 10,
 http.Client? client,
 }) async {
 final String baseUrl = await ApiConfig.resolveBaseUrl();
 final String? token = await SecureStorageService.getToken();

 if (token == null || token.isEmpty) {
 return {'success': false, 'message': 'No autenticado.', 'fotos': <FotoUsuario>[]};
 }

 final httpClient = client ?? http.Client();
 try {
 final response = await httpClient
 .get(
 Uri.parse('$baseUrl/probador-virtual/fotos?limit=$limit'),
 headers: {
 'Authorization': 'Bearer $token',
 },
 )
 .timeout(const Duration(seconds: 15));

 if (response.statusCode == 200) {
 final Map<String, dynamic> body =
 jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
 final dynamic rawList = body['data'];
 if (rawList is List) {
 final items = rawList
 .whereType<Map<String, dynamic>>()
 .map(FotoUsuario.fromJson)
 .toList();
 return {'success': true, 'fotos': items};
 }
 }

 return {'success': false, 'fotos': <FotoUsuario>[]};
 } catch (_) {
 return {'success': false, 'fotos': <FotoUsuario>[]};
 } finally {
 if (client == null) {
 httpClient.close();
 }
 }
 }

 /// Invocación directa al modelo Nano Banana Pro (Gemini Pro Image) en POST /api/v1/ia/try-on-nano.
 static Future<Map<String, dynamic>> probarPrendaNanoBanana({
 required String imagenUsuario,
 required String prendaUrl,
 String productoNombre = 'Prenda de Catálogo',
 String productoCategoria = 'Ropa',
 String talla = 'M',
 List<String> tallasDisponibles = const ['S', 'M', 'L', 'XL'],
 String? colorNombre,
 String? colorHex,
 int? estaturaCm,
 int? pesoKg,
 String complexion = 'MEDIA',
 http.Client? client,
 }) async {
 final String baseUrl = await ApiConfig.resolveBaseUrl();
 final String? token = await SecureStorageService.getToken();

 final payload = <String, dynamic>{
 'imagen_usuario': imagenUsuario,
 'prenda_url': prendaUrl,
 'producto_nombre': productoNombre,
 'producto_categoria': productoCategoria,
 'talla': talla,
 'tallas_disponibles': tallasDisponibles,
 if (colorNombre != null && colorNombre.isNotEmpty) 'color_nombre': colorNombre,
 if (colorHex != null && colorHex.isNotEmpty) 'color_hex': colorHex,
 'estatura_cm': ?estaturaCm,
 'peso_kg': ?pesoKg,
 'complexion': complexion,
 };

 final httpClient = client ?? http.Client();
 try {
 final response = await httpClient
 .post(
 Uri.parse('$baseUrl/ia/try-on-nano'),
 headers: {
 'Content-Type': 'application/json',
 if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
 },
 body: jsonEncode(payload),
 )
 .timeout(const Duration(seconds: 90));

 final Map<String, dynamic> body =
 jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

 if (response.statusCode == 200 && body['status'] == 'success') {
 final data = body['data'] as Map<String, dynamic>;
 return {
 'success': true,
 'data': data,
 'message': body['message'] ?? 'Simulación hiperrealista generada con éxito con Nano Banana Pro.',
 };
 }

 final errorMsg = body['detail'] ?? body['message'] ?? 'Error en Nano Banana Pro.';
 return {
 'success': false,
 'message': errorMsg.toString(),
 };
 } on TimeoutException {
 return {
 'success': false,
 'message': 'El modelo Nano Banana Pro tardó más de lo esperado. Intenta nuevamente.',
 };
 } catch (e) {
 return {
 'success': false,
 'message': 'Error de conexión con el motor Nano Banana Pro: $e',
 };
 } finally {
 if (client == null) {
 httpClient.close();
 }
 }
 }
}

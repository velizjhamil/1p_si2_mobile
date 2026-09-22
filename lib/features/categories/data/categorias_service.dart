import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../../core/storage/secure_storage_service.dart';

/// Category model for (Gestión de Categorías).
class Categoria {
 const Categoria({
 required this.idCategoria,
 required this.nombre,
 required this.linea,
 this.descripcion,
 required this.activo,
 this.fechaCreacion,
 });

 factory Categoria.fromJson(Map<String, dynamic> json) {
 final dynamic fechaRaw = json['fecha_creacion'];
 DateTime? fechaCreacion;
 if (fechaRaw is String && fechaRaw.isNotEmpty) {
 try {
 fechaCreacion = DateTime.parse(fechaRaw);
 } on FormatException {
 fechaCreacion = null;
 }
 }

 return Categoria(
 idCategoria: (json['id_categoria'] as num?)?.toInt() ?? 0,
 nombre: json['nombre'] as String? ?? '',
 linea: json['linea'] as String? ?? 'Unisex',
 descripcion: json['descripcion'] as String?,
 activo: json['activo'] as bool? ?? true,
 fechaCreacion: fechaCreacion,
 );
 }

 final int idCategoria;
 final String nombre;
 final String linea; // Hombre, Mujer, Unisex
 final String? descripcion;
 final bool activo;
 final DateTime? fechaCreacion;
}

/// Service that consumes the backend /categorias endpoint.
class CategoriasService {
 CategoriasService._();

 /// Fetches paginated and filtered categories.
 static Future<Map<String, dynamic>> listar({
 String? q,
 String? linea,
 int page = 1,
 int limit = 50,
 }) async {
 try {
 final String baseUrl = await ApiConfig.resolveBaseUrl();
 final String? token = await SecureStorageService.getToken();

 final queryParams = <String, String>{
 'page': page.toString(),
 'limit': limit.toString(),
 };
 if (q != null && q.trim().isNotEmpty) {
 queryParams['q'] = q.trim();
 }
 if (linea != null && linea.trim().isNotEmpty && linea != 'Todas') {
 queryParams['linea'] = linea.trim();
 }

 final headers = <String, String>{
 'Accept': 'application/json',
 if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
 };

 final uri = Uri.parse('$baseUrl/categorias').replace(queryParameters: queryParams);

 final response = await http
 .get(uri, headers: headers)
 .timeout(const Duration(seconds: 15));

 if (response.statusCode != 200) {
 return {
 'success': false,
 'message': 'Error del servidor (código ${response.statusCode})',
 'categorias': <Categoria>[],
 'total': 0,
 };
 }

 final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
 if (decoded is! Map<String, dynamic> || decoded['data'] is! List) {
 return {
 'success': false,
 'message': 'Respuesta del servidor inválida.',
 'categorias': <Categoria>[],
 'total': 0,
 };
 }

 final items = (decoded['data'] as List)
 .whereType<Map<String, dynamic>>()
 .map(Categoria.fromJson)
 .toList();

 final total = (decoded['total'] as num?)?.toInt() ?? items.length;

 return {
 'success': true,
 'categorias': items,
 'total': total,
 };
 } on SocketException {
 return {
 'success': false,
 'message':
 'No se pudo conectar con el servidor. Revisa tu conexión de red.',
 'categorias': <Categoria>[],
 'total': 0,
 };
 } on TimeoutException {
 return {
 'success': false,
 'message': 'El servidor tardó demasiado en responder.',
 'categorias': <Categoria>[],
 'total': 0,
 };
 } on http.ClientException {
 return {
 'success': false,
 'message': 'Error de comunicación con el servidor. Verifica tu conexión.',
 'categorias': <Categoria>[],
 'total': 0,
 };
 } on FormatException {
 return {
 'success': false,
 'message': 'Formato de respuesta del servidor no reconocido.',
 'categorias': <Categoria>[],
 'total': 0,
 };
 } on TypeError {
 return {
 'success': false,
 'message': 'Error al procesar las categorías.',
 'categorias': <Categoria>[],
 'total': 0,
 };
 } catch (_) {
 return {
 'success': false,
 'message': 'Ocurrió un error inesperado al consultar categorías.',
 'categorias': <Categoria>[],
 'total': 0,
 };
 }
 }
}

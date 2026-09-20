import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../../core/storage/secure_storage_service.dart';

/// Lightweight product model for the client catalog.
class Producto {
  const Producto({
    required this.idProducto,
    required this.nombre,
    required this.precioVenta,
    required this.imagenUrl,
    this.descripcion,
    this.estado,
    this.idCategoria,
    this.nombreCategoria,
    this.tallas = const [],
    this.colores = const [],
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    final dynamic tallas = json['tallas'];
    final dynamic colores = json['colores'];
    final dynamic categoriaJson = json['categoria'];

    return Producto(
      idProducto: (json['id_producto'] as num?)?.toInt() ?? 0,
      nombre: json['nombre'] as String? ?? '',
      precioVenta: (json['precio_venta'] as num?)?.toDouble() ?? 0.0,
      imagenUrl: json['imagen_url'] as String?,
      descripcion: json['descripcion'] as String?,
      estado: json['estado'] as String?,
      idCategoria: (json['id_categoria'] as num?)?.toInt(),
      nombreCategoria: categoriaJson is Map<String, dynamic>
          ? categoriaJson['nombre'] as String?
          : null,
      tallas: tallas is List
          ? tallas
              .whereType<Map<String, dynamic>>()
              .map((t) => t['nombre_talla'] as String? ?? '')
              .where((n) => n.isNotEmpty)
              .toList()
          : const [],
      colores: colores is List
          ? colores.whereType<Map<String, dynamic>>().map(ColorDto.fromJson).toList()
          : const [],
    );
  }

  final int idProducto;
  final String nombre;
  final double precioVenta;
  final String? imagenUrl;
  final String? descripcion;
  final String? estado;
  final int? idCategoria;
  final String? nombreCategoria;
  final List<String> tallas;
  final List<ColorDto> colores;
}

/// Color option as returned by /productos (CU7 catalog).
class ColorDto {
  const ColorDto({required this.nombre, this.hex});

  factory ColorDto.fromJson(Map<String, dynamic> json) => ColorDto(
        nombre: json['nombre_color'] as String? ?? '',
        hex: json['codigo_hex'] as String?,
      );

  final String nombre;
  final String? hex;
}

/// Fetches the product catalog (CU6) for the client app.
class ProductosService {
  ProductosService._();

  static Future<Map<String, dynamic>> listar({
    String? q,
    int? idCategoria,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final String baseUrl = await ApiConfig.resolveBaseUrl();
      final String? token = await SecureStorageService.getToken();

      final query = <String, String>{
        'page': '$page',
        'limit': '$limit',
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        if (idCategoria != null && idCategoria > 0) 'id_categoria': '$idCategoria',
      };

      final headers = <String, String>{
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final response = await http
          .get(
            Uri.parse('$baseUrl/productos').replace(queryParameters: query),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': 'Error del servidor (código ${response.statusCode})',
          'productos': <Producto>[],
          'items': <Producto>[],
        };
      }

      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic> || decoded['data'] is! List) {
        return {
          'success': false,
          'message': 'Respuesta del servidor inválida.',
          'productos': <Producto>[],
          'items': <Producto>[],
        };
      }

      final productos = (decoded['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map(Producto.fromJson)
          .toList();

      final total = (decoded['total'] as num?)?.toInt() ?? productos.length;

      return {
        'success': true,
        'productos': productos,
        'items': productos,
        'total': total,
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'El servidor tardó demasiado en responder. Intenta nuevamente.',
        'productos': <Producto>[],
        'items': <Producto>[],
      };
    } on SocketException {
      return {
        'success': false,
        'message': 'No se pudo conectar con el servidor. Verifica tu conexión.',
        'productos': <Producto>[],
        'items': <Producto>[],
      };
    } on http.ClientException {
      return {
        'success': false,
        'message': 'Error de comunicación con el servidor. Verifica tu conexión.',
        'productos': <Producto>[],
        'items': <Producto>[],
      };
    } on FormatException {
      return {
        'success': false,
        'message': 'Formato de respuesta del servidor no reconocido.',
        'productos': <Producto>[],
        'items': <Producto>[],
      };
    } on TypeError {
      return {
        'success': false,
        'message': 'Error al procesar los datos de las prendas.',
        'productos': <Producto>[],
        'items': <Producto>[],
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'Ocurrió un error inesperado. Intenta nuevamente.',
        'productos': <Producto>[],
        'items': <Producto>[],
      };
    }
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';

/// Lightweight product model for the client catalog.
class Producto {
  const Producto({
    required this.idProducto,
    required this.nombre,
    required this.precioVenta,
    required this.imagenUrl,
    this.descripcion,
    this.estado,
    this.tallas = const [],
    this.colores = const [],
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    final dynamic tallas = json['tallas'];
    final dynamic colores = json['colores'];

    return Producto(
      idProducto: json['id_producto'] as int,
      nombre: json['nombre'] as String? ?? '',
      precioVenta: (json['precio_venta'] as num?)?.toDouble() ?? 0.0,
      imagenUrl: json['imagen_url'] as String?,
      descripcion: json['descripcion'] as String?,
      estado: json['estado'] as String?,
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
///
/// Public list endpoint: the backend exposes /productos without auth for
/// client browsing, so no Authorization header is attached.
class ProductosService {
  ProductosService._();

  static Future<Map<String, dynamic>> listar({
    String? q,
    int page = 1,
    int limit = 20,
  }) async {
    final String baseUrl = await ApiConfig.resolveBaseUrl();

    final query = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
    };

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/productos').replace(queryParameters: query),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': 'Error del servidor (código ${response.statusCode})',
        };
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> ||
          decoded['data'] is! List) {
        return {'success': false, 'message': 'Respuesta del servidor inválida.'};
      }

      final productos = (decoded['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map(Producto.fromJson)
          .toList();

      return {
        'success': true,
        'productos': productos,
        'total': decoded['total'] as int? ?? productos.length,
      };
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
    } catch (e) {
      return {
        'success': false,
        'message': 'Ocurrió un error inesperado. Intenta nuevamente.',
      };
    }
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';

/// Size (Talla) model for CU7 (Gestión de Tallas y Colores).
class Talla {
  const Talla({
    required this.idTalla,
    required this.nombreTalla,
    this.descripcion,
    required this.activo,
    this.fechaCreacion,
  });

  factory Talla.fromJson(Map<String, dynamic> json) {
    final dynamic fechaRaw = json['fecha_creacion'];
    DateTime? fechaCreacion;
    if (fechaRaw is String && fechaRaw.isNotEmpty) {
      try {
        fechaCreacion = DateTime.parse(fechaRaw);
      } on FormatException {
        fechaCreacion = null;
      }
    }

    return Talla(
      idTalla: json['id_talla'] as int? ?? 0,
      nombreTalla: json['nombre_talla'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      activo: json['activo'] as bool? ?? true,
      fechaCreacion: fechaCreacion,
    );
  }

  final int idTalla;
  final String nombreTalla;
  final String? descripcion;
  final bool activo;
  final DateTime? fechaCreacion;
}

/// Color model for CU7 (Gestión de Tallas y Colores).
class ColorItem {
  const ColorItem({
    required this.idColor,
    required this.nombreColor,
    required this.codigoHex,
    this.descripcion,
    required this.activo,
    this.fechaCreacion,
  });

  factory ColorItem.fromJson(Map<String, dynamic> json) {
    final dynamic fechaRaw = json['fecha_creacion'];
    DateTime? fechaCreacion;
    if (fechaRaw is String && fechaRaw.isNotEmpty) {
      try {
        fechaCreacion = DateTime.parse(fechaRaw);
      } on FormatException {
        fechaCreacion = null;
      }
    }

    return ColorItem(
      idColor: json['id_color'] as int? ?? 0,
      nombreColor: json['nombre_color'] as String? ?? '',
      codigoHex: json['codigo_hex'] as String? ?? '#000000',
      descripcion: json['descripcion'] as String?,
      activo: json['activo'] as bool? ?? true,
      fechaCreacion: fechaCreacion,
    );
  }

  final int idColor;
  final String nombreColor;
  final String codigoHex;
  final String? descripcion;
  final bool activo;
  final DateTime? fechaCreacion;
}

/// Service that consumes backend /tallas and /colores endpoints (CU7).
class TallasService {
  TallasService._();

  /// Fetches the list of available sizes.
  static Future<Map<String, dynamic>> listarTallas({
    String? q,
    int page = 1,
    int limit = 50,
  }) async {
    final String baseUrl = await ApiConfig.resolveBaseUrl();

    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (q != null && q.trim().isNotEmpty) {
      queryParams['q'] = q.trim();
    }

    final uri = Uri.parse('$baseUrl/tallas').replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': 'Error del servidor (código ${response.statusCode})',
        };
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['data'] is! List) {
        return {
          'success': false,
          'message': 'Respuesta del servidor inválida.',
        };
      }

      final items = (decoded['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map(Talla.fromJson)
          .toList();

      return {
        'success': true,
        'tallas': items,
        'total': decoded['total'] as int? ?? items.length,
      };
    } on SocketException {
      return {
        'success': false,
        'message':
            'No se pudo conectar con el servidor. Revisa tu conexión de red.',
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'El servidor tardó demasiado en responder.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al consultar tallas: $e',
      };
    }
  }

  /// Fetches the list of garment colors.
  static Future<Map<String, dynamic>> listarColores({
    String? q,
    int page = 1,
    int limit = 50,
  }) async {
    final String baseUrl = await ApiConfig.resolveBaseUrl();

    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (q != null && q.trim().isNotEmpty) {
      queryParams['q'] = q.trim();
    }

    final uri = Uri.parse('$baseUrl/colores').replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': 'Error del servidor (código ${response.statusCode})',
        };
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['data'] is! List) {
        return {
          'success': false,
          'message': 'Respuesta del servidor inválida.',
        };
      }

      final items = (decoded['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map(ColorItem.fromJson)
          .toList();

      return {
        'success': true,
        'colores': items,
        'total': decoded['total'] as int? ?? items.length,
      };
    } on SocketException {
      return {
        'success': false,
        'message': 'No se pudo conectar con el servidor.',
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'El servidor tardó demasiado en responder.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al consultar colores: $e',
      };
    }
  }
}

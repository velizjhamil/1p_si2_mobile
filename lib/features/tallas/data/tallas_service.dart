import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../../core/storage/secure_storage_service.dart';

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
      idTalla: (json['id_talla'] as num?)?.toInt() ?? 0,
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
      idColor: (json['id_color'] as num?)?.toInt() ?? 0,
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

      final headers = <String, String>{
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final uri = Uri.parse('$baseUrl/tallas').replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': 'Error del servidor (código ${response.statusCode})',
          'tallas': <Talla>[],
          'total': 0,
        };
      }

      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic> || decoded['data'] is! List) {
        return {
          'success': false,
          'message': 'Respuesta del servidor inválida.',
          'tallas': <Talla>[],
          'total': 0,
        };
      }

      final items = (decoded['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map(Talla.fromJson)
          .toList();

      final total = (decoded['total'] as num?)?.toInt() ?? items.length;

      return {
        'success': true,
        'tallas': items,
        'total': total,
      };
    } on SocketException {
      return {
        'success': false,
        'message':
            'No se pudo conectar con el servidor. Revisa tu conexión de red.',
        'tallas': <Talla>[],
        'total': 0,
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'El servidor tardó demasiado en responder.',
        'tallas': <Talla>[],
        'total': 0,
      };
    } on http.ClientException {
      return {
        'success': false,
        'message': 'Error de comunicación con el servidor. Verifica tu conexión.',
        'tallas': <Talla>[],
        'total': 0,
      };
    } on FormatException {
      return {
        'success': false,
        'message': 'Formato de respuesta del servidor no reconocido.',
        'tallas': <Talla>[],
        'total': 0,
      };
    } on TypeError {
      return {
        'success': false,
        'message': 'Error al procesar las tallas.',
        'tallas': <Talla>[],
        'total': 0,
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'Ocurrió un error inesperado al consultar tallas.',
        'tallas': <Talla>[],
        'total': 0,
      };
    }
  }

  /// Fetches the list of garment colors.
  static Future<Map<String, dynamic>> listarColores({
    String? q,
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

      final headers = <String, String>{
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final uri = Uri.parse('$baseUrl/colores').replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': 'Error del servidor (código ${response.statusCode})',
          'colores': <ColorItem>[],
          'total': 0,
        };
      }

      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic> || decoded['data'] is! List) {
        return {
          'success': false,
          'message': 'Respuesta del servidor inválida.',
          'colores': <ColorItem>[],
          'total': 0,
        };
      }

      final items = (decoded['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map(ColorItem.fromJson)
          .toList();

      final total = (decoded['total'] as num?)?.toInt() ?? items.length;

      return {
        'success': true,
        'colores': items,
        'total': total,
      };
    } on SocketException {
      return {
        'success': false,
        'message': 'No se pudo conectar con el servidor. Revisa tu red.',
        'colores': <ColorItem>[],
        'total': 0,
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'El servidor tardó demasiado en responder.',
        'colores': <ColorItem>[],
        'total': 0,
      };
    } on http.ClientException {
      return {
        'success': false,
        'message': 'Error de comunicación con el servidor. Verifica tu conexión.',
        'colores': <ColorItem>[],
        'total': 0,
      };
    } on FormatException {
      return {
        'success': false,
        'message': 'Formato de respuesta del servidor no reconocido.',
        'colores': <ColorItem>[],
        'total': 0,
      };
    } on TypeError {
      return {
        'success': false,
        'message': 'Error al procesar los colores.',
        'colores': <ColorItem>[],
        'total': 0,
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'Ocurrió un error inesperado al consultar colores.',
        'colores': <ColorItem>[],
        'total': 0,
      };
    }
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';

/// Category model for CU9 (Gestión de Categorías).
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
      idCategoria: json['id_categoria'] as int? ?? 0,
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

/// Service that consumes the backend /categorias endpoint (CU9).
class CategoriasService {
  CategoriasService._();

  /// Fetches paginated and filtered categories.
  ///
  /// Never throws. Always returns:
  /// - `{'success': true, 'categorias': List<Categoria>, 'total': int}`
  /// - `{'success': false, 'message': String}` on any failure.
  static Future<Map<String, dynamic>> listar({
    String? q,
    String? linea,
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
    if (linea != null && linea.trim().isNotEmpty && linea != 'Todas') {
      queryParams['linea'] = linea.trim();
    }

    final uri = Uri.parse('$baseUrl/categorias').replace(queryParameters: queryParams);

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
          .map(Categoria.fromJson)
          .toList();

      return {
        'success': true,
        'categorias': items,
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
        'message': 'Error inesperado al consultar categorías: $e',
      };
    }
  }
}

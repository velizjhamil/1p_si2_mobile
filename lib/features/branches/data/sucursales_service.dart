import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';

/// City (Ciudad) as returned by the public /ciudades endpoint.
///
/// Lightweight DTO used by the branches feature. Department may be null
/// for cities that do not yet have an associated department.
class Ciudad {
  const Ciudad({
    required this.id,
    required this.nombre,
    this.departamento,
  });

  /// Parses a Ciudad from a JSON object with a tolerant shape.
  factory Ciudad.fromJson(Map<String, dynamic> json) => Ciudad(
        id: json['id'] as int? ?? 0,
        nombre: json['nombre'] as String? ?? '',
        departamento: json['departamento'] as String?,
      );

  final int id;
  final String nombre;
  final String? departamento;
}

/// Branch (Sucursal) as returned by the public /sucursales endpoint.
class Sucursal {
  const Sucursal({
    required this.codigoSucursal,
    required this.nombre,
    this.direccion,
    this.telefono,
    this.horarioAtencion,
    required this.isActive,
    required this.ciudad,
    required this.empresaId,
    this.fechaActualizacion,
  });

  /// Parses a Sucursal from a JSON object with a tolerant shape.
  ///
  /// Missing or malformed fields fall back to safe defaults instead of
  /// throwing, so a single bad record does not break the whole list.
  factory Sucursal.fromJson(Map<String, dynamic> json) {
    final dynamic ciudadJson = json['ciudad'];
    final Ciudad ciudad = ciudadJson is Map<String, dynamic>
        ? Ciudad.fromJson(ciudadJson)
        : const Ciudad(id: 0, nombre: '');

    final dynamic fechaRaw = json['fecha_actualizacion'];
    DateTime? fechaActualizacion;
    if (fechaRaw is String && fechaRaw.isNotEmpty) {
      try {
        fechaActualizacion = DateTime.parse(fechaRaw);
      } on FormatException {
        fechaActualizacion = null;
      }
    }

    return Sucursal(
      codigoSucursal: json['codigo_sucursal'] as int? ?? 0,
      nombre: json['nombre'] as String? ?? '',
      direccion: json['direccion'] as String?,
      telefono: json['telefono'] as String?,
      horarioAtencion: json['horario_atencion'] as String?,
      isActive: json['is_active'] as bool? ?? false,
      ciudad: ciudad,
      empresaId: json['empresa_id'] as int? ?? 0,
      fechaActualizacion: fechaActualizacion,
    );
  }

  final int codigoSucursal;
  final String nombre;
  final String? direccion;
  final String? telefono;
  final String? horarioAtencion;
  final bool isActive;
  final Ciudad ciudad;
  final int empresaId;
  final DateTime? fechaActualizacion;
}

/// Service that talks to the Attention backend branches and cities endpoints.
///
/// Both /sucursales and /ciudades are public read-only endpoints exposed
/// without authentication, so no Authorization header is attached.
class SucursalesService {
  SucursalesService._();

  /// Fetches the list of active branches.
  ///
  /// Never throws. Always returns:
  /// - `{'success': true, 'sucursales': List<Sucursal>}` on success
  /// - `{'success': false, 'message': String}` on any failure.
  static Future<Map<String, dynamic>> listar() async {
    return _getList<Sucursal>(
      path: 'sucursales',
      itemsKey: 'sucursales',
      fromJson: Sucursal.fromJson,
    );
  }

  /// Fetches the list of cities available for branch lookup.
  ///
  /// The branches screen already embeds the city in each branch, so a
  /// failure here is non-fatal for the main list.
  ///
  /// Never throws. Always returns:
  /// - `{'success': true, 'ciudades': List<Ciudad>}` on success
  /// - `{'success': false, 'message': String}` on any failure.
  static Future<Map<String, dynamic>> listarCiudades() async {
    return _getList<Ciudad>(
      path: 'ciudades',
      itemsKey: 'ciudades',
      fromJson: Ciudad.fromJson,
    );
  }

  /// Shared GET helper that decodes the standard envelope and converts
  /// each item via [fromJson]. Returns the same success/failure map shape
  /// regardless of the item type, so both public endpoints stay
  /// consistent with the rest of the codebase.
  static Future<Map<String, dynamic>> _getList<T>({
    required String path,
    required String itemsKey,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    final String baseUrl = await ApiConfig.resolveBaseUrl();

    try {
      final response = await http
          .get(Uri.parse('$baseUrl/$path'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': 'Error del servidor (código ${response.statusCode})',
        };
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['data'] is! List) {
        return {'success': false, 'message': 'Respuesta del servidor inválida.'};
      }

      final items = (decoded['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map(fromJson)
          .toList();

      return {
        'success': true,
        itemsKey: items,
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
    } on http.ClientException {
      return {
        'success': false,
        'message': 'No se pudo conectar con el servidor. Verifica tu conexión.',
      };
    } on FormatException {
      return {'success': false, 'message': 'Respuesta del servidor inválida.'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Ocurrió un error inesperado. Intenta nuevamente.',
      };
    }
  }
}

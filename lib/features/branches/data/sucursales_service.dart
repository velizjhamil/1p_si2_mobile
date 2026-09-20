import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../../core/storage/secure_storage_service.dart';

/// City (Ciudad) as returned by the public /ciudades endpoint.
class Ciudad {
  const Ciudad({
    required this.id,
    required this.nombre,
    this.departamento,
  });

  /// Parses a Ciudad from a JSON object with a tolerant shape.
  factory Ciudad.fromJson(Map<String, dynamic> json) => Ciudad(
        id: (json['id'] as num?)?.toInt() ?? 0,
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
      codigoSucursal: (json['codigo_sucursal'] as num?)?.toInt() ?? 0,
      nombre: json['nombre'] as String? ?? '',
      direccion: json['direccion'] as String?,
      telefono: json['telefono'] as String?,
      horarioAtencion: json['horario_atencion'] as String?,
      isActive: json['is_active'] as bool? ?? false,
      ciudad: ciudad,
      empresaId: (json['empresa_id'] as num?)?.toInt() ?? 0,
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
class SucursalesService {
  SucursalesService._();

  /// Fetches the list of active branches.
  static Future<Map<String, dynamic>> listar() async {
    return _getList<Sucursal>(
      path: 'sucursales',
      itemsKey: 'sucursales',
      fromJson: Sucursal.fromJson,
    );
  }

  /// Fetches the list of cities available for branch lookup.
  static Future<Map<String, dynamic>> listarCiudades() async {
    return _getList<Ciudad>(
      path: 'ciudades',
      itemsKey: 'ciudades',
      fromJson: Ciudad.fromJson,
    );
  }

  static Future<Map<String, dynamic>> _getList<T>({
    required String path,
    required String itemsKey,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final String baseUrl = await ApiConfig.resolveBaseUrl();
      final String? token = await SecureStorageService.getToken();

      final headers = <String, String>{
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final response = await http
          .get(Uri.parse('$baseUrl/$path'), headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': 'Error del servidor (código ${response.statusCode})',
          itemsKey: <T>[],
        };
      }

      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic> || decoded['data'] is! List) {
        return {
          'success': false,
          'message': 'Respuesta del servidor inválida.',
          itemsKey: <T>[],
        };
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
        itemsKey: <T>[],
      };
    } on SocketException {
      return {
        'success': false,
        'message': 'No se pudo conectar con el servidor. Verifica tu conexión.',
        itemsKey: <T>[],
      };
    } on http.ClientException {
      return {
        'success': false,
        'message': 'No se pudo conectar con el servidor. Verifica tu conexión.',
        itemsKey: <T>[],
      };
    } on FormatException {
      return {
        'success': false,
        'message': 'Respuesta del servidor inválida.',
        itemsKey: <T>[],
      };
    } on TypeError {
      return {
        'success': false,
        'message': 'Error al procesar los datos de las sucursales.',
        itemsKey: <T>[],
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'Ocurrió un error inesperado. Intenta nuevamente.',
        itemsKey: <T>[],
      };
    }
  }
}

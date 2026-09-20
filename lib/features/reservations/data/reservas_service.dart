import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../../core/storage/secure_storage_service.dart';

class DetalleReservaItem {
  const DetalleReservaItem({
    required this.idDetalle,
    required this.idProducto,
    required this.nombre,
    required this.cantidad,
    required this.precioUnitario,
  });

  factory DetalleReservaItem.fromJson(Map<String, dynamic> json) =>
      DetalleReservaItem(
        idDetalle: (json['id_detalle'] as num?)?.toInt() ?? 0,
        idProducto: (json['id_producto'] as num?)?.toInt() ?? 0,
        nombre: json['nombre'] as String? ?? '',
        cantidad: (json['cantidad'] as num?)?.toInt() ?? 1,
        precioUnitario: (json['precio_unitario'] as num?)?.toDouble() ?? 0.0,
      );

  final int idDetalle;
  final int idProducto;
  final String nombre;
  final int cantidad;
  final double precioUnitario;
}

class ReservaItem {
  const ReservaItem({
    required this.idReserva,
    this.fechaReserva,
    this.fechaExpiracion,
    required this.estado,
    required this.totalEstimado,
    this.motivoCancelacion,
    this.productos = const [],
  });

  factory ReservaItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic raw) {
      if (raw is String && raw.isNotEmpty) {
        try {
          return DateTime.parse(raw);
        } catch (_) {}
      }
      return null;
    }

    final dynamic prods = json['productos'];
    final items = prods is List
        ? prods
            .whereType<Map<String, dynamic>>()
            .map(DetalleReservaItem.fromJson)
            .toList()
        : <DetalleReservaItem>[];

    return ReservaItem(
      idReserva: (json['id_reserva'] as num?)?.toInt() ?? 0,
      fechaReserva: parseDate(json['fecha_reserva']),
      fechaExpiracion: parseDate(json['fecha_expiracion']),
      estado: json['estado'] as String? ?? 'PENDIENTE',
      totalEstimado: (json['total_estimado'] as num?)?.toDouble() ?? 0.0,
      motivoCancelacion: json['motivo_cancelacion'] as String?,
      productos: items,
    );
  }

  final int idReserva;
  final DateTime? fechaReserva;
  final DateTime? fechaExpiracion;
  final String estado; // PENDIENTE | CONFIRMADA | CANCELADA | COMPLETADA
  final double totalEstimado;
  final String? motivoCancelacion;
  final List<DetalleReservaItem> productos;
}

/// Service that manages client reservations (CU14) with the backend.
class ReservasService {
  ReservasService._();

  static Future<Map<String, dynamic>> listar({String? estado}) async {
    try {
      final String baseUrl = await ApiConfig.resolveBaseUrl();
      final String? token = await SecureStorageService.getToken();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Debes iniciar sesión para consultar tus reservas.',
          'reservas': <ReservaItem>[],
        };
      }

      final queryParams = <String, String>{'limit': '50'};
      if (estado != null && estado.isNotEmpty && estado != 'TODAS') {
        queryParams['estado'] = estado;
      }

      final uri = Uri.parse('$baseUrl/reservas').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': 'Error al consultar reservas (código ${response.statusCode})',
          'reservas': <ReservaItem>[],
        };
      }

      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic> || decoded['data'] is! List) {
        return {
          'success': false,
          'message': 'Respuesta del servidor inválida.',
          'reservas': <ReservaItem>[],
        };
      }

      final items = (decoded['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map(ReservaItem.fromJson)
          .toList();

      return {
        'success': true,
        'reservas': items,
      };
    } on SocketException {
      return {
        'success': false,
        'message': 'Sin conexión con el servidor. Revisa tu conexión de red.',
        'reservas': <ReservaItem>[],
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'El servidor tardó demasiado en responder.',
        'reservas': <ReservaItem>[],
      };
    } on http.ClientException {
      return {
        'success': false,
        'message': 'Error de comunicación con el servidor. Verifica tu conexión.',
        'reservas': <ReservaItem>[],
      };
    } on FormatException {
      return {
        'success': false,
        'message': 'Formato de respuesta del servidor no reconocido.',
        'reservas': <ReservaItem>[],
      };
    } on TypeError {
      return {
        'success': false,
        'message': 'Error al procesar las reservas registradas.',
        'reservas': <ReservaItem>[],
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'Ocurrió un error inesperado al obtener reservas.',
        'reservas': <ReservaItem>[],
      };
    }
  }

  /// Creates a garment reservation holding stock atomically.
  static Future<Map<String, dynamic>> crear({
    required DateTime fechaExpiracion,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final String baseUrl = await ApiConfig.resolveBaseUrl();
      final String? token = await SecureStorageService.getToken();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Debes iniciar sesión para reservar prendas.',
        };
      }

      final formattedDate =
          "${fechaExpiracion.year.toString().padLeft(4, '0')}-${fechaExpiracion.month.toString().padLeft(2, '0')}-${fechaExpiracion.day.toString().padLeft(2, '0')}";

      final payload = {
        'fecha_expiracion': formattedDate,
        'items': items,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/reservas'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'reserva': decoded is Map<String, dynamic> ? decoded['data'] : null,
          'message': (decoded is Map<String, dynamic> ? decoded['message'] : null) as String? ??
              'Reserva registrada con éxito.',
        };
      }

      final errorMsg = decoded is Map<String, dynamic>
          ? (decoded['detail'] ?? decoded['message'] ?? 'Error al registrar la reserva.')
          : 'Error del servidor (código ${response.statusCode})';

      return {
        'success': false,
        'message': errorMsg.toString(),
      };
    } on SocketException {
      return {
        'success': false,
        'message': 'Sin conexión con el servidor al registrar reserva.',
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'El servidor tardó demasiado en responder.',
      };
    } on http.ClientException {
      return {
        'success': false,
        'message': 'Error de comunicación con el servidor. Verifica tu conexión.',
      };
    } on FormatException {
      return {
        'success': false,
        'message': 'Respuesta no válida del servidor al reservar.',
      };
    } on TypeError {
      return {
        'success': false,
        'message': 'Error de formato en la respuesta de la reserva.',
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'Ocurrió un error inesperado al crear la reserva.',
      };
    }
  }

  /// Cancels a pending reservation, returning stock to the catalog.
  static Future<Map<String, dynamic>> cancelar(
    int idReserva, {
    String motivo = 'Cancelada por el cliente desde la app móvil.',
  }) async {
    try {
      final String baseUrl = await ApiConfig.resolveBaseUrl();
      final String? token = await SecureStorageService.getToken();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Sesión no válida.',
        };
      }

      final response = await http
          .patch(
            Uri.parse('$baseUrl/reservas/$idReserva/estado'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'estado': 'CANCELADA',
              'motivo_cancelacion': motivo,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': (decoded is Map<String, dynamic> ? decoded['message'] : null) as String? ??
              'Reserva cancelada correctamente.',
        };
      }

      final errorMsg = decoded is Map<String, dynamic>
          ? (decoded['detail'] ?? decoded['message'] ?? 'No se pudo cancelar la reserva.')
          : 'Error del servidor.';

      return {
        'success': false,
        'message': errorMsg.toString(),
      };
    } on SocketException {
      return {
        'success': false,
        'message': 'Sin conexión con el servidor al cancelar.',
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Tiempo de espera agotado al cancelar la reserva.',
      };
    } on http.ClientException {
      return {
        'success': false,
        'message': 'Error de comunicación con el servidor al cancelar.',
      };
    } on FormatException {
      return {
        'success': false,
        'message': 'Respuesta del servidor inválida al cancelar.',
      };
    } on TypeError {
      return {
        'success': false,
        'message': 'Error al procesar la cancelación.',
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'Error al cancelar la reserva. Intente nuevamente.',
      };
    }
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../../core/storage/secure_storage_service.dart';

/// Modelo de ítem individual de una compra realizada por el cliente.
class CompraClienteItemModel {
  const CompraClienteItemModel({
    required this.idDetalle,
    required this.productoId,
    required this.nombre,
    this.talla,
    this.color,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  factory CompraClienteItemModel.fromJson(Map<String, dynamic> json) {
    return CompraClienteItemModel(
      idDetalle: json['id_detalle'] as int? ?? 0,
      productoId: json['producto_id'] as int? ?? 0,
      nombre: json['nombre'] as String? ?? 'Prenda',
      talla: json['talla'] as String?,
      color: json['color'] as String?,
      cantidad: json['cantidad'] as int? ?? 1,
      precioUnitario: (json['precio_unitario'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final int idDetalle;
  final int productoId;
  final String nombre;
  final String? talla;
  final String? color;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;
}

/// Datos de envío y facturación vinculados a la compra.
class CompraClienteEntregaModel {
  const CompraClienteEntregaModel({
    required this.nombreCliente,
    required this.correo,
    required this.telefono,
    required this.direccion,
    required this.ciudad,
    this.referencia,
  });

  factory CompraClienteEntregaModel.fromJson(Map<String, dynamic> json) {
    return CompraClienteEntregaModel(
      nombreCliente: json['nombre_cliente'] as String? ?? '',
      correo: json['correo'] as String? ?? '',
      telefono: json['telefono'] as String? ?? '',
      direccion: json['direccion'] as String? ?? '',
      ciudad: json['ciudad'] as String? ?? '',
      referencia: json['referencia'] as String?,
    );
  }

  final String nombreCliente;
  final String correo;
  final String telefono;
  final String direccion;
  final String ciudad;
  final String? referencia;
}

/// Modelo representativo de una compra de cliente en el historial (CU11 / CU13).
class CompraClienteModel {
  const CompraClienteModel({
    required this.idVenta,
    required this.codigo,
    this.fechaVenta,
    required this.total,
    required this.costoEnvio,
    required this.metodoPago,
    required this.estadoPago,
    this.comprobanteUrl,
    this.items = const [],
    this.datosEntrega,
  });

  factory CompraClienteModel.fromJson(Map<String, dynamic> json) {
    DateTime? fecha;
    final dynamic rawFecha = json['fecha_venta'];
    if (rawFecha is String && rawFecha.isNotEmpty) {
      try {
        fecha = DateTime.parse(rawFecha);
      } catch (_) {}
    }

    final dynamic rawItems = json['items'];
    final itemsList = rawItems is List
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map(CompraClienteItemModel.fromJson)
            .toList()
        : <CompraClienteItemModel>[];

    final dynamic rawEntrega = json['datos_entrega'];
    final entrega = rawEntrega is Map<String, dynamic>
        ? CompraClienteEntregaModel.fromJson(rawEntrega)
        : null;

    return CompraClienteModel(
      idVenta: json['id_venta'] as int? ?? 0,
      codigo: json['codigo'] as String? ?? 'ATT-000000',
      fechaVenta: fecha,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      costoEnvio: (json['costo_envio'] as num?)?.toDouble() ?? 0.0,
      metodoPago: json['metodo_pago'] as String? ?? 'QR',
      estadoPago: json['estado_pago'] as String? ?? 'PAGADO',
      comprobanteUrl: json['comprobante_url'] as String?,
      items: itemsList,
      datosEntrega: entrega,
    );
  }

  final int idVenta;
  final String codigo;
  final DateTime? fechaVenta;
  final double total;
  final double costoEnvio;
  final String metodoPago;
  final String estadoPago;
  final String? comprobanteUrl;
  final List<CompraClienteItemModel> items;
  final CompraClienteEntregaModel? datosEntrega;

  /// Retorna un texto amigable para la interfaz de usuario.
  String get estadoLegible {
    final estado = estadoPago.trim().toUpperCase();
    switch (estado) {
      case 'PAGADO':
      case 'COMPLETADA':
      case 'COMPLETADO':
        return 'Completada';
      case 'PENDIENTE':
        return 'Pendiente';
      case 'RECHAZADO':
      case 'CANCELADA':
      case 'CANCELADO':
        return 'Cancelada';
      default:
        return estadoPago;
    }
  }

  /// Retorna la cantidad acumulada de prendas de la compra.
  int get totalPrendas {
    if (items.isEmpty) return 0;
    return items.fold(0, (sum, item) => sum + item.cantidad);
  }

  /// Formato de fecha legible (DD/MM/YYYY o DD/MM/YYYY HH:mm).
  String get fechaFormateada {
    if (fechaVenta == null) return 'Reciente';
    final d = fechaVenta!.day.toString().padLeft(2, '0');
    final m = fechaVenta!.month.toString().padLeft(2, '0');
    final y = fechaVenta!.year.toString();
    final h = fechaVenta!.hour.toString().padLeft(2, '0');
    final min = fechaVenta!.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }

  bool get esCompletada {
    final est = estadoPago.trim().toUpperCase();
    return est == 'PAGADO' || est == 'COMPLETADA' || est == 'COMPLETADO';
  }

  bool get esPendiente {
    return estadoPago.trim().toUpperCase() == 'PENDIENTE';
  }

  bool get esCancelada {
    final est = estadoPago.trim().toUpperCase();
    return est == 'RECHAZADO' || est == 'CANCELADA' || est == 'CANCELADO';
  }
}

/// Servicio HTTP para el rol de Cliente (CU11 / CU13).
///
/// Consume los endpoints protegidos del backend para consultar el historial
/// de compras aisladas para el cliente autenticado.
class ComprasClienteService {
  ComprasClienteService._();

  /// Obtiene la lista paginada de compras del cliente autenticado.
  ///
  /// Consume `GET /api/v1/ventas` (o `GET /api/v1/ventas/mis-compras`).
  /// El backend filtra automáticamente por el `id_cliente` del JWT de rol `C`.
  static Future<Map<String, dynamic>> obtenerHistorialCompras({
    int page = 1,
    int limit = 50,
    String? estadoPago,
  }) async {
    final String baseUrl = await ApiConfig.resolveBaseUrl();
    final String? token = await SecureStorageService.getToken();

    if (token == null || token.isEmpty) {
      return {
        'success': false,
        'message': 'Debes iniciar sesión con tu cuenta para ver tus compras.',
      };
    }

    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (estadoPago != null && estadoPago.isNotEmpty && estadoPago != 'TODAS') {
      queryParams['estado_pago'] = estadoPago;
    }

    final uri = Uri.parse('$baseUrl/ventas').replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is! Map<String, dynamic> || decoded['data'] is! List) {
          return {
            'success': false,
            'message': 'Formato de respuesta del servidor no reconocido.',
            'compras': <CompraClienteModel>[],
            'total': 0,
            'pages': 1,
          };
        }

        final items = (decoded['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map(CompraClienteModel.fromJson)
            .toList();

        final total = (decoded['total'] as num?)?.toInt() ?? items.length;
        final pages = (decoded['pages'] as num?)?.toInt() ?? 1;

        return {
          'success': true,
          'compras': items,
          'total': total,
          'pages': pages,
        };
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        return {
          'success': false,
          'message': 'Tu sesión ha expirado o no tienes permisos. Inicia sesión nuevamente.',
          'compras': <CompraClienteModel>[],
          'total': 0,
          'pages': 1,
        };
      }

      return {
        'success': false,
        'message': 'Error al consultar historial de compras (código ${response.statusCode}).',
        'compras': <CompraClienteModel>[],
        'total': 0,
        'pages': 1,
      };
    } on SocketException {
      return {
        'success': false,
        'message': 'Sin conexión con el servidor. Revisa tu conexión a internet o red local.',
        'compras': <CompraClienteModel>[],
        'total': 0,
        'pages': 1,
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'El servidor tardó demasiado en responder. Intenta nuevamente.',
        'compras': <CompraClienteModel>[],
        'total': 0,
        'pages': 1,
      };
    } on http.ClientException {
      return {
        'success': false,
        'message': 'Error de comunicación con el servidor. Verifica tu conexión.',
        'compras': <CompraClienteModel>[],
        'total': 0,
        'pages': 1,
      };
    } on FormatException {
      return {
        'success': false,
        'message': 'Formato de respuesta del servidor no reconocido.',
        'compras': <CompraClienteModel>[],
        'total': 0,
        'pages': 1,
      };
    } on TypeError {
      return {
        'success': false,
        'message': 'Error al procesar el historial de compras.',
        'compras': <CompraClienteModel>[],
        'total': 0,
        'pages': 1,
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'Ocurrió un error inesperado al cargar tus compras.',
        'compras': <CompraClienteModel>[],
        'total': 0,
        'pages': 1,
      };
    }
  }

  /// Obtiene el detalle exhaustivo de una compra específica.
  ///
  /// Consume `GET /api/v1/ventas/{id_venta}`.
  static Future<Map<String, dynamic>> obtenerDetalleCompra(int idVenta) async {
    try {
      final String baseUrl = await ApiConfig.resolveBaseUrl();
      final String? token = await SecureStorageService.getToken();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Debes iniciar sesión para consultar el detalle de la compra.',
        };
      }

      final uri = Uri.parse('$baseUrl/ventas/$idVenta');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final dynamic data = decoded is Map<String, dynamic> ? decoded['data'] : null;

        if (data is Map<String, dynamic>) {
          return {
            'success': true,
            'compra': CompraClienteModel.fromJson(data),
          };
        }

        return {
          'success': false,
          'message': 'Detalle de compra no disponible en la respuesta.',
        };
      }

      if (response.statusCode == 403) {
        return {
          'success': false,
          'message': 'No tienes permisos para ver esta compra.',
        };
      }

      if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'La compra solicitada no existe.',
        };
      }

      return {
        'success': false,
        'message': 'Error al obtener el detalle de la compra (${response.statusCode}).',
      };
    } on SocketException {
      return {
        'success': false,
        'message': 'Sin conexión con el servidor al cargar el detalle.',
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Tiempo de espera agotado al consultar el detalle.',
      };
    } on http.ClientException {
      return {
        'success': false,
        'message': 'Error de comunicación con el servidor. Verifica tu conexión.',
      };
    } on FormatException {
      return {
        'success': false,
        'message': 'Formato de respuesta del servidor no válido.',
      };
    } on TypeError {
      return {
        'success': false,
        'message': 'Error al procesar la información del pedido.',
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'Ocurrió un error inesperado al consultar el detalle del pedido.',
      };
    }
  }
}

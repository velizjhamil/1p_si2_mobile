import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../cart/data/cart_item.dart';

/// Item in a processed order or purchase detail.
class VentaItemModel {
  const VentaItemModel({
    required this.idDetalle,
    required this.productoId,
    required this.nombre,
    this.talla,
    this.color,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  factory VentaItemModel.fromJson(Map<String, dynamic> json) => VentaItemModel(
        idDetalle: json['id_detalle'] as int? ?? 0,
        productoId: json['producto_id'] as int? ?? 0,
        nombre: json['nombre'] as String? ?? 'Prenda',
        talla: json['talla'] as String?,
        color: json['color'] as String?,
        cantidad: json['cantidad'] as int? ?? 1,
        precioUnitario: (json['precio_unitario'] as num?)?.toDouble() ?? 0.0,
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      );

  final int idDetalle;
  final int productoId;
  final String nombre;
  final String? talla;
  final String? color;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;
}

/// Delivery details associated with an order.
class DatosEntregaModel {
  const DatosEntregaModel({
    required this.nombreCliente,
    required this.correo,
    required this.telefono,
    required this.direccion,
    required this.ciudad,
    this.referencia,
  });

  factory DatosEntregaModel.fromJson(Map<String, dynamic> json) =>
      DatosEntregaModel(
        nombreCliente: json['nombre_cliente'] as String? ?? '',
        correo: json['correo'] as String? ?? '',
        telefono: json['telefono'] as String? ?? '',
        direccion: json['direccion'] as String? ?? '',
        ciudad: json['ciudad'] as String? ?? '',
        referencia: json['referencia'] as String?,
      );

  final String nombreCliente;
  final String correo;
  final String telefono;
  final String direccion;
  final String ciudad;
  final String? referencia;
}

/// Processed sale / purchase record.
class VentaModel {
  const VentaModel({
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

  factory VentaModel.fromJson(Map<String, dynamic> json) {
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
            .map(VentaItemModel.fromJson)
            .toList()
        : <VentaItemModel>[];

    final dynamic rawEntrega = json['datos_entrega'];
    final entrega = rawEntrega is Map<String, dynamic>
        ? DatosEntregaModel.fromJson(rawEntrega)
        : null;

    return VentaModel(
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
  final List<VentaItemModel> items;
  final DatosEntregaModel? datosEntrega;
}

/// Service handling Client checkout (CU21) and purchase history (CU13).
class CompraService {
  CompraService._();

  /// Submits the atomic checkout transaction to the backend.
  static Future<Map<String, dynamic>> procesarCheckout({
    required List<CartItem> items,
    required String metodoPago, // QR | EFECTIVO | TARJETA
    required String nombreCliente,
    required String correo,
    required String telefono,
    required String direccion,
    required String ciudad,
    String? referencia,
  }) async {
    final String baseUrl = await ApiConfig.resolveBaseUrl();
    final String? token = await SecureStorageService.getToken();

    if (token == null || token.isEmpty) {
      return {
        'success': false,
        'message': 'Debes iniciar sesión con tu cuenta de cliente.',
      };
    }

    final payload = {
      'items': items
          .map((i) => {
                'producto_id': i.idProducto,
                'cantidad': i.cantidad,
                'talla': i.talla,
                'color': i.color,
              })
          .toList(),
      'metodo_pago': metodoPago,
      'datos_entrega': {
        'nombre_cliente': nombreCliente,
        'correo': correo,
        'telefono': telefono,
        'direccion': direccion,
        'ciudad': ciudad,
        'referencia': referencia ?? '',
      },
      'tipo_venta': 'ONLINE',
    };

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/ventas/checkout'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));

      final dynamic decoded = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
        final venta = data is Map<String, dynamic> ? VentaModel.fromJson(data) : null;

        return {
          'success': true,
          'venta': venta,
          'message': decoded['message'] as String? ?? 'Compra procesada exitosamente.',
        };
      }

      final errorMsg = decoded is Map<String, dynamic>
          ? (decoded['detail'] ?? decoded['message'] ?? 'Error al procesar la compra.')
          : 'Error del servidor (${response.statusCode})';

      return {
        'success': false,
        'message': errorMsg.toString(),
      };
    } on SocketException {
      return {
        'success': false,
        'message': 'Sin conexión con el servidor. Revisa tu conexión Wi-Fi o USB.',
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'El servidor tardó demasiado en responder al checkout.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error inesperado durante la compra: $e',
      };
    }
  }

  /// Lists the client's past purchases (CU13).
  static Future<Map<String, dynamic>> listarMisCompras() async {
    final String baseUrl = await ApiConfig.resolveBaseUrl();
    final String? token = await SecureStorageService.getToken();

    if (token == null || token.isEmpty) {
      return {
        'success': false,
        'message': 'Debes iniciar sesión para consultar tus compras.',
      };
    }

    final uri = Uri.parse('$baseUrl/ventas?limit=50');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': 'Error al consultar historial de compras (código ${response.statusCode})',
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
          .map(VentaModel.fromJson)
          .toList();

      return {
        'success': true,
        'compras': items,
      };
    } on SocketException {
      return {
        'success': false,
        'message': 'Sin conexión con el servidor.',
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'El servidor tardó demasiado en responder.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al obtener historial de compras: $e',
      };
    }
  }
}

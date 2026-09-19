import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../../core/storage/secure_storage_service.dart';
import 'cart_item.dart';

/// Service that submits the checkout transaction to POST /api/v1/ventas/checkout.
class CheckoutService {
  CheckoutService._();

  static Future<Map<String, dynamic>> procesarCompra({
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
        'message': 'Debes iniciar sesión para completar la compra.',
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
        return {
          'success': true,
          'venta': data,
          'message': decoded['message'] as String? ?? 'Compra procesada exitosamente.',
        };
      }

      final errorMsg = decoded is Map<String, dynamic>
          ? (decoded['detail'] ?? decoded['message'] ?? 'Error al procesar la compra.')
          : 'Error del servidor (código ${response.statusCode})';

      return {
        'success': false,
        'message': errorMsg.toString(),
      };
    } on SocketException {
      return {
        'success': false,
        'message': 'Sin conexión con el servidor. Revisa tu red local.',
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'La operación tardó demasiado en responder.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error inesperado durante el checkout: $e',
      };
    }
  }
}

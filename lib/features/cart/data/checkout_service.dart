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
 try {
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

 final response = await http
 .post(
 Uri.parse('$baseUrl/ventas/checkout'),
 headers: {
 'Content-Type': 'application/json',
 'Accept': 'application/json',
 'Authorization': 'Bearer $token',
 },
 body: jsonEncode(payload),
 )
 .timeout(const Duration(seconds: 20));

 final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));

 if (response.statusCode == 200 || response.statusCode == 201) {
 final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
 return {
 'success': true,
 'venta': data,
 'message': (decoded is Map<String, dynamic> ? decoded['message'] : null) as String? ??
 'Compra procesada exitosamente.',
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
 'message': 'La operación tardó demasiado tiempo en responder.',
 };
 } on http.ClientException {
 return {
 'success': false,
 'message': 'Error de comunicación con el servidor. Verifica tu conexión.',
 };
 } on FormatException {
 return {
 'success': false,
 'message': 'Respuesta no válida del servidor durante el checkout.',
 };
 } on TypeError {
 return {
 'success': false,
 'message': 'Error de formato en la respuesta de la compra.',
 };
 } catch (_) {
 return {
 'success': false,
 'message': 'Ocurrió un error inesperado al procesar tu pedido.',
 };
 }
 }
}

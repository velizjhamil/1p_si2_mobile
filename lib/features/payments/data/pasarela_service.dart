import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../cart/data/cart_item.dart';
import 'payment_model.dart';

/// Service for handling payment gateway interactions.
class PasarelaService {
 PasarelaService._();

 /// Starts a payment transaction with the AttentionPay gateway.
 static Future<Map<String, dynamic>> iniciarPago({
 required List<CartItem> items,
 required String metodoPago, // QR | TARJETA | EFECTIVO
 required String nombreCliente,
 required String correo,
 required String telefono,
 required String direccion,
 required String ciudad,
 String? referencia,
 DatosTarjetaModel? datosTarjeta,
 int? idSucursal,
 String? tipoEntrega,
 }) async {
 try {
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
 'tipo_entrega': tipoEntrega ?? 'DOMICILIO',
 if (datosTarjeta != null) 'datos_tarjeta': datosTarjeta.toJson(),
 'id_sucursal': ?idSucursal,
 };

 final response = await http
 .post(
 Uri.parse('$baseUrl/pagos/procesar'),
 headers: {
 'Content-Type': 'application/json',
 'Accept': 'application/json',
 'Authorization': 'Bearer $token',
 },
 body: jsonEncode(payload),
 )
 .timeout(const Duration(seconds: 25));

 final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));

 if (response.statusCode == 200 || response.statusCode == 201) {
 final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
 if (data is Map<String, dynamic>) {
 final transaccionData = data['transaccion'];
 final transaccion = transaccionData is Map<String, dynamic>
 ? TransaccionPagoModel.fromJson(transaccionData)
 : null;

 return {
 'success': true,
 'id_venta': data['id_venta'],
 'codigo_venta': data['codigo_venta'],
 'total': (data['total'] as num?)?.toDouble() ?? 0.0,
 'costo_envio': (data['costo_envio'] as num?)?.toDouble() ?? 0.0,
 'estado_pago': data['estado_pago'] as String? ?? 'PENDIENTE',
 'transaccion': transaccion,
 'message': decoded['message'] ?? 'Transacción de pago iniciada exitosamente.',
 };
 }
 }

 final errorMsg = decoded is Map<String, dynamic>
 ? (decoded['detail'] ?? decoded['message'] ?? 'Error al procesar el pago.')
 : 'Error del servidor (${response.statusCode})';

 return {
 'success': false,
 'message': errorMsg.toString(),
 };
 } on SocketException {
 return {
 'success': false,
 'message': 'Sin conexión con el servidor. Revisa tu conexión Wi-Fi o red móvil.',
 };
 } on TimeoutException {
 return {
 'success': false,
 'message': 'El servidor de la pasarela tardó demasiado en responder.',
 };
 } on http.ClientException {
 return {
 'success': false,
 'message': 'Error de comunicación con la pasarela. Verifica tu conexión.',
 };
 } on FormatException {
 return {
 'success': false,
 'message': 'Respuesta no válida del servidor de pagos.',
 };
 } on TypeError {
 return {
 'success': false,
 'message': 'Error al procesar la respuesta de la transacción.',
 };
 } catch (e) {
 return {
 'success': false,
 'message': 'Error inesperado durante el pago: $e',
 };
 }
 }

 /// Polls or queries the live transaction status from the gateway.
 static Future<Map<String, dynamic>> consultarEstado(String codigoTransaccion) async {
 try {
 final String baseUrl = await ApiConfig.resolveBaseUrl();
 final String? token = await SecureStorageService.getToken();

 final response = await http.get(
 Uri.parse('$baseUrl/pagos/estado/$codigoTransaccion'),
 headers: {
 'Accept': 'application/json',
 if (token != null) 'Authorization': 'Bearer $token',
 },
 ).timeout(const Duration(seconds: 15));

 final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));

 if (response.statusCode == 200) {
 final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
 if (data is Map<String, dynamic>) {
 return {
 'success': true,
 'transaccion': TransaccionPagoModel.fromJson(data),
 };
 }
 }

 return {
 'success': false,
 'message': decoded is Map<String, dynamic>
 ? (decoded['detail'] ?? 'No se pudo obtener el estado de la transacción.')
 : 'Error del servidor (${response.statusCode})',
 };
 } on SocketException {
 return {'success': false, 'message': 'Sin conexión al verificar estado.'};
 } on TimeoutException {
 return {'success': false, 'message': 'Tiempo de espera agotado al consultar estado.'};
 } catch (e) {
 return {'success': false, 'message': 'Error al consultar estado: $e'};
 }
 }

 /// Simulates a bank / gateway webhook confirmation (for testing/demo purposes).
 static Future<Map<String, dynamic>> simularConfirmacion({
 required String codigoTransaccion,
 bool aprobar = true,
 String? motivo,
 }) async {
 try {
 final String baseUrl = await ApiConfig.resolveBaseUrl();
 final String? token = await SecureStorageService.getToken();

 final payload = {
 'codigo_transaccion': codigoTransaccion,
 'aprobar': aprobar,
 'motivo': ?motivo,
 };

 final response = await http
 .post(
 Uri.parse('$baseUrl/pagos/simular-confirmacion'),
 headers: {
 'Content-Type': 'application/json',
 'Accept': 'application/json',
 if (token != null) 'Authorization': 'Bearer $token',
 },
 body: jsonEncode(payload),
 )
 .timeout(const Duration(seconds: 20));

 final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));

 if (response.statusCode == 200) {
 final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
 return {
 'success': true,
 'estado': data is Map<String, dynamic> ? data['estado'] : (aprobar ? 'PAGADO' : 'RECHAZADO'),
 'message': decoded['message'] ?? 'Confirmación simulada exitosamente.',
 };
 }

 return {
 'success': false,
 'message': decoded is Map<String, dynamic>
 ? (decoded['detail'] ?? 'Error al simular confirmación.')
 : 'Error del servidor (${response.statusCode})',
 };
 } on SocketException {
 return {'success': false, 'message': 'Sin conexión al simular confirmación.'};
 } on TimeoutException {
 return {'success': false, 'message': 'Tiempo agotado al simular webhook.'};
 } catch (e) {
 return {'success': false, 'message': 'Error al simular: $e'};
 }
 }
}

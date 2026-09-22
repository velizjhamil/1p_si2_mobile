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
    this.idSucursal,
    this.sucursalNombre,
    this.tipoEntrega = 'RETIRO',
    this.direccionEntrega,
    this.telefonoEntrega,
    this.fechaReserva,
    this.fechaExpiracion,
    this.fechaConfirmacion,
    this.fechaExpiracionDt,
    required this.estado,
    required this.totalEstimado,
    this.montoAnticipo = 0.0,
    this.montoAnticipoPagado = 0.0,
    this.montoReembolsado = 0.0,
    this.montoPenalizacion = 0.0,
    this.metodoPagoAnticipo,
    this.codigoTransaccionAnticipo,
    this.motivoCancelacion,
    this.minutosRestantes,
    this.esExpirada = false,
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

    final total = (json['total_estimado'] as num?)?.toDouble() ?? 0.0;
    final anticipo = (json['monto_anticipo'] as num?)?.toDouble() ?? 0.0;

    return ReservaItem(
      idReserva: (json['id_reserva'] as num?)?.toInt() ?? 0,
      idSucursal: (json['id_sucursal'] as num?)?.toInt(),
      sucursalNombre: json['sucursal_nombre'] as String?,
      tipoEntrega: json['tipo_entrega'] as String? ?? 'RETIRO',
      direccionEntrega: json['direccion_entrega'] as String?,
      telefonoEntrega: json['telefono_entrega'] as String?,
      fechaReserva: parseDate(json['fecha_reserva']),
      fechaExpiracion: parseDate(json['fecha_expiracion']),
      fechaConfirmacion: parseDate(json['fecha_confirmacion']),
      fechaExpiracionDt: parseDate(json['fecha_expiracion_dt']),
      estado: json['estado'] as String? ?? 'CONFIRMADA',
      totalEstimado: total,
      montoAnticipo: anticipo,
      montoAnticipoPagado: (json['monto_anticipo_pagado'] as num?)?.toDouble() ?? 0.0,
      montoReembolsado: (json['monto_reembolsado'] as num?)?.toDouble() ?? 0.0,
      montoPenalizacion: (json['monto_penalizacion'] as num?)?.toDouble() ?? 0.0,
      metodoPagoAnticipo: json['metodo_pago_anticipo'] as String?,
      codigoTransaccionAnticipo: json['codigo_transaccion_anticipo'] as String?,
      motivoCancelacion: json['motivo_cancelacion'] as String?,
      minutosRestantes: (json['minutos_restantes'] as num?)?.toInt(),
      esExpirada: json['es_expirada'] as bool? ?? false,
      productos: items,
    );
  }

  final int idReserva;
  final int? idSucursal;
  final String? sucursalNombre;
  final String tipoEntrega; // RETIRO | DOMICILIO
  final String? direccionEntrega;
  final String? telefonoEntrega;
  final DateTime? fechaReserva;
  final DateTime? fechaExpiracion;
  final DateTime? fechaConfirmacion;
  final DateTime? fechaExpiracionDt;
  final String estado; // PENDIENTE | CONFIRMADA | CANCELADA | COMPLETADA
  final double totalEstimado;
  final double montoAnticipo;
  final double montoAnticipoPagado;
  final double montoReembolsado;
  final double montoPenalizacion;
  final String? metodoPagoAnticipo;
  final String? codigoTransaccionAnticipo;
  final String? motivoCancelacion;
  final int? minutosRestantes;
  final bool esExpirada;
  final List<DetalleReservaItem> productos;

  bool get esPendiente => estado.toUpperCase() == 'PENDIENTE';
  bool get esConfirmada => estado.toUpperCase() == 'CONFIRMADA';
  bool get esCancelada => estado.toUpperCase() == 'CANCELADA';
  bool get esCompletada => estado.toUpperCase() == 'COMPLETADA';

  bool get esRetiroEnTienda => tipoEntrega.toUpperCase() == 'RETIRO';
  bool get esEnvioDomicilio => tipoEntrega.toUpperCase() == 'DOMICILIO';

  double get saldoPendiente => (totalEstimado - montoAnticipoPagado).clamp(0.0, double.infinity);

  /// Retorna un texto descriptivo del tiempo restante de las 48 horas.
  String get tiempoRestanteTexto {
    if (esExpirada) return 'Expirada';
    if (minutosRestantes != null) {
      if (minutosRestantes! <= 0) return 'Expirada';
      if (minutosRestantes! < 60) return '$minutosRestantes min restantes';
      final horas = minutosRestantes! ~/ 60;
      final mins = minutosRestantes! % 60;
      if (horas < 24) return '${horas}h ${mins > 0 ? "${mins}m " : ""}restantes';
      final dias = horas ~/ 24;
      final horasRestantes = horas % 24;
      return '${dias}d ${horasRestantes}h restantes';
    }
    return '48 horas de validez';
  }
}

/// Service that manages client reservations with the backend.
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

  /// Creates a garment reservation holding stock atomically with cash payment confirmation.
  static Future<Map<String, dynamic>> crear({
    required DateTime fechaExpiracion,
    required List<Map<String, dynamic>> items,
    int? idSucursal,
    String tipoEntrega = 'RETIRO',
    String? direccionEntrega,
    String? telefonoEntrega,
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
        'tipo_entrega': tipoEntrega,
        if (idSucursal != null && idSucursal > 0) 'id_sucursal': idSucursal,
        if (direccionEntrega != null && direccionEntrega.trim().isNotEmpty)
          'direccion_entrega': direccionEntrega.trim(),
        if (telefonoEntrega != null && telefonoEntrega.trim().isNotEmpty)
          'telefono_entrega': telefonoEntrega.trim(),
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

  /// Procesa el pago del anticipo del 50% para confirmar la reserva y activar las 48 horas.
  static Future<Map<String, dynamic>> pagarAnticipo({
    required int idReserva,
    required String metodoPago, // QR | TARJETA
    String? referenciaPago,
  }) async {
    try {
      final String baseUrl = await ApiConfig.resolveBaseUrl();
      final String? token = await SecureStorageService.getToken();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Sesión no válida. Inicia sesión para confirmar tu anticipo.',
        };
      }

      final payload = {
        'metodo_pago': metodoPago,
        if (referenciaPago != null && referenciaPago.isNotEmpty)
          'referencia_pago': referenciaPago,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/reservas/$idReserva/pagar-anticipo'),
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
          'reserva': decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>
              ? ReservaItem.fromJson(decoded['data'] as Map<String, dynamic>)
              : null,
          'message': (decoded is Map<String, dynamic> ? decoded['message'] : null) as String? ??
              'Anticipo del 50% registrado correctamente. ¡Reserva CONFIRMADA!',
        };
      }

      final errorMsg = decoded is Map<String, dynamic>
          ? (decoded['detail'] ?? decoded['message'] ?? 'Error al procesar el anticipo.')
          : 'Error del servidor (código ${response.statusCode})';

      return {
        'success': false,
        'message': errorMsg.toString(),
      };
    } on SocketException {
      return {
        'success': false,
        'message': 'Sin conexión con el servidor al registrar anticipo.',
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'El servidor tardó demasiado en responder al procesar el anticipo.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error inesperado al pagar anticipo: $e',
      };
    }
  }
}

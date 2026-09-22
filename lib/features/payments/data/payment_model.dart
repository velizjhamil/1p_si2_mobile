/// Models for payment gateway transactions and card payloads.
class TransaccionPagoModel {
 const TransaccionPagoModel({
 required this.idTransaccion,
 required this.codigoTransaccion,
 required this.pasarela,
 required this.monto,
 required this.moneda,
 required this.metodoPago,
 required this.estado,
 this.qrData,
 this.detallesPago,
 this.fechaCreacion,
 this.fechaActualizacion,
 this.idVenta,
 this.codigoVenta,
 this.estadoVenta,
 });

 factory TransaccionPagoModel.fromJson(Map<String, dynamic> json) {
 DateTime? parseDate(dynamic d) {
 if (d is String && d.isNotEmpty) {
 try {
 return DateTime.parse(d);
 } catch (_) {}
 }
 return null;
 }

 return TransaccionPagoModel(
 idTransaccion: (json['id_transaccion'] as num?)?.toInt() ?? 0,
 codigoTransaccion: json['codigo_transaccion'] as String? ?? '',
 pasarela: json['pasarela'] as String? ?? 'AttentionPay',
 monto: (json['monto'] as num?)?.toDouble() ?? 0.0,
 moneda: json['moneda'] as String? ?? 'BOB',
 metodoPago: json['metodo_pago'] as String? ?? 'QR',
 estado: json['estado'] as String? ?? 'PENDIENTE',
 qrData: json['qr_data'] as String?,
 detallesPago: json['detalles_pago'] as String?,
 fechaCreacion: parseDate(json['fecha_creacion']),
 fechaActualizacion: parseDate(json['fecha_actualizacion']),
 idVenta: (json['id_venta'] as num?)?.toInt(),
 codigoVenta: json['codigo_venta'] as String?,
 estadoVenta: json['estado_venta'] as String?,
 );
 }

 final int idTransaccion;
 final String codigoTransaccion;
 final String pasarela;
 final double monto;
 final String moneda;
 final String metodoPago;
 final String estado;
 final String? qrData;
 final String? detallesPago;
 final DateTime? fechaCreacion;
 final DateTime? fechaActualizacion;
 final int? idVenta;
 final String? codigoVenta;
 final String? estadoVenta;

 bool get isPagado => estado == 'PAGADO';
 bool get isRechazado => estado == 'RECHAZADO';
 bool get isPendiente => estado == 'PENDIENTE';
}

/// Card information for secure transaction submission.
class DatosTarjetaModel {
 const DatosTarjetaModel({
 required this.titular,
 required this.numeroTarjeta,
 required this.expiracion,
 required this.cvv,
 });

 final String titular;
 final String numeroTarjeta;
 final String expiracion;
 final String cvv;

 Map<String, dynamic> toJson() => {
 'titular': titular,
 'numero_tarjeta': numeroTarjeta.replaceAll(' ', ''),
 'expiracion': expiracion,
 'cvv': cvv,
 };
}

import 'package:flutter/material.dart';

/// Modelo de datos para las Notificaciones in-app.
class NotificacionModel {
 const NotificacionModel({
 required this.idNotificacion,
 this.idUsuario,
 required this.titulo,
 required this.mensaje,
 this.tipo = 'INFO',
 this.leida = false,
 this.fechaCreacion,
 this.referenciaTipo,
 this.referenciaId,
 });

 factory NotificacionModel.fromJson(Map<String, dynamic> json) {
 DateTime? parseDate(dynamic raw) {
 if (raw is String && raw.isNotEmpty) {
 try {
 return DateTime.parse(raw);
 } catch (_) {}
 }
 return null;
 }

 return NotificacionModel(
 idNotificacion: (json['id_notificacion'] as num?)?.toInt() ?? 0,
 idUsuario: json['id_usuario']?.toString(),
 titulo: json['titulo'] as String? ?? 'Aviso',
 mensaje: json['mensaje'] as String? ?? '',
 tipo: (json['tipo'] as String? ?? 'INFO').toUpperCase(),
 leida: json['leida'] as bool? ?? false,
 fechaCreacion: parseDate(json['fecha_creacion']),
 referenciaTipo: json['referencia_tipo'] as String?,
 referenciaId: json['referencia_id']?.toString(),
 );
 }

 final int idNotificacion;
 final String? idUsuario;
 final String titulo;
 final String mensaje;
 final String tipo;
 final bool leida;
 final DateTime? fechaCreacion;
 final String? referenciaTipo;
 final String? referenciaId;

 NotificacionModel copyWith({
 bool? leida,
 }) {
 return NotificacionModel(
 idNotificacion: idNotificacion,
 idUsuario: idUsuario,
 titulo: titulo,
 mensaje: mensaje,
 tipo: tipo,
 leida: leida ?? this.leida,
 fechaCreacion: fechaCreacion,
 referenciaTipo: referenciaTipo,
 referenciaId: referenciaId,
 );
 }

 /// Nombre amigable del tipo en español neutro.
 String get tipoLegible {
 switch (tipo) {
 case 'RESERVA':
 return 'Reserva';
 case 'PEDIDO':
 case 'VENTA':
 return 'Pedido';
 case 'PROMO':
 case 'DESCUENTO':
 return 'Promoción';
 case 'STOCK':
 return 'Inventario';
 case 'DEVOLUCION':
 return 'Devolución';
 case 'SISTEMA':
 return 'Sistema';
 default:
 return 'Aviso';
 }
 }

 /// Ícono representativo según la categoría de la notificación.
 IconData get iconoPorTipo {
 switch (tipo) {
 case 'RESERVA':
 return Icons.bookmark_added_rounded;
 case 'PEDIDO':
 case 'VENTA':
 return Icons.shopping_bag_rounded;
 case 'PROMO':
 case 'DESCUENTO':
 return Icons.local_offer_rounded;
 case 'STOCK':
 return Icons.inventory_2_rounded;
 case 'DEVOLUCION':
 return Icons.assignment_return_rounded;
 case 'SISTEMA':
 return Icons.shield_rounded;
 default:
 return Icons.notifications_rounded;
 }
 }

 /// Color semántico asignado a la categoría.
 Color get colorPorTipo {
 switch (tipo) {
 case 'RESERVA':
 return Colors.blue.shade700;
 case 'PEDIDO':
 case 'VENTA':
 return Colors.teal.shade700;
 case 'PROMO':
 case 'DESCUENTO':
 return Colors.amber.shade900;
 case 'STOCK':
 return Colors.deepOrange.shade700;
 case 'DEVOLUCION':
 return Colors.indigo.shade700;
 case 'SISTEMA':
 return Colors.purple.shade700;
 default:
 return Colors.blueGrey.shade700;
 }
 }

 /// Formato de fecha completo legible (ej. "20/09/2026 14:30").
 String get fechaFormateada {
 if (fechaCreacion == null) return 'Fecha no disponible';
 final d = fechaCreacion!.day.toString().padLeft(2, '0');
 final m = fechaCreacion!.month.toString().padLeft(2, '0');
 final y = fechaCreacion!.year.toString();
 final h = fechaCreacion!.hour.toString().padLeft(2, '0');
 final min = fechaCreacion!.minute.toString().padLeft(2, '0');
 return '$d/$m/$y $h:$min';
 }

 /// Formato de tiempo relativo estilo bandeja de entrada.
 String get tiempoRelativo {
 if (fechaCreacion == null) return '';
 final ahora = DateTime.now();
 final diferencia = ahora.difference(fechaCreacion!);

 if (diferencia.isNegative || diferencia.inSeconds < 60) {
 return 'Ahora mismo';
 } else if (diferencia.inMinutes < 60) {
 return 'Hace ${diferencia.inMinutes} min';
 } else if (diferencia.inHours < 24) {
 return 'Hace ${diferencia.inHours} h';
 } else if (diferencia.inDays == 1) {
 return 'Ayer';
 } else if (diferencia.inDays < 7) {
 return 'Hace ${diferencia.inDays} días';
 } else {
 final d = fechaCreacion!.day.toString().padLeft(2, '0');
 final m = fechaCreacion!.month.toString().padLeft(2, '0');
 final y = fechaCreacion!.year.toString();
 return '$d/$m/$y';
 }
 }
}

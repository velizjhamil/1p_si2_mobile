import 'package:flutter/material.dart';

/// Modelo de un hito o paso en la trazabilidad del envío.
class HitoSeguimientoModel {
  const HitoSeguimientoModel({
    required this.etapa,
    required this.titulo,
    required this.descripcion,
    this.fecha,
    this.completado = false,
    this.enCurso = false,
  });

  factory HitoSeguimientoModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic raw) {
      if (raw is String && raw.isNotEmpty) {
        try {
          return DateTime.parse(raw);
        } catch (_) {}
      }
      return null;
    }

    return HitoSeguimientoModel(
      etapa: json['etapa'] as String? ?? '',
      titulo: json['titulo'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      fecha: parseDate(json['fecha']),
      completado: json['completado'] as bool? ?? false,
      enCurso: json['en_curso'] as bool? ?? false,
    );
  }

  final String etapa;
  final String titulo;
  final String descripcion;
  final DateTime? fecha;
  final bool completado;
  final bool enCurso;

  String get fechaFormateada {
    if (fecha == null) return '';
    final d = fecha!.day.toString().padLeft(2, '0');
    final m = fecha!.month.toString().padLeft(2, '0');
    final y = fecha!.year.toString();
    final h = fecha!.hour.toString().padLeft(2, '0');
    final min = fecha!.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }
}

/// Modelo completo de seguimiento y estado de envío (CU18).
class EnvioTrackingModel {
  const EnvioTrackingModel({
    required this.codigoRastreo,
    required this.idVenta,
    required this.codigoVenta,
    required this.estadoEnvio,
    required this.estadoLegible,
    this.fechaEstimadaEntrega,
    this.fechaVenta,
    required this.direccionEntrega,
    required this.ciudad,
    required this.destinatario,
    required this.telefono,
    this.referencia,
    this.costoEnvio = 0.0,
    this.totalVenta = 0.0,
    this.totalPrendas = 0,
    this.repartidorNombre,
    this.repartidorTelefono,
    this.repartidorVehiculo,
    this.agencia,
    this.hitos = const [],
  });

  factory EnvioTrackingModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic raw) {
      if (raw is String && raw.isNotEmpty) {
        try {
          return DateTime.parse(raw);
        } catch (_) {}
      }
      return null;
    }

    final rawHitos = json['hitos'];
    final List<HitoSeguimientoModel> hitosParsed = [];
    if (rawHitos is List) {
      for (final h in rawHitos) {
        if (h is Map<String, dynamic>) {
          hitosParsed.add(HitoSeguimientoModel.fromJson(h));
        }
      }
    }

    return EnvioTrackingModel(
      codigoRastreo: json['codigo_rastreo'] as String? ?? '',
      idVenta: (json['id_venta'] as num?)?.toInt() ?? 0,
      codigoVenta: json['codigo_venta'] as String? ?? '',
      estadoEnvio: (json['estado_envio'] as String? ?? 'PREPARANDO').toUpperCase(),
      estadoLegible: json['estado_legible'] as String? ?? 'En proceso',
      fechaEstimadaEntrega: parseDate(json['fecha_estimada_entrega']),
      fechaVenta: parseDate(json['fecha_venta']),
      direccionEntrega: json['direccion_entrega'] as String? ?? 'Dirección no especificada',
      ciudad: json['ciudad'] as String? ?? 'Santa Cruz',
      destinatario: json['destinatario'] as String? ?? '',
      telefono: json['telefono'] as String? ?? '',
      referencia: json['referencia'] as String?,
      costoEnvio: (json['costo_envio'] as num?)?.toDouble() ?? 0.0,
      totalVenta: (json['total_venta'] as num?)?.toDouble() ?? 0.0,
      totalPrendas: (json['total_prendas'] as num?)?.toInt() ?? 1,
      repartidorNombre: json['repartidor_nombre'] as String?,
      repartidorTelefono: json['repartidor_telefono'] as String?,
      repartidorVehiculo: json['repartidor_vehiculo'] as String?,
      agencia: json['agencia'] as String? ?? 'Attention Delivery Express',
      hitos: hitosParsed,
    );
  }

  final String codigoRastreo;
  final int idVenta;
  final String codigoVenta;
  final String estadoEnvio; // PREPARANDO | EN_CAMINO | ENTREGADO | PENDIENTE_PAGO | CANCELADO
  final String estadoLegible;
  final DateTime? fechaEstimadaEntrega;
  final DateTime? fechaVenta;
  final String direccionEntrega;
  final String ciudad;
  final String destinatario;
  final String telefono;
  final String? referencia;
  final double costoEnvio;
  final double totalVenta;
  final int totalPrendas;
  final String? repartidorNombre;
  final String? repartidorTelefono;
  final String? repartidorVehiculo;
  final String? agencia;
  final List<HitoSeguimientoModel> hitos;

  /// Índice numérico para el stepper visual (0: Orden, 1: Preparando, 2: En camino, 3: Entregado).
  int get etapaIndex {
    switch (estadoEnvio) {
      case 'ENTREGADO':
        return 3;
      case 'EN_CAMINO':
        return 2;
      case 'PREPARANDO':
        return 1;
      case 'PENDIENTE_PAGO':
      default:
        return 0;
    }
  }

  bool get esEntregado => estadoEnvio == 'ENTREGADO';
  bool get esEnCamino => estadoEnvio == 'EN_CAMINO';
  bool get esPreparando => estadoEnvio == 'PREPARANDO';

  Color get colorEstado {
    switch (estadoEnvio) {
      case 'ENTREGADO':
        return Colors.green.shade700;
      case 'EN_CAMINO':
        return Colors.teal.shade700;
      case 'PREPARANDO':
        return Colors.amber.shade900;
      case 'PENDIENTE_PAGO':
        return Colors.orange.shade800;
      case 'CANCELADO':
        return Colors.red.shade700;
      default:
        return Colors.blueGrey;
    }
  }

  IconData get iconoEstado {
    switch (estadoEnvio) {
      case 'ENTREGADO':
        return Icons.check_circle_rounded;
      case 'EN_CAMINO':
        return Icons.delivery_dining_rounded;
      case 'PREPARANDO':
        return Icons.inventory_2_rounded;
      case 'PENDIENTE_PAGO':
        return Icons.pending_actions_rounded;
      default:
        return Icons.local_shipping_rounded;
    }
  }

  String get fechaEstimadaFormateada {
    if (fechaEstimadaEntrega == null) return 'Por confirmar';
    final d = fechaEstimadaEntrega!.day.toString().padLeft(2, '0');
    final m = fechaEstimadaEntrega!.month.toString().padLeft(2, '0');
    final y = fechaEstimadaEntrega!.year.toString();
    final h = fechaEstimadaEntrega!.hour.toString().padLeft(2, '0');
    final min = fechaEstimadaEntrega!.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }
}

/// Modelo de datos para Descuentos y Cupones Promocionales (CU12).
class DescuentoModel {
  const DescuentoModel({
    required this.idDescuento,
    this.codigo,
    required this.nombre,
    this.descripcion,
    required this.tipo,
    required this.valor,
    this.fechaInicio,
    this.fechaFin,
    this.activo = true,
    this.usosMaximos,
    this.usosActuales = 0,
    this.montoMinimoCompra,
  });

  factory DescuentoModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic raw) {
      if (raw is String && raw.isNotEmpty) {
        try {
          return DateTime.parse(raw);
        } catch (_) {}
      }
      return null;
    }

    return DescuentoModel(
      idDescuento: json['id_descuento'] as int? ?? 0,
      codigo: json['codigo'] as String?,
      nombre: json['nombre'] as String? ?? 'Promoción Especial',
      descripcion: json['descripcion'] as String?,
      tipo: json['tipo'] as String? ?? 'PORCENTAJE',
      valor: (json['valor'] as num?)?.toDouble() ?? 0.0,
      fechaInicio: parseDate(json['fecha_inicio']),
      fechaFin: parseDate(json['fecha_fin']),
      activo: json['activo'] as bool? ?? true,
      usosMaximos: json['usos_maximos'] as int?,
      usosActuales: json['usos_actuales'] as int? ?? 0,
      montoMinimoCompra: (json['monto_minimo_compra'] as num?)?.toDouble(),
    );
  }

  final int idDescuento;
  final String? codigo;
  final String nombre;
  final String? descripcion;
  final String tipo; // PORCENTAJE | MONTO_FIJO
  final double valor;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final bool activo;
  final int? usosMaximos;
  final int usosActuales;
  final double? montoMinimoCompra;

  /// Retorna si el tipo de descuento se calcula en porcentaje.
  bool get esPorcentaje => tipo.toUpperCase() == 'PORCENTAJE';

  /// Retorna si el tipo de descuento es de monto fijo (ej. Bs 50).
  bool get esMontoFijo => !esPorcentaje;

  /// Indica si el descuento requiere aplicar un cupón con código.
  bool get tieneCodigo => codigo != null && codigo!.trim().isNotEmpty;

  /// Texto destacado del beneficio (ej. "25% OFF" o "Bs 50 OFF").
  String get badgeTexto {
    if (esPorcentaje) {
      final porcentaje = valor % 1 == 0 ? valor.toInt().toString() : valor.toStringAsFixed(1);
      return '$porcentaje% OFF';
    } else {
      final monto = valor % 1 == 0 ? valor.toInt().toString() : valor.toStringAsFixed(2);
      return 'Bs $monto OFF';
    }
  }

  /// Valor formateado con signo (ej. "-25%" o "-Bs 50.00").
  String get valorFormateado {
    if (esPorcentaje) {
      final porcentaje = valor % 1 == 0 ? valor.toInt().toString() : valor.toStringAsFixed(1);
      return '-$porcentaje%';
    } else {
      return '-Bs ${valor.toStringAsFixed(2)}';
    }
  }

  /// Días restantes de validez hasta la fecha de expiración.
  int? get diasRestantes {
    if (fechaFin == null) return null;
    final hoy = DateTime.now();
    final fin = DateTime(fechaFin!.year, fechaFin!.month, fechaFin!.day, 23, 59, 59);
    final diff = fin.difference(hoy).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Indica si la oferta expira en 3 días o menos.
  bool get estaPorVencer {
    final dias = diasRestantes;
    return dias != null && dias <= 3 && dias >= 0;
  }

  /// Texto amigable de validez de la oferta.
  String get vigenciaTexto {
    if (fechaFin == null) return 'Por tiempo limitado';
    final d = fechaFin!.day.toString().padLeft(2, '0');
    final m = fechaFin!.month.toString().padLeft(2, '0');
    final y = fechaFin!.year.toString();
    return 'Válido hasta el $d/$m/$y';
  }

  /// Descripción de condición de compra mínima si aplica.
  String? get condicionCompraMinima {
    if (montoMinimoCompra != null && montoMinimoCompra! > 0) {
      return 'Compra mínima: Bs ${montoMinimoCompra!.toStringAsFixed(2)}';
    }
    return null;
  }
}

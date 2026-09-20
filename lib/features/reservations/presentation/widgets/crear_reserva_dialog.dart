import 'package:flutter/material.dart';

import '../../data/reservas_service.dart';

/// Modal dialog allowing a client to reserve a garment in physical stores.
class CrearReservaDialog extends StatefulWidget {
  const CrearReservaDialog({
    super.key,
    required this.idProducto,
    required this.nombreProducto,
    required this.precioUnitario,
    this.talla,
    this.color,
  });

  final int idProducto;
  final String nombreProducto;
  final double precioUnitario;
  final String? talla;
  final String? color;

  @override
  State<CrearReservaDialog> createState() => _CrearReservaDialogState();
}

class _CrearReservaDialogState extends State<CrearReservaDialog> {
  int _cantidad = 1;
  late DateTime _fechaExpiracion;
  bool _enviando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Default expiration date: 2 days from now
    _fechaExpiracion = DateTime.now().add(const Duration(days: 2));
  }

  Future<void> _seleccionarFecha() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaExpiracion,
      firstDate: now,
      lastDate: now.add(const Duration(days: 7)),
    );
    if (picked != null && mounted) {
      setState(() => _fechaExpiracion = picked);
    }
  }

  Future<void> _confirmarReserva() async {
    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      final result = await ReservasService.crear(
        fechaExpiracion: _fechaExpiracion,
        items: [
          {
            'id_producto': widget.idProducto,
            'cantidad': _cantidad,
            'precio_unitario': widget.precioUnitario,
          },
        ],
      );

      if (!mounted) return;

      if (result['success'] == true) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              content: Text('¡Prenda reservada con éxito! El stock ha sido apartado.'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
      } else {
        setState(() {
          _error = result['message'] as String? ?? 'No se pudo registrar la reserva.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al procesar la reserva: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _enviando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final total = widget.precioUnitario * _cantidad;
    final fechaFormatted =
        "${_fechaExpiracion.day}/${_fechaExpiracion.month}/${_fechaExpiracion.year}";

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.bookmark_add_rounded, size: 36, color: colorScheme.primary),
      ),
      title: const Text('Reservar Prenda', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.nombreProducto,
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (widget.talla != null)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.outline.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Talla: ${widget.talla}', style: const TextStyle(fontSize: 11)),
                  ),
                if (widget.color != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.outline.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Color: ${widget.color}', style: const TextStyle(fontSize: 11)),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!, style: TextStyle(color: colorScheme.error, fontSize: 12)),
              ),
            ],

            // Quantity selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Cantidad a apartar:'),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _cantidad > 1 ? () => setState(() => _cantidad--) : null,
                    ),
                    Text('$_cantidad', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => setState(() => _cantidad++),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Expiration date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Válida hasta:'),
                TextButton.icon(
                  onPressed: _seleccionarFecha,
                  icon: const Icon(Icons.calendar_today_outlined, size: 16),
                  label: Text(fechaFormatted),
                ),
              ],
            ),

            const Divider(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total estimado:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'Bs ${total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Nota: El stock se aparta sin cobro inmediato. Podrás probarte la prenda en la sucursal.',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _enviando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _enviando ? null : _confirmarReserva,
          child: _enviando
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Confirmar Reserva'),
        ),
      ],
    );
  }
}

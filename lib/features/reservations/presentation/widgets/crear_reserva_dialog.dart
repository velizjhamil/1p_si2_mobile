import 'package:flutter/material.dart';

import '../../../branches/data/sucursales_service.dart';
import '../../../catalog/data/productos_service.dart';
import '../../data/reservas_service.dart';
/// Modal dialog allowing a client to reserve a garment.
/// Enforces branch stock selection, delivery modality (Retiro en Tienda vs Envío a Domicilio),
/// and automatic confirmation with cash payment (no 50% advance, 48h active reservation).
class CrearReservaDialog extends StatefulWidget {
  const CrearReservaDialog({
    super.key,
    required this.idProducto,
    required this.nombreProducto,
    required this.precioUnitario,
    this.talla,
    this.color,
    this.idSucursalInicial,
    this.disponibilidadSucursales = const [],
  });

  final int idProducto;
  final String nombreProducto;
  final double precioUnitario;
  final String? talla;
  final String? color;
  final int? idSucursalInicial;
  final List<DisponibilidadSucursalDto> disponibilidadSucursales;

  @override
  State<CrearReservaDialog> createState() => _CrearReservaDialogState();
}

class _CrearReservaDialogState extends State<CrearReservaDialog> {
  int _cantidad = 1;
  late DateTime _fechaExpiracion;
  bool _enviando = false;
  String? _error;

  String _tipoEntrega = 'RETIRO'; // 'RETIRO' | 'DOMICILIO'
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();

  List<Sucursal> _sucursales = [];
  int? _idSucursalSeleccionada;
  bool _cargandoSucursales = true;

  @override
  void initState() {
    super.initState();
    // Default expiration: 2 days (48 hours)
    _fechaExpiracion = DateTime.now().add(const Duration(days: 2));
    _idSucursalSeleccionada = widget.idSucursalInicial;
    _cargarSucursales();
  }

  @override
  void dispose() {
    _direccionController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _cargarSucursales() async {
    try {
      final res = await SucursalesService.listar();
      if (!mounted) return;
      if (res['success'] == true && res['sucursales'] is List<Sucursal>) {
        final list = res['sucursales'] as List<Sucursal>;
        setState(() {
          _sucursales = list;
          if (_idSucursalSeleccionada == null && _sucursales.isNotEmpty) {
            // Pick first branch that has available stock if specified
            if (widget.disponibilidadSucursales.isNotEmpty) {
              final conStock = widget.disponibilidadSucursales
                  .where((d) => d.disponible && d.stock > 0)
                  .map((d) => d.idSucursal)
                  .toSet();
              final match = _sucursales.where((s) => conStock.contains(s.codigoSucursal)).firstOrNull;
              _idSucursalSeleccionada = match?.codigoSucursal ?? _sucursales.first.codigoSucursal;
            } else {
              _idSucursalSeleccionada = _sucursales.first.codigoSucursal;
            }
          }
          _cargandoSucursales = false;
        });
      } else {
        setState(() => _cargandoSucursales = false);
      }
    } catch (_) {
      if (mounted) setState(() => _cargandoSucursales = false);
    }
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
    if (_tipoEntrega == 'DOMICILIO' && _direccionController.text.trim().isEmpty) {
      setState(() => _error = 'Por favor ingresa la dirección de entrega.');
      return;
    }

    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      final result = await ReservasService.crear(
        fechaExpiracion: _fechaExpiracion,
        idSucursal: _idSucursalSeleccionada,
        tipoEntrega: _tipoEntrega,
        direccionEntrega: _tipoEntrega == 'DOMICILIO' ? _direccionController.text.trim() : null,
        telefonoEntrega: _telefonoController.text.trim(),
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
        final double totalEst = widget.precioUnitario * _cantidad;
        final sucursalNombre = _sucursales
            .where((s) => s.codigoSucursal == _idSucursalSeleccionada)
            .firstOrNull
            ?.nombre;

        final modoTexto = _tipoEntrega == 'RETIRO'
            ? 'Retiro en sucursal ${sucursalNombre ?? ""}'
            : 'Envío a domicilio contra entrega';

        // Close creation dialog
        Navigator.of(context).pop(true);

        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '¡Reserva CONFIRMADA! ($modoTexto). Pago en efectivo: Bs ${totalEst.toStringAsFixed(2)}.',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade800,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
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
      title: const Text(
        'Reservar Prenda',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
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
            const SizedBox(height: 12),

            // Banner explicativo: Sin anticipo / pago en efectivo
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_rounded, size: 20, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Reserva confirmada al instante con pago en efectivo (al retirar o contra entrega). Sin tarjetas ni anticipos.',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1B5E20)),
                    ),
                  ),
                ],
              ),
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

            // Selector de modalidad de entrega
            const Text(
              'Modalidad de entrega y pago:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _tipoEntrega = 'RETIRO'),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _tipoEntrega == 'RETIRO' ? colorScheme.primary : Colors.grey.shade300,
                          width: _tipoEntrega == 'RETIRO' ? 2 : 1,
                        ),
                        color: _tipoEntrega == 'RETIRO' ? colorScheme.primary.withAlpha(20) : Colors.transparent,
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.storefront_rounded, color: _tipoEntrega == 'RETIRO' ? colorScheme.primary : Colors.grey),
                          const SizedBox(height: 4),
                          Text(
                            'Retiro en Tienda',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _tipoEntrega == 'RETIRO' ? colorScheme.primary : Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Paga en la sucursal',
                            style: TextStyle(fontSize: 10, color: Colors.black54),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _tipoEntrega = 'DOMICILIO'),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _tipoEntrega == 'DOMICILIO' ? colorScheme.primary : Colors.grey.shade300,
                          width: _tipoEntrega == 'DOMICILIO' ? 2 : 1,
                        ),
                        color: _tipoEntrega == 'DOMICILIO' ? colorScheme.primary.withAlpha(20) : Colors.transparent,
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.local_shipping_outlined, color: _tipoEntrega == 'DOMICILIO' ? colorScheme.primary : Colors.grey),
                          const SizedBox(height: 4),
                          Text(
                            'Envío a Domicilio',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _tipoEntrega == 'DOMICILIO' ? colorScheme.primary : Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Paga contra entrega',
                            style: TextStyle(fontSize: 10, color: Colors.black54),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Campos de Envío a Domicilio
            if (_tipoEntrega == 'DOMICILIO') ...[
              const Text(
                'Dirección de entrega (requerido):',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _direccionController,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Calle, número, barrio o referencia...',
                  prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Teléfono de contacto:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _telefonoController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Ej. 70012345',
                  prefixIcon: Icon(Icons.phone_outlined, size: 20),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Sucursal Selector
            Text(
              _tipoEntrega == 'RETIRO' ? 'Sucursal física para retiro:' : 'Sucursal que despacha el stock:',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            if (_cargandoSucursales)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 8),
                    Text('Cargando sucursales...', style: TextStyle(fontSize: 12)),
                  ],
                ),
              )
            else if (_sucursales.isNotEmpty)
              DropdownButtonFormField<int>(
                initialValue: _idSucursalSeleccionada,
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.storefront_rounded, size: 20),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  isDense: true,
                ),
                items: _sucursales.map((suc) {
                  final stockInfo = widget.disponibilidadSucursales
                      .where((d) => d.idSucursal == suc.codigoSucursal)
                      .firstOrNull;
                  final stockText = stockInfo != null
                      ? ' (${stockInfo.stock > 0 ? "${stockInfo.stock} unids" : "Agotado"})'
                      : '';
                  return DropdownMenuItem<int>(
                    value: suc.codigoSucursal,
                    child: Text(
                      '${suc.nombre} • ${suc.ciudad.nombre}$stockText',
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _idSucursalSeleccionada = val),
              )
            else
              const Text('No hay sucursales activas disponibles.', style: TextStyle(fontSize: 12, color: Colors.grey)),

            const SizedBox(height: 12),

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

            // Expiration date (48 hours)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Válida hasta (48h):'),
                TextButton.icon(
                  onPressed: _seleccionarFecha,
                  icon: const Icon(Icons.calendar_today_outlined, size: 16),
                  label: Text(fechaFormatted),
                ),
              ],
            ),

            const Divider(height: 18),

            // Financial breakdown
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total a pagar:', style: TextStyle(fontSize: 13)),
                      Text('Bs ${total.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Método de pago:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.primary),
                      ),
                      Text(
                        _tipoEntrega == 'RETIRO' ? 'Efectivo en Tienda' : 'Efectivo Contra Entrega',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Anticipo requerido:', style: TextStyle(fontSize: 11, color: Colors.black54)),
                      Text('Bs 0.00 (Sin anticipo)',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nota: El stock se aparta de inmediato en la sucursal seleccionada con vigencia de 48 horas (2 días). Pagarás en efectivo al momento de retirar tus prendas o al recibirlas por delivery.',
              style: textTheme.bodySmall?.copyWith(fontSize: 11, color: colorScheme.outline),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _enviando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _enviando ? null : _confirmarReserva,
          icon: _enviando
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check_circle_outline_rounded, size: 16),
          label: Text(_enviando ? 'Confirmando...' : 'Confirmar Reserva (Efectivo)'),
        ),
      ],
    );
  }
}

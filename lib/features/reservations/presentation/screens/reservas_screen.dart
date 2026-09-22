import 'package:flutter/material.dart';

import '../../../../shared/widgets/empty_view.dart';
import '../../../../shared/widgets/error_retry_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../data/reservas_service.dart';

/// Screen displaying the client's garment reservations with cash payment confirmation,
/// delivery modality (store pickup / home delivery) and 48-hour expiration countdown.
class ReservasScreen extends StatefulWidget {
  const ReservasScreen({super.key});

  @override
  State<ReservasScreen> createState() => _ReservasScreenState();
}

class _ReservasScreenState extends State<ReservasScreen> {
  List<ReservaItem> _reservas = [];
  bool _cargando = false;
  String? _error;
  String _estadoFiltro = 'TODAS';

  final List<String> _estados = const [
    'TODAS',
    'PENDIENTE',
    'CONFIRMADA',
    'CANCELADA',
    'COMPLETADA',
  ];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (_cargando) return;
    setState(() {
      _cargando = true;
      _error = null;
    });

    final result = await ReservasService.listar(estado: _estadoFiltro);

    if (!mounted) return;

    setState(() {
      _cargando = false;
      if (result['success'] == true) {
        _reservas = result['reservas'] as List<ReservaItem>;
        _error = null;
      } else {
        _error = result['message'] as String;
      }
    });
  }

  Future<void> _cancelarReserva(ReservaItem reserva) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar reserva'),
        content: Text(
          '¿Estás seguro de cancelar la reserva #${reserva.idReserva}? Las prendas apartadas volverán al inventario de la tienda.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Cancelar Reserva'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await ReservasService.cancelar(reserva.idReserva);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Reserva cancelada correctamente.'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      _cargar();
    } else {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(result['message'] as String? ?? 'No se pudo cancelar.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Reservas de Prendas'),
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _estados.map((e) {
                  final isSelected = _estadoFiltro == e;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(e),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() => _estadoFiltro = e);
                        _cargar();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_cargando && _reservas.isEmpty) {
      return const LoadingView(message: 'Cargando tus reservas de prendas...');
    }

    if (_error != null) {
      return ErrorRetryView(
        title: 'Error al consultar reservas',
        message: _error!,
        onRetry: _cargar,
      );
    }

    if (_reservas.isEmpty) {
      return RefreshIndicator(
        onRefresh: _cargar,
        child: EmptyView(
          icon: Icons.bookmark_border_rounded,
          title: 'No tienes reservas en este estado',
          message: 'Puedes apartar prendas desde el catálogo para probártelas en nuestras sucursales físicas.',
          actionLabel: 'Explorar catálogo',
          onAction: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _reservas.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final r = _reservas[index];
          return _ReservaCard(
            reserva: r,
            onCancel: (r.esPendiente || r.esConfirmada) && !r.esExpirada ? () => _cancelarReserva(r) : null,
          );
        },
      ),
    );
  }
}

class _ReservaCard extends StatelessWidget {
  const _ReservaCard({
    required this.reserva,
    this.onCancel,
  });

  final ReservaItem reserva;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final fechaExp = reserva.fechaExpiracion != null
        ? "${reserva.fechaExpiracion!.day}/${reserva.fechaExpiracion!.month}/${reserva.fechaExpiracion!.year}"
        : "Sin fecha";

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: ID + Sucursal + Estado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.bookmark_rounded, color: colorScheme.primary, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      'Reserva #${reserva.idReserva}',
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                _EstadoBadge(estado: reserva.estado),
              ],
            ),
            const SizedBox(height: 6),

            // Modalidad de entrega y sucursal
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: reserva.esRetiroEnTienda ? Colors.blue.shade50 : Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: reserva.esRetiroEnTienda ? Colors.blue.shade200 : Colors.purple.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        reserva.esRetiroEnTienda ? Icons.storefront_rounded : Icons.local_shipping_outlined,
                        size: 14,
                        color: reserva.esRetiroEnTienda ? Colors.blue.shade800 : Colors.purple.shade800,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        reserva.esRetiroEnTienda ? 'Retiro en Tienda' : 'Envío a Domicilio',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: reserva.esRetiroEnTienda ? Colors.blue.shade900 : Colors.purple.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
                if (reserva.sucursalNombre != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '📍 ${reserva.sucursalNombre!}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            if (reserva.esEnvioDomicilio && reserva.direccionEntrega != null && reserva.direccionEntrega!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.home_outlined, size: 14, color: Colors.black54),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Entrega en: ${reserva.direccionEntrega!}',
                      style: const TextStyle(fontSize: 11, color: Colors.black87),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 6),

            // Temporizador de 48 horas / Fecha
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fecha límite: $fechaExp',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                _TemporizadorBadge(reserva: reserva),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 6),

            // Prendas apartadas
            Text(
              'Prendas apartadas:',
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.outline,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            ...reserva.productos.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '• ${p.nombre} (x${p.cantidad})',
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'Bs ${(p.precioUnitario * p.cantidad).toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 6),

            // Desglose Financiero (Pago en Efectivo)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total a pagar:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                      Text(
                        'Bs ${reserva.totalEstimado.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.payments_outlined, size: 14, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            reserva.esRetiroEnTienda ? 'Pago al retirar en tienda:' : 'Pago contra entrega:',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Efectivo al recibir',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
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
                  if (reserva.montoReembolsado > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Reembolso:', style: TextStyle(fontSize: 12, color: Colors.blue)),
                        Text(
                          'Bs ${reserva.montoReembolsado.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Botones de acción
            if (onCancel != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('Cancelar Reserva', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _TemporizadorBadge extends StatelessWidget {
  const _TemporizadorBadge({required this.reserva});

  final ReservaItem reserva;

  @override
  Widget build(BuildContext context) {
    if (reserva.esCancelada || reserva.esCompletada) {
      return const SizedBox.shrink();
    }

    Color bg;
    Color fg;
    IconData icon;

    if (reserva.esExpirada || (reserva.minutosRestantes != null && reserva.minutosRestantes! <= 0)) {
      bg = Colors.red.shade50;
      fg = Colors.red.shade800;
      icon = Icons.timer_off_rounded;
    } else if (reserva.minutosRestantes != null && reserva.minutosRestantes! <= 360) {
      bg = Colors.red.shade100;
      fg = Colors.red.shade900;
      icon = Icons.alarm_rounded;
    } else if (reserva.minutosRestantes != null && reserva.minutosRestantes! <= 1440) {
      bg = Colors.amber.shade50;
      fg = Colors.amber.shade900;
      icon = Icons.hourglass_bottom_rounded;
    } else {
      bg = Colors.blue.shade50;
      fg = Colors.blue.shade800;
      icon = Icons.timer_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            reserva.tiempoRestanteTexto,
            style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  const _EstadoBadge({required this.estado});

  final String estado;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (estado.toUpperCase()) {
      case 'CONFIRMADA':
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        break;
      case 'COMPLETADA':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade800;
        break;
      case 'CANCELADA':
        bg = Colors.red.shade50;
        fg = Colors.red.shade800;
        break;
      case 'PENDIENTE':
      default:
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        estado,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../orders/presentation/screens/historial_compras_screen.dart';
import '../../../reservations/presentation/screens/reservas_screen.dart';
import '../../data/notificacion_model.dart';
import '../../data/notificaciones_service.dart';

/// Pantalla de Bandeja de Notificaciones del Cliente (CU10).
class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  List<NotificacionModel> _notificaciones = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _totalNoLeidas = 0;
  bool _soloNoLeidas = false;
  bool _isMarkingAll = false;

  @override
  void initState() {
    super.initState();
    _cargarNotificaciones();
  }

  Future<void> _cargarNotificaciones() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await NotificacionesService.obtenerNotificaciones(
      soloNoLeidas: _soloNoLeidas,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result['success'] == true) {
        _notificaciones = result['notificaciones'] as List<NotificacionModel>;
        _totalNoLeidas = result['total_no_leidas'] as int? ?? 0;
        _errorMessage = null;
      } else {
        _errorMessage = result['message'] as String? ??
            'No se pudieron cargar tus notificaciones.';
      }
    });
  }

  Future<void> _marcarComoLeida(NotificacionModel noti) async {
    if (noti.leida) return;

    // Actualización optimista inmediata
    setState(() {
      final index = _notificaciones.indexWhere(
        (n) => n.idNotificacion == noti.idNotificacion,
      );
      if (index != -1) {
        _notificaciones[index] = noti.copyWith(leida: true);
        if (_totalNoLeidas > 0) _totalNoLeidas--;
      }
    });

    final success = await NotificacionesService.marcarComoLeida(noti.idNotificacion);
    if (!success && mounted) {
      // Revertir si hubo error en servidor
      _cargarNotificaciones();
    }
  }

  Future<void> _marcarTodasComoLeidas() async {
    if (_totalNoLeidas == 0 && _notificaciones.every((n) => n.leida)) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Todas tus notificaciones ya están marcadas como leídas.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isMarkingAll = true);

    final count = await NotificacionesService.marcarTodasComoLeidas();

    if (!mounted) return;

    setState(() {
      _isMarkingAll = false;
      _totalNoLeidas = 0;
      _notificaciones = _notificaciones.map((n) => n.copyWith(leida: true)).toList();
      if (_soloNoLeidas) {
        _notificaciones.clear();
      }
    });

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.done_all_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              count > 0
                  ? 'Se marcaron $count notificación(es) como leídas.'
                  : 'Bandeja actualizada como leída.',
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navegarAReferencia(NotificacionModel noti) {
    _marcarComoLeida(noti);

    final ref = noti.referenciaTipo?.toUpperCase() ?? noti.tipo;
    if (ref == 'RESERVA') {
      ScaffoldMessenger.of(context).clearSnackBars();
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ReservasScreen()),
      );
    } else if (ref == 'PEDIDO' || ref == 'VENTA') {
      ScaffoldMessenger.of(context).clearSnackBars();
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const HistorialComprasScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notificaciones',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_isMarkingAll)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.done_all_rounded),
              tooltip: 'Marcar todas como leídas',
              onPressed: _marcarTodasComoLeidas,
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar bandeja',
            onPressed: _isLoading ? null : _cargarNotificaciones,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
            ),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Todas'),
                  selected: !_soloNoLeidas,
                  onSelected: (val) {
                    if (!_soloNoLeidas) return;
                    setState(() => _soloNoLeidas = false);
                    _cargarNotificaciones();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('No leídas'),
                      if (_totalNoLeidas > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$_totalNoLeidas',
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  selected: _soloNoLeidas,
                  onSelected: (val) {
                    if (_soloNoLeidas) return;
                    setState(() => _soloNoLeidas = true);
                    _cargarNotificaciones();
                  },
                ),
              ],
            ),
          ),

          // Main list or states
          Expanded(
            child: _buildBody(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading && _notificaciones.isEmpty) {
      return _buildLoadingState(context);
    }

    if (_errorMessage != null) {
      return _buildErrorState(context);
    }

    if (_notificaciones.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: _cargarNotificaciones,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        itemCount: _notificaciones.length,
        separatorBuilder: (_, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final noti = _notificaciones[index];
          return _NotificacionCard(
            notificacion: noti,
            onTap: () => _marcarComoLeida(noti),
            onActionRef: (noti.referenciaTipo != null ||
                    noti.tipo == 'RESERVA' ||
                    noti.tipo == 'PEDIDO')
                ? () => _navegarAReferencia(noti)
                : null,
          );
        },
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Cargando tus notificaciones...',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            const Text(
              'No pudimos sincronizar tus avisos',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Ocurrió un inconveniente al consultar la bandeja.',
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _cargarNotificaciones,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _soloNoLeidas
                    ? Icons.mark_email_read_rounded
                    : Icons.notifications_none_rounded,
                size: 64,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _soloNoLeidas
                  ? '¡Estás al día!'
                  : 'Bandeja de notificaciones vacía',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _soloNoLeidas
                  ? 'No tienes notificaciones pendientes por leer.'
                  : 'Aquí recibirás confirmaciones de tus compras, reservas de prendas y promociones exclusivas.',
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_soloNoLeidas)
              OutlinedButton.icon(
                onPressed: () {
                  setState(() => _soloNoLeidas = false);
                  _cargarNotificaciones();
                },
                icon: const Icon(Icons.list_alt_rounded),
                label: const Text('Ver todas las notificaciones'),
              )
            else
              FilledButton.tonalIcon(
                onPressed: _cargarNotificaciones,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Actualizar bandeja'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta interactiva de Notificación individual.
class _NotificacionCard extends StatelessWidget {
  const _NotificacionCard({
    required this.notificacion,
    required this.onTap,
    this.onActionRef,
  });

  final NotificacionModel notificacion;
  final VoidCallback onTap;
  final VoidCallback? onActionRef;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUnread = !notificacion.leida;

    final bgColor = isUnread
        ? colorScheme.primaryContainer.withValues(alpha: 0.22)
        : colorScheme.surface;

    final borderColor = isUnread
        ? colorScheme.primary.withValues(alpha: 0.4)
        : colorScheme.outlineVariant.withValues(alpha: 0.35);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: isUnread ? 1.4 : 1),
            boxShadow: isUnread
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Icon Avatar
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: notificacion.colorPorTipo.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  notificacion.iconoPorTipo,
                  color: notificacion.colorPorTipo,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: Category tag + relative time + unread dot
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: notificacion.colorPorTipo.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            notificacion.tipoLegible.toUpperCase(),
                            style: TextStyle(
                              color: notificacion.colorPorTipo,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          notificacion.tiempoRelativo,
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Title
                    Text(
                      notificacion.titulo,
                      style: TextStyle(
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                        fontSize: 14.5,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Message text
                    Text(
                      notificacion.mensaje,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withValues(
                          alpha: isUnread ? 0.9 : 0.72,
                        ),
                        height: 1.35,
                      ),
                    ),

                    // Optional Reference Action (e.g. Ver Pedido / Ver Reserva)
                    if (onActionRef != null) ...[
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: onActionRef,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.open_in_new_rounded,
                                size: 14,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _textoBotonReferencia(notificacion),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _textoBotonReferencia(NotificacionModel noti) {
    final ref = noti.referenciaTipo?.toUpperCase() ?? noti.tipo;
    if (ref == 'RESERVA') {
      return noti.referenciaId != null
          ? 'Ver Reserva #${noti.referenciaId}'
          : 'Ver Mis Reservas';
    } else if (ref == 'PEDIDO' || ref == 'VENTA') {
      return noti.referenciaId != null
          ? 'Ver Compra #${noti.referenciaId}'
          : 'Ver Mis Compras';
    }
    return 'Ver detalle';
  }
}

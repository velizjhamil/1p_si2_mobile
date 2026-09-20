import 'package:flutter/material.dart';

import '../../data/compras_cliente_service.dart';
import 'detalle_compra_screen.dart';

/// Pantalla de Historial de Compras adaptada para el rol de Cliente (CU11 / CU13).
class HistorialComprasScreen extends StatefulWidget {
  const HistorialComprasScreen({super.key});

  @override
  State<HistorialComprasScreen> createState() => _HistorialComprasScreenState();
}

class _HistorialComprasScreenState extends State<HistorialComprasScreen> {
  List<CompraClienteModel> _compras = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _filtroSeleccionado = 'TODAS'; // 'TODAS' | 'PAGADO' | 'PENDIENTE'

  @override
  void initState() {
    super.initState();
    _cargarCompras();
  }

  Future<void> _cargarCompras() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ComprasClienteService.obtenerHistorialCompras(
      estadoPago: _filtroSeleccionado == 'TODAS' ? null : _filtroSeleccionado,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result['success'] == true) {
        _compras = result['compras'] as List<CompraClienteModel>;
        _errorMessage = null;
      } else {
        _errorMessage = result['message'] as String? ?? 'Error al cargar tus compras.';
      }
    });
  }

  void _onFilterChanged(String nuevoFiltro) {
    if (_filtroSeleccionado == nuevoFiltro) return;
    setState(() => _filtroSeleccionado = nuevoFiltro);
    _cargarCompras();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Historial de Compras',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
            onPressed: _isLoading ? null : _cargarCompras,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          _buildFilterChips(context),

          // Main Content
          Expanded(
            child: _buildBody(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildChip(
            label: 'Todas',
            filtroKey: 'TODAS',
            colorScheme: colorScheme,
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'Completadas',
            filtroKey: 'PAGADO',
            colorScheme: colorScheme,
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'Pendientes',
            filtroKey: 'PENDIENTE',
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required String filtroKey,
    required ColorScheme colorScheme,
  }) {
    final isSelected = _filtroSeleccionado == filtroKey;

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
      ),
      selectedColor: colorScheme.primary,
      checkmarkColor: colorScheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (_) => _onFilterChanged(filtroKey),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading && _compras.isEmpty) {
      return _buildLoadingState(context);
    }

    if (_errorMessage != null) {
      return _buildErrorState(context);
    }

    if (_compras.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: _cargarCompras,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _compras.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final compra = _compras[index];
          return _CompraCard(
            compra: compra,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DetalleCompraScreen(compra: compra),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Cargando tus compras...',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(32),
        children: [
          Icon(Icons.error_outline_rounded, size: 56, color: colorScheme.error),
          const SizedBox(height: 16),
          const Text(
            'Error al cargar el historial de compras',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.outline, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              onPressed: _cargarCompras,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 64, color: colorScheme.outline),
            const SizedBox(height: 16),
            const Text(
              'Aún no tienes compras realizadas',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _filtroSeleccionado == 'TODAS'
                  ? 'Tus compras y pedidos realizados desde la app aparecerán organizados aquí.'
                  : 'No se encontraron compras con el filtro seleccionado.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.outline, fontSize: 13),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                if (_filtroSeleccionado != 'TODAS') {
                  _onFilterChanged('TODAS');
                } else {
                  Navigator.of(context).pop();
                }
              },
              icon: Icon(
                _filtroSeleccionado != 'TODAS'
                    ? Icons.filter_alt_off_rounded
                    : Icons.storefront_rounded,
              ),
              label: Text(
                _filtroSeleccionado != 'TODAS'
                    ? 'Ver todas las compras'
                    : 'Explorar Catálogo',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta representativa de una compra en el listado del cliente.
class _CompraCard extends StatelessWidget {
  const _CompraCard({
    required this.compra,
    required this.onTap,
  });

  final CompraClienteModel compra;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Código + Badge de Estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.receipt_rounded,
                          color: colorScheme.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        compra.codigo,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  _buildStatusBadge(context),
                ],
              ),
              const SizedBox(height: 10),

              // Secondary Info: Fecha y Cantidad de Prendas
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 14, color: colorScheme.outline),
                      const SizedBox(width: 4),
                      Text(
                        compra.fechaFormateada,
                        style: TextStyle(fontSize: 12, color: colorScheme.outline),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.checkroom_outlined, size: 14, color: colorScheme.outline),
                      const SizedBox(width: 4),
                      Text(
                        compra.totalPrendas > 0
                            ? '${compra.totalPrendas} prenda(s)'
                            : '${compra.items.length} item(s)',
                        style: TextStyle(fontSize: 12, color: colorScheme.outline),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 20),

              // Footer: Total y Botón "Ver Detalle"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      Text(
                        'Bs ${compra.total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'Ver Detalle',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color bg;
    Color fg;
    Color border;

    if (compra.esCompletada) {
      bg = Colors.green.shade50;
      fg = Colors.green.shade800;
      border = Colors.green.shade300;
    } else if (compra.esPendiente) {
      bg = Colors.amber.shade50;
      fg = Colors.amber.shade900;
      border = Colors.amber.shade300;
    } else {
      bg = Colors.red.shade50;
      fg = Colors.red.shade800;
      border = Colors.red.shade300;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Text(
        compra.estadoLegible,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

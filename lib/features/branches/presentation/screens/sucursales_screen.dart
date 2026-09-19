import 'package:flutter/material.dart';

import '../../data/sucursales_service.dart';

/// Screen that lists the company branches (Sucursales) for the client app.
///
/// Public, read-only screen: no authentication is required to fetch the
/// branches. The list is loaded once on initState and can be refreshed
/// via pull-to-refresh or the "Reintentar" action in the error state.
class SucursalesScreen extends StatefulWidget {
  const SucursalesScreen({super.key});

  @override
  State<SucursalesScreen> createState() => _SucursalesScreenState();
}

class _SucursalesScreenState extends State<SucursalesScreen> {
  /// Guard against concurrent loads (initState + manual retry + pull-to-refresh).
  bool _cargando = false;

  List<Sucursal> _sucursales = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    // Fire-and-forget; the spinner state already reflects the in-flight load.
    _cargar();
  }

  /// Fetches branches (and best-effort city enrichment) from the backend.
  ///
  /// Returns a Future so it can be awaited by [RefreshIndicator]. The
  /// [_cargando] flag prevents overlapping calls when the user spam-taps
  /// "Reintentar" while a request is in flight.
  Future<void> _cargar() async {
    if (_cargando) return;
    setState(() {
      _cargando = true;
      _error = null;
    });

    final result = await SucursalesService.listar();

    // Cities are only used for the screen title fallback / lookup. The
    // branch payload already contains a nested city, so a cities failure
    // must not blank the list.
    if (mounted && result['success'] == true) {
      // Best-effort enrichment; ignored on failure (we already have city
      // info inside each Sucursal from the main response).
      await SucursalesService.listarCiudades();
    }

    if (!mounted) return;

    setState(() {
      _cargando = false;
      if (result['success'] == true) {
        _sucursales = result['sucursales'] as List<Sucursal>;
        _error = null;
      } else {
        _error = result['message'] as String;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sucursales')),
      body: _buildBody(context),
    );
  }

  /// Resolves which of the three canonical async states to render.
  Widget _buildBody(BuildContext context) {
    if (_cargando && _sucursales.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState(context);
    }

    return _buildDataState(context);
  }

  /// Error view: icon + primary copy + backend message + retry button.
  Widget _buildErrorState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: ListView(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'No se pudo cargar la lista de sucursales.',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              onPressed: _cargar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ),
        ],
      ),
    );
  }

  /// Data view: empty state or the populated list wrapped in
  /// [RefreshIndicator] for pull-to-refresh.
  Widget _buildDataState(BuildContext context) {
    if (_sucursales.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _sucursales.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _SucursalCard(sucursal: _sucursales[index]);
        },
      ),
    );
  }

  /// Empty state shown when the backend returns an empty list.
  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: ListView(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: [
          Icon(
            Icons.store_mall_directory_outlined,
            size: 64,
            color: colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Aún no hay sucursales registradas.',
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

/// Single branch card: name, address, city, phone, hours and active badge.
///
/// All colors come from the active theme. No hex literals are used so
/// the screen stays consistent with light and dark variants.
class _SucursalCard extends StatelessWidget {
  const _SucursalCard({required this.sucursal});

  final Sucursal sucursal;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    sucursal.nombre,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _ActiveBadge(isActive: sucursal.isActive),
              ],
            ),
            const SizedBox(height: 8),
            if (sucursal.direccion != null && sucursal.direccion!.isNotEmpty)
              _InfoRow(
                icon: Icons.location_on_outlined,
                text: sucursal.direccion!,
              ),
            _InfoRow(
              icon: Icons.location_city_outlined,
              text: _formatCiudad(sucursal.ciudad),
            ),
            if (sucursal.telefono != null && sucursal.telefono!.isNotEmpty)
              _InfoRow(
                icon: Icons.phone_outlined,
                text: 'Tel: ${sucursal.telefono!}',
              ),
            if (sucursal.horarioAtencion != null &&
                sucursal.horarioAtencion!.isNotEmpty)
              _InfoRow(
                icon: Icons.schedule_outlined,
                text: 'Horario: ${sucursal.horarioAtencion!}',
              ),
          ],
        ),
      ),
    );
  }

  /// Formats the nested city as "Nombre, Departamento" when the
  /// department is present, otherwise just the city name.
  static String _formatCiudad(Ciudad ciudad) {
    final hasDepartamento =
        ciudad.departamento != null && ciudad.departamento!.isNotEmpty;
    if (hasDepartamento) {
      return '${ciudad.nombre}, ${ciudad.departamento}';
    }
    return ciudad.nombre;
  }
}

/// Small icon + text row used inside the branch card.
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill that shows whether a branch is currently active.
class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Active: surface with primary tint. Inactive: muted on-surface variant
    // so it reads as "neutral / disabled" against any background.
    final Color background;
    final Color foreground;
    if (isActive) {
      background = colorScheme.primaryContainer;
      foreground = colorScheme.onPrimaryContainer;
    } else {
      background = colorScheme.surfaceContainerHighest;
      foreground = colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'Activa' : 'Inactiva',
        style: textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

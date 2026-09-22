import 'package:flutter/material.dart';

import '../../../../shared/widgets/empty_view.dart';
import '../../../../shared/widgets/error_retry_view.dart';
import '../../../../shared/widgets/loading_view.dart';
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
 _cargar();
 }

 /// Fetches branches (and best-effort city enrichment) from the backend.
 Future<void> _cargar() async {
 if (_cargando) return;
 setState(() {
 _cargando = true;
 _error = null;
 });

 final result = await SucursalesService.listar();

 if (mounted && result['success'] == true) {
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
 return const LoadingView(message: 'Cargando sucursales disponibles...');
 }

 if (_error != null) {
 return ErrorRetryView(
 title: 'No se pudieron cargar las sucursales',
 message: _error!,
 onRetry: _cargar,
 );
 }

 if (_sucursales.isEmpty) {
 return RefreshIndicator(
 onRefresh: _cargar,
 child: const EmptyView(
 icon: Icons.store_mall_directory_rounded,
 title: 'No hay sucursales registradas',
 message: 'En este momento no se encontraron puntos de atención disponibles.',
 ),
 );
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

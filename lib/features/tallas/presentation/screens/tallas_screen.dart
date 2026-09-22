import 'package:flutter/material.dart';

import '../../../../shared/widgets/empty_view.dart';
import '../../../../shared/widgets/error_retry_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../data/tallas_service.dart';

/// Screen displaying sizes (Tallas) and colors (Colores) for the client app.
class TallasScreen extends StatefulWidget {
 const TallasScreen({super.key});

 @override
 State<TallasScreen> createState() => _TallasScreenState();
}

class _TallasScreenState extends State<TallasScreen>
 with SingleTickerProviderStateMixin {
 late final TabController _tabController;

 List<Talla> _tallas = [];
 List<ColorItem> _colores = [];

 bool _cargandoTallas = false;
 bool _cargandoColores = false;

 String? _errorTallas;
 String? _errorColores;

 Talla? _tallaSeleccionada;

 @override
 void initState() {
 super.initState();
 _tabController = TabController(length: 2, vsync: this);
 _cargarTodo();
 }

 @override
 void dispose() {
 _tabController.dispose();
 super.dispose();
 }

 Future<void> _cargarTodo() async {
 await Future.wait([
 _cargarTallas(),
 _cargarColores(),
 ]);
 }

 Future<void> _cargarTallas() async {
 if (_cargandoTallas) return;
 setState(() {
 _cargandoTallas = true;
 _errorTallas = null;
 });

 final result = await TallasService.listarTallas();

 if (!mounted) return;

 setState(() {
 _cargandoTallas = false;
 if (result['success'] == true) {
 _tallas = result['tallas'] as List<Talla>;
 _errorTallas = null;
 if (_tallas.isNotEmpty && _tallaSeleccionada == null) {
 _tallaSeleccionada = _tallas.first;
 }
 } else {
 _errorTallas = result['message'] as String;
 }
 });
 }

 Future<void> _cargarColores() async {
 if (_cargandoColores) return;
 setState(() {
 _cargandoColores = true;
 _errorColores = null;
 });

 final result = await TallasService.listarColores();

 if (!mounted) return;

 setState(() {
 _cargandoColores = false;
 if (result['success'] == true) {
 _colores = result['colores'] as List<ColorItem>;
 _errorColores = null;
 } else {
 _errorColores = result['message'] as String;
 }
 });
 }

 @override
 Widget build(BuildContext context) {
 return Scaffold(
 appBar: AppBar(
 title: const Text('Tallas y Variantes'),
 bottom: TabBar(
 controller: _tabController,
 tabs: const [
 Tab(
 icon: Icon(Icons.straighten_rounded),
 text: 'Tallas Habilitadas',
 ),
 Tab(
 icon: Icon(Icons.palette_rounded),
 text: 'Paleta de Colores',
 ),
 ],
 ),
 ),
 body: TabBarView(
 controller: _tabController,
 children: [
 _buildTallasTab(context),
 _buildColoresTab(context),
 ],
 ),
 );
 }

 // ---------------------------------------------------------------------------
 // TAB 1: TALLAS
 // ---------------------------------------------------------------------------
 Widget _buildTallasTab(BuildContext context) {
 if (_cargandoTallas && _tallas.isEmpty) {
 return const LoadingView(message: 'Cargando tallas disponibles...');
 }

 if (_errorTallas != null) {
 return _buildErrorState(
 message: _errorTallas!,
 onRetry: _cargarTallas,
 );
 }

 if (_tallas.isEmpty) {
 return _buildEmptyState(
 icon: Icons.straighten_rounded,
 message: 'No hay tallas registradas en el catálogo.',
 );
 }

 final colorScheme = Theme.of(context).colorScheme;
 final textTheme = Theme.of(context).textTheme;

 return RefreshIndicator(
 onRefresh: _cargarTallas,
 child: ListView(
 physics: const AlwaysScrollableScrollPhysics(),
 padding: const EdgeInsets.all(16),
 children: [
 // Informative Banner
 Container(
 padding: const EdgeInsets.all(16),
 decoration: BoxDecoration(
 color: colorScheme.primaryContainer.withValues(alpha: 0.3),
 borderRadius: BorderRadius.circular(16),
 border: Border.all(
 color: colorScheme.primary.withValues(alpha: 0.2),
 ),
 ),
 child: Row(
 children: [
 Container(
 padding: const EdgeInsets.all(10),
 decoration: BoxDecoration(
 color: colorScheme.primary,
 shape: BoxShape.circle,
 ),
 child: Icon(
 Icons.rule_rounded,
 color: colorScheme.onPrimary,
 size: 24,
 ),
 ),
 const SizedBox(width: 14),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 'Guía de Tallas y Colores',
 style: textTheme.titleSmall?.copyWith(
 fontWeight: FontWeight.bold,
 color: colorScheme.onSurface,
 ),
 ),
 const SizedBox(height: 2),
 Text(
 'Selecciona una talla para consultar su descripción y medidas aproximadas de confección.',
 style: textTheme.bodySmall?.copyWith(
 color: colorScheme.onSurface.withValues(alpha: 0.7),
 ),
 ),
 ],
 ),
 ),
 ],
 ),
 ),
 const SizedBox(height: 16),

 // Horizontal/Grid Size Selector
 Text(
 'Tallas Registradas en Sistema (${_tallas.length}):',
 style: textTheme.labelLarge?.copyWith(
 fontWeight: FontWeight.bold,
 color: colorScheme.outline,
 ),
 ),
 const SizedBox(height: 10),

 Wrap(
 spacing: 10,
 runSpacing: 10,
 children: _tallas.map((t) {
 final isSelected = _tallaSeleccionada?.idTalla == t.idTalla;
 return ChoiceChip(
 avatar: CircleAvatar(
 backgroundColor: isSelected
 ? colorScheme.onPrimary
 : colorScheme.primaryContainer,
 child: Text(
 t.nombreTalla,
 style: TextStyle(
 fontSize: 10,
 fontWeight: FontWeight.bold,
 color: isSelected
 ? colorScheme.primary
 : colorScheme.onPrimaryContainer,
 ),
 ),
 ),
 label: Text(
 t.nombreTalla,
 style: TextStyle(
 fontWeight:
 isSelected ? FontWeight.bold : FontWeight.w600,
 ),
 ),
 selected: isSelected,
 onSelected: (selected) {
 if (selected) {
 setState(() => _tallaSeleccionada = t);
 }
 },
 );
 }).toList(),
 ),

 const SizedBox(height: 24),

 // Selected Size Detailed Card
 if (_tallaSeleccionada != null) ...[
 Text(
 'Detalle de la Talla Seleccionada:',
 style: textTheme.labelLarge?.copyWith(
 fontWeight: FontWeight.bold,
 color: colorScheme.outline,
 ),
 ),
 const SizedBox(height: 10),
 _SizeDetailCard(talla: _tallaSeleccionada!),
 ],

 const SizedBox(height: 20),

 // All sizes list overview
 Text(
 'Listado Completo de Tallas:',
 style: textTheme.labelLarge?.copyWith(
 fontWeight: FontWeight.bold,
 color: colorScheme.outline,
 ),
 ),
 const SizedBox(height: 10),
 ..._tallas.map((t) => Card(
 elevation: 0.5,
 margin: const EdgeInsets.only(bottom: 8),
 shape: RoundedRectangleBorder(
 borderRadius: BorderRadius.circular(12),
 side: BorderSide(
 color: colorScheme.outline.withValues(alpha: 0.15),
 ),
 ),
 child: ListTile(
 leading: CircleAvatar(
 backgroundColor:
 colorScheme.primaryContainer.withValues(alpha: 0.6),
 child: Text(
 t.nombreTalla,
 style: TextStyle(
 fontWeight: FontWeight.bold,
 color: colorScheme.primary,
 ),
 ),
 ),
 title: Text(
 'Talla ${t.nombreTalla}',
 style: const TextStyle(fontWeight: FontWeight.w600),
 ),
 subtitle: Text(
 t.descripcion?.isNotEmpty == true
 ? t.descripcion!
 : 'Estándar para prendas Attention',
 ),
 trailing: Container(
 padding: const EdgeInsets.symmetric(
 horizontal: 8, vertical: 3),
 decoration: BoxDecoration(
 color: Colors.green.shade50,
 borderRadius: BorderRadius.circular(8),
 border: Border.all(color: Colors.green.shade300),
 ),
 child: Text(
 t.activo ? 'Habilitada' : 'Inactiva',
 style: TextStyle(
 color: Colors.green.shade800,
 fontSize: 10,
 fontWeight: FontWeight.bold,
 ),
 ),
 ),
 onTap: () => setState(() => _tallaSeleccionada = t),
 ),
 )),
 ],
 ),
 );
 }

 // ---------------------------------------------------------------------------
 // TAB 2: COLORES
 // ---------------------------------------------------------------------------
 Widget _buildColoresTab(BuildContext context) {
 if (_cargandoColores && _colores.isEmpty) {
 return const LoadingView(message: 'Cargando colores disponibles...');
 }

 if (_errorColores != null) {
 return _buildErrorState(
 message: _errorColores!,
 onRetry: _cargarColores,
 );
 }

 if (_colores.isEmpty) {
 return _buildEmptyState(
 icon: Icons.palette_outlined,
 message: 'No hay colores registrados en el catálogo.',
 );
 }

 return RefreshIndicator(
 onRefresh: _cargarColores,
 child: ListView.separated(
 physics: const AlwaysScrollableScrollPhysics(),
 padding: const EdgeInsets.all(16),
 itemCount: _colores.length,
 separatorBuilder: (_, _) => const SizedBox(height: 10),
 itemBuilder: (context, index) {
 final c = _colores[index];
 return _ColorCard(colorItem: c);
 },
 ),
 );
 }

 Widget _buildErrorState({
 required String message,
 required VoidCallback onRetry,
 }) {
 return ErrorRetryView(
 title: 'Error al consultar información',
 message: message,
 onRetry: onRetry,
 );
 }

 Widget _buildEmptyState({required IconData icon, required String message}) {
 return EmptyView(
 icon: icon,
 title: 'Catálogo sin registros',
 message: message,
 );
 }
}

/// Detailed card displaying measurements and sizing advice for selected size
class _SizeDetailCard extends StatelessWidget {
 const _SizeDetailCard({required this.talla});

 final Talla talla;

 @override
 Widget build(BuildContext context) {
 final colorScheme = Theme.of(context).colorScheme;
 final textTheme = Theme.of(context).textTheme;

 final measurements = _getApproximateMeasurements(talla.nombreTalla);

 return Card(
 elevation: 2,
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
 child: Padding(
 padding: const EdgeInsets.all(18),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 children: [
 Container(
 width: 50,
 height: 50,
 decoration: BoxDecoration(
 color: colorScheme.primary,
 borderRadius: BorderRadius.circular(14),
 ),
 alignment: Alignment.center,
 child: Text(
 talla.nombreTalla,
 style: TextStyle(
 fontSize: 20,
 fontWeight: FontWeight.bold,
 color: colorScheme.onPrimary,
 ),
 ),
 ),
 const SizedBox(width: 14),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 'Talla ${talla.nombreTalla}',
 style: textTheme.titleLarge?.copyWith(
 fontWeight: FontWeight.bold,
 ),
 ),
 Text(
 talla.descripcion?.isNotEmpty == true
 ? talla.descripcion!
 : 'Identificador #${talla.idTalla}',
 style: textTheme.bodySmall?.copyWith(
 color: colorScheme.onSurface.withValues(alpha: 0.7),
 ),
 ),
 ],
 ),
 ),
 Container(
 padding:
 const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
 decoration: BoxDecoration(
 color: Colors.green.shade50,
 borderRadius: BorderRadius.circular(8),
 border: Border.all(color: Colors.green.shade300),
 ),
 child: Text(
 'Disponible',
 style: TextStyle(
 color: Colors.green.shade800,
 fontWeight: FontWeight.bold,
 fontSize: 11,
 ),
 ),
 ),
 ],
 ),
 const SizedBox(height: 16),
 const Divider(),
 const SizedBox(height: 10),
 Text(
 'Guía de medidas estimadas:',
 style: textTheme.labelLarge?.copyWith(
 fontWeight: FontWeight.bold,
 ),
 ),
 const SizedBox(height: 10),
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceAround,
 children: [
 _MeasurementBadge(label: 'Pecho', value: measurements['pecho']!),
 _MeasurementBadge(
 label: 'Cintura', value: measurements['cintura']!),
 _MeasurementBadge(
 label: 'Cadera', value: measurements['cadera']!),
 ],
 ),
 ],
 ),
 ),
 );
 }

 Map<String, String> _getApproximateMeasurements(String size) {
 switch (size.toUpperCase()) {
 case 'XS':
 return {'pecho': '82-86 cm', 'cintura': '62-66 cm', 'cadera': '88-92 cm'};
 case 'S':
 return {'pecho': '86-92 cm', 'cintura': '66-72 cm', 'cadera': '92-98 cm'};
 case 'M':
 return {
 'pecho': '92-98 cm',
 'cintura': '72-78 cm',
 'cadera': '98-104 cm'
 };
 case 'L':
 return {
 'pecho': '98-104 cm',
 'cintura': '78-86 cm',
 'cadera': '104-110 cm'
 };
 case 'XL':
 return {
 'pecho': '104-112 cm',
 'cintura': '86-94 cm',
 'cadera': '110-118 cm'
 };
 default:
 return {'pecho': 'Estándar', 'cintura': 'Estándar', 'cadera': 'Estándar'};
 }
 }
}

class _MeasurementBadge extends StatelessWidget {
 const _MeasurementBadge({required this.label, required this.value});

 final String label;
 final String value;

 @override
 Widget build(BuildContext context) {
 final colorScheme = Theme.of(context).colorScheme;

 return Container(
 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
 decoration: BoxDecoration(
 color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
 borderRadius: BorderRadius.circular(10),
 ),
 child: Column(
 children: [
 Text(
 label,
 style: TextStyle(
 fontSize: 11,
 fontWeight: FontWeight.w600,
 color: colorScheme.outline,
 ),
 ),
 const SizedBox(height: 2),
 Text(
 value,
 style: TextStyle(
 fontSize: 12,
 fontWeight: FontWeight.bold,
 color: colorScheme.onSurface,
 ),
 ),
 ],
 ),
 );
 }
}

/// Color Card with circle swatch, HEX code, and label
class _ColorCard extends StatelessWidget {
 const _ColorCard({required this.colorItem});

 final ColorItem colorItem;

 @override
 Widget build(BuildContext context) {
 final colorScheme = Theme.of(context).colorScheme;
 final textTheme = Theme.of(context).textTheme;

 final parsedColor = _parseColor(colorItem.codigoHex);

 return Card(
 elevation: 1,
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
 child: Padding(
 padding: const EdgeInsets.all(14),
 child: Row(
 children: [
 // Color Swatch with border
 Container(
 width: 44,
 height: 44,
 decoration: BoxDecoration(
 color: parsedColor,
 shape: BoxShape.circle,
 border: Border.all(
 color: colorScheme.outline.withValues(alpha: 0.3),
 width: 2,
 ),
 boxShadow: [
 BoxShadow(
 color: Colors.black.withValues(alpha: 0.08),
 blurRadius: 4,
 offset: const Offset(0, 2),
 ),
 ],
 ),
 ),
 const SizedBox(width: 16),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 colorItem.nombreColor,
 style: textTheme.titleMedium?.copyWith(
 fontWeight: FontWeight.bold,
 ),
 ),
 const SizedBox(height: 2),
 Text(
 'Código HEX: ${colorItem.codigoHex.toUpperCase()}',
 style: textTheme.bodySmall?.copyWith(
 color: colorScheme.outline,
 fontFamily: 'monospace',
 ),
 ),
 ],
 ),
 ),
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
 decoration: BoxDecoration(
 color: Colors.green.shade50,
 borderRadius: BorderRadius.circular(8),
 border: Border.all(color: Colors.green.shade300),
 ),
 child: Text(
 'Disponible',
 style: TextStyle(
 color: Colors.green.shade800,
 fontSize: 10,
 fontWeight: FontWeight.bold,
 ),
 ),
 ),
 ],
 ),
 ),
 );
 }

 Color _parseColor(String hex) {
 var cleanHex = hex.replaceAll('#', '').trim();
 if (cleanHex.length == 6) {
 cleanHex = 'FF$cleanHex';
 }
 final parsed = int.tryParse(cleanHex, radix: 16);
 if (parsed == null) return Colors.grey;
 return Color(parsed);
 }
}

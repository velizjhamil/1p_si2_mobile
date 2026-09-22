import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/descuento_model.dart';
import '../../data/descuentos_service.dart';

/// Pantalla de Visualización de Descuentos y Promociones activas.
class PromocionesScreen extends StatefulWidget {
 const PromocionesScreen({
 super.key,
 this.onNavigateToCatalog,
 });

 final VoidCallback? onNavigateToCatalog;

 @override
 State<PromocionesScreen> createState() => _PromocionesScreenState();
}

class _PromocionesScreenState extends State<PromocionesScreen> {
 List<DescuentoModel> _descuentos = [];
 bool _isLoading = true;
 String? _errorMessage;

 @override
 void initState() {
 super.initState();
 _cargarPromociones();
 }

 Future<void> _cargarPromociones() async {
 setState(() {
 _isLoading = true;
 _errorMessage = null;
 });

 final result = await DescuentosService.obtenerDescuentosActivos();

 if (!mounted) return;

 setState(() {
 _isLoading = false;
 if (result['success'] == true) {
 _descuentos = result['descuentos'] as List<DescuentoModel>;
 _errorMessage = null;
 } else {
 _errorMessage = result['message'] as String? ??
 'No se pudieron cargar las promociones.';
 }
 });
 }

 void _copiarCodigo(String codigo) {
 Clipboard.setData(ClipboardData(text: codigo));
 final messenger = ScaffoldMessenger.of(context);
 messenger.clearSnackBars();
 messenger.showSnackBar(
 SnackBar(
 content: Row(
 children: [
 const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
 const SizedBox(width: 8),
 Text('¡Cupón "$codigo" copiado al portapapeles!'),
 ],
 ),
 behavior: SnackBarBehavior.floating,
 duration: const Duration(seconds: 2),
 ),
 );
 }

 @override
 Widget build(BuildContext context) {
 return Scaffold(
 appBar: AppBar(
 title: const Text(
 'Descuentos y Ofertas',
 style: TextStyle(fontWeight: FontWeight.bold),
 ),
 actions: [
 IconButton(
 icon: const Icon(Icons.refresh_rounded),
 tooltip: 'Actualizar',
 onPressed: _isLoading ? null : _cargarPromociones,
 ),
 ],
 ),
 body: _buildBody(context),
 );
 }

 Widget _buildBody(BuildContext context) {
 if (_isLoading && _descuentos.isEmpty) {
 return _buildLoadingState(context);
 }

 if (_errorMessage != null) {
 return _buildErrorState(context);
 }

 if (_descuentos.isEmpty) {
 return _buildEmptyState(context);
 }

 return RefreshIndicator(
 onRefresh: _cargarPromociones,
 child: ListView.separated(
 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
 itemCount: _descuentos.length + 1, // +1 para el header hero
 separatorBuilder: (_, index) => index == 0
 ? const SizedBox(height: 16)
 : const SizedBox(height: 12),
 itemBuilder: (context, index) {
 if (index == 0) {
 return _buildHeroHeader(context);
 }
 final promo = _descuentos[index - 1];
 return _DescuentoCard(
 descuento: promo,
 onCopiarCodigo: promo.tieneCodigo ? () => _copiarCodigo(promo.codigo!) : null,
 );
 },
 ),
 );
 }

 Widget _buildHeroHeader(BuildContext context) {
 final colorScheme = Theme.of(context).colorScheme;

 return Container(
 padding: const EdgeInsets.all(20),
 decoration: BoxDecoration(
 gradient: LinearGradient(
 colors: [
 colorScheme.primary,
 Colors.purple.shade900,
 ],
 begin: Alignment.topLeft,
 end: Alignment.bottomRight,
 ),
 borderRadius: BorderRadius.circular(20),
 boxShadow: [
 BoxShadow(
 color: colorScheme.primary.withAlpha(50),
 blurRadius: 10,
 offset: const Offset(0, 4),
 ),
 ],
 ),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 children: [
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
 decoration: BoxDecoration(
 color: Colors.white.withAlpha(40),
 borderRadius: BorderRadius.circular(8),
 ),
 child: const Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Icon(Icons.local_fire_department_rounded, color: Colors.amber, size: 16),
 SizedBox(width: 4),
 Text(
 'OFERTAS ACTIVAS',
 style: TextStyle(
 color: Colors.white,
 fontSize: 11,
 fontWeight: FontWeight.bold,
 letterSpacing: 0.6,
 ),
 ),
 ],
 ),
 ),
 const Spacer(),
 const Icon(Icons.sell_outlined, color: Colors.white70, size: 22),
 ],
 ),
 const SizedBox(height: 12),
 const Text(
 '¡Ahorra en tus Prendas Favoritas!',
 style: TextStyle(
 color: Colors.white,
 fontSize: 18,
 fontWeight: FontWeight.bold,
 ),
 ),
 const SizedBox(height: 6),
 const Text(
 'Aplica estos cupones de descuento o aprovecha las rebajas especiales en tus compras y pedidos desde la app.',
 style: TextStyle(
 color: Colors.white70,
 fontSize: 12,
 height: 1.3,
 ),
 ),
 ],
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
 'Cargando descuentos y promociones...',
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
 'Error al cargar las promociones',
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
 onPressed: _cargarPromociones,
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
 Icon(Icons.local_offer_outlined, size: 64, color: colorScheme.outline),
 const SizedBox(height: 16),
 const Text(
 'No hay promociones activas por ahora',
 textAlign: TextAlign.center,
 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
 ),
 const SizedBox(height: 8),
 Text(
 'Vuelve pronto para descubrir nuevos cupones de descuento y rebajas de temporada.',
 textAlign: TextAlign.center,
 style: TextStyle(color: colorScheme.outline, fontSize: 13),
 ),
 const SizedBox(height: 24),
 FilledButton.icon(
 onPressed: () {
 if (Navigator.of(context).canPop()) {
 Navigator.of(context).pop();
 } else {
 widget.onNavigateToCatalog?.call();
 }
 },
 icon: const Icon(Icons.storefront_rounded),
 label: const Text('Explorar Catálogo'),
 ),
 ],
 ),
 ),
 );
 }
}

/// Tarjeta visual representativa de un descuento o cupón en la lista.
class _DescuentoCard extends StatelessWidget {
 const _DescuentoCard({
 required this.descuento,
 this.onCopiarCodigo,
 });

 final DescuentoModel descuento;
 final VoidCallback? onCopiarCodigo;

 @override
 Widget build(BuildContext context) {
 final colorScheme = Theme.of(context).colorScheme;
 final textTheme = Theme.of(context).textTheme;

 return Card(
 elevation: 1.5,
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
 child: Padding(
 padding: const EdgeInsets.all(16),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Top Row: Badge de Descuento + Tag de Expiración
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
 decoration: BoxDecoration(
 color: Colors.red.shade50,
 borderRadius: BorderRadius.circular(8),
 border: Border.all(color: Colors.red.shade300),
 ),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Icon(Icons.percent_rounded, size: 14, color: Colors.red.shade800),
 const SizedBox(width: 4),
 Text(
 descuento.badgeTexto,
 style: TextStyle(
 color: Colors.red.shade900,
 fontSize: 12,
 fontWeight: FontWeight.bold,
 ),
 ),
 ],
 ),
 ),
 Row(
 children: [
 Icon(
 descuento.estaPorVencer
 ? Icons.access_time_filled_rounded
 : Icons.calendar_today_outlined,
 size: 13,
 color: descuento.estaPorVencer ? Colors.amber.shade900 : colorScheme.outline,
 ),
 const SizedBox(width: 4),
 Text(
 descuento.estaPorVencer
 ? '¡Vence en ${descuento.diasRestantes}d!'
 : descuento.vigenciaTexto,
 style: TextStyle(
 fontSize: 11,
 fontWeight: descuento.estaPorVencer ? FontWeight.bold : FontWeight.normal,
 color: descuento.estaPorVencer ? Colors.amber.shade900 : colorScheme.outline,
 ),
 ),
 ],
 ),
 ],
 ),
 const SizedBox(height: 12),

 // Promo Title
 Text(
 descuento.nombre,
 style: textTheme.titleMedium?.copyWith(
 fontWeight: FontWeight.bold,
 ),
 ),

 // Description if available
 if (descuento.descripcion != null && descuento.descripcion!.isNotEmpty) ...[
 const SizedBox(height: 4),
 Text(
 descuento.descripcion!,
 style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
 ),
 ],

 // Minimum Purchase Condition
 if (descuento.condicionCompraMinima != null) ...[
 const SizedBox(height: 8),
 Row(
 children: [
 Icon(Icons.info_outline_rounded, size: 14, color: colorScheme.outline),
 const SizedBox(width: 4),
 Text(
 descuento.condicionCompraMinima!,
 style: TextStyle(fontSize: 11, color: colorScheme.outline),
 ),
 ],
 ),
 ],

 const Divider(height: 20),

 // Bottom Section: Coupon code with copy action OR automatic badge
 if (descuento.tieneCodigo)
 Row(
 children: [
 Expanded(
 child: Container(
 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
 decoration: BoxDecoration(
 color: colorScheme.primaryContainer.withAlpha(40),
 borderRadius: BorderRadius.circular(10),
 border: Border.all(
 color: colorScheme.primary.withAlpha(80),
 style: BorderStyle.solid,
 ),
 ),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Icon(Icons.confirmation_number_outlined,
 size: 16, color: colorScheme.primary),
 const SizedBox(width: 8),
 Text(
 descuento.codigo!,
 style: TextStyle(
 fontWeight: FontWeight.bold,
 letterSpacing: 1.1,
 color: colorScheme.primary,
 fontSize: 13,
 ),
 ),
 ],
 ),
 ),
 ),
 const SizedBox(width: 10),
 FilledButton.tonalIcon(
 onPressed: onCopiarCodigo,
 style: FilledButton.styleFrom(
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
 padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
 ),
 icon: const Icon(Icons.copy_rounded, size: 16),
 label: const Text('Copiar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
 ),
 ],
 )
 else
 Row(
 children: [
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
 decoration: BoxDecoration(
 color: Colors.green.shade50,
 borderRadius: BorderRadius.circular(8),
 ),
 child: Text(
 'Descuento automático al comprar',
 style: TextStyle(
 color: Colors.green.shade800,
 fontSize: 11,
 fontWeight: FontWeight.bold,
 ),
 ),
 ),
 ],
 ),
 ],
 ),
 ),
 );
 }
}

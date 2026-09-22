import 'package:flutter/material.dart';

import '../../../../core/storage/secure_storage_service.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../../../../shared/widgets/error_retry_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../ai_assistant/presentation/screens/asistente_ia_screen.dart';
import '../../../ar_tryon/presentation/screens/probador_virtual_screen.dart';
import '../../../branches/data/sucursales_service.dart';
import '../../../branches/presentation/screens/sucursales_screen.dart';
import '../../../cart/logic/cart_service.dart';
import '../../../cart/presentation/screens/cart_screen.dart';
import '../../../categories/data/categorias_service.dart';
import '../../../notifications/data/notificaciones_service.dart';
import '../../../notifications/presentation/screens/notificaciones_screen.dart';
import '../../../profile/presentation/screens/perfil_screen.dart';
import '../../../promotions/data/descuento_model.dart';
import '../../../promotions/data/descuentos_service.dart';
import '../../../promotions/presentation/screens/promociones_screen.dart';
import '../../../promotions/presentation/widgets/promociones_banner_section.dart';
import '../../../reservations/presentation/screens/reservas_screen.dart';
import '../../data/productos_service.dart';
import '../widgets/product_detail_sheet.dart';

/// Main navigation shell for the Attention mobile app.
///
/// Replaces the legacy hamburger drawer with a modern Material 3
/// [NavigationBar] composed of 5 core modules:
/// 1. Inicio / Catálogo with integrated Categories filter
/// 2. Sucursales
/// 3. Promociones
/// 4. Probador Virtual IA
/// 5. Perfil y Ajustes
class HomeScreen extends StatefulWidget {
 const HomeScreen({
 super.key,
 this.initialTabIndex = 0,
 });

 final int initialTabIndex;

 @override
 State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
 late int _currentIndex;

 @override
 void initState() {
 super.initState();
 _currentIndex = widget.initialTabIndex;
 CartService.instance.init();
 }

 void _onTabSelected(int index) {
 setState(() => _currentIndex = index);
 }

 @override
 Widget build(BuildContext context) {
 return Scaffold(
 body: IndexedStack(
 index: _currentIndex,
 children: [
 _CatalogTab(
 onNavigateToTab: _onTabSelected,
 ),
 const SucursalesScreen(),
 PromocionesScreen(
 onNavigateToCatalog: () => _onTabSelected(0),
 ),
 const ProbadorVirtualScreen(),
 PerfilScreen(
 onNavigateToCatalog: () => _onTabSelected(0),
 ),
 ],
 ),
 bottomNavigationBar: NavigationBar(
 selectedIndex: _currentIndex,
 onDestinationSelected: _onTabSelected,
 destinations: const [
 NavigationDestination(
 icon: Icon(Icons.storefront_outlined),
 selectedIcon: Icon(Icons.storefront_rounded),
 label: 'Inicio',
 ),
 NavigationDestination(
 icon: Icon(Icons.store_mall_directory_outlined),
 selectedIcon: Icon(Icons.store_mall_directory_rounded),
 label: 'Sucursales',
 ),
 NavigationDestination(
 icon: Icon(Icons.local_offer_outlined),
 selectedIcon: Icon(Icons.local_offer_rounded),
 label: 'Promociones',
 ),
 NavigationDestination(
 icon: Icon(Icons.auto_awesome_outlined),
 selectedIcon: Icon(Icons.auto_awesome_rounded),
 label: 'Probador IA',
 ),
 NavigationDestination(
 icon: Icon(Icons.person_outline_rounded),
 selectedIcon: Icon(Icons.person_rounded),
 label: 'Perfil',
 ),
 ],
 ),
 );
 }
}

/// Primary catalog screen (Tab 0) featuring integrated category filters,
/// keyword search, promotional highlights, and 2-column garment grid.
class _CatalogTab extends StatefulWidget {
 const _CatalogTab({
 required this.onNavigateToTab,
 });

 final ValueChanged<int> onNavigateToTab;

 @override
 State<_CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends State<_CatalogTab> {
 final TextEditingController _searchController = TextEditingController();

 List<Producto> _productos = [];
 List<Categoria> _categorias = [];
 Categoria? _categoriaSeleccionada;

 List<Sucursal> _sucursales = [];
 Sucursal? _sucursalSeleccionada;
 List<DescuentoModel> _promociones = [];
 DescuentoModel? _mejorDescuento;

 bool _isLoading = true;
 bool _isSearching = false;
 String? _error;
 int _total = 0;
 int _totalNotificacionesNoLeidas = 0;
 Map<String, dynamic>? _session;

 @override
 void initState() {
 super.initState();
 _loadSession();
 _loadSucursales();
 _loadPromociones();
 _loadCategories();
 _loadProducts();
 _loadNotificacionesContador();
 }

 @override
 void dispose() {
 _searchController.dispose();
 super.dispose();
 }

 Future<void> _loadSession() async {
 final session = await SecureStorageService.getUserSession();
 if (mounted) {
 setState(() => _session = session);
 }
 }

 Future<void> _loadSucursales() async {
 try {
 final result = await SucursalesService.listar();
 if (!mounted) return;
 if (result['success'] == true && result['sucursales'] is List<Sucursal>) {
 setState(() {
 _sucursales = result['sucursales'] as List<Sucursal>;
 });
 }
 } catch (_) {}
 }

 Future<void> _loadPromociones() async {
 try {
 final result = await DescuentosService.obtenerDescuentosActivos(limit: 10);
 if (!mounted) return;
 if (result['success'] == true && result['descuentos'] is List<DescuentoModel>) {
 final list = result['descuentos'] as List<DescuentoModel>;
 setState(() {
 _promociones = list;
 if (_promociones.isNotEmpty) {
 final ordenadas = List<DescuentoModel>.from(_promociones)
 ..sort((a, b) => b.valor.compareTo(a.valor));
 _mejorDescuento = ordenadas.first;
 }
 });
 }
 } catch (_) {}
 }

 Future<void> _loadCategories() async {
 final result = await CategoriasService.listar(limit: 50);
 if (!mounted) return;
 if (result['success'] == true && result['categorias'] is List<Categoria>) {
 setState(() {
 _categorias = result['categorias'] as List<Categoria>;
 });
 }
 }

 Future<void> _loadProducts({String? q, int? idCategoria}) async {
 final result = await ProductosService.listar(
 q: q,
 idCategoria: idCategoria ?? _categoriaSeleccionada?.idCategoria,
 idSucursal: _sucursalSeleccionada?.codigoSucursal,
 limit: 50,
 );

 if (!mounted) return;

 setState(() {
 _isLoading = false;
 _isSearching = false;
 if (result['success'] == true) {
 _productos = result['productos'] as List<Producto>;
 _total = result['total'] as int? ?? 0;
 _error = null;
 } else {
 _error = result['message'] as String;
 _productos = [];
 }
 });
 }

 Future<void> _handleSearch(String value) {
 setState(() {
 _isSearching = true;
 _error = null;
 });
 return _loadProducts(q: value);
 }

 void _onCategorySelected(Categoria? cat) {
 setState(() {
 if (_categoriaSeleccionada?.idCategoria == cat?.idCategoria) {
 _categoriaSeleccionada = null;
 } else {
 _categoriaSeleccionada = cat;
 }
 _isLoading = true;
 });
 _loadProducts(
 q: _searchController.text,
 idCategoria: _categoriaSeleccionada?.idCategoria,
 );
 }

 Future<void> _loadNotificacionesContador() async {
 final count = await NotificacionesService.obtenerContadorNoLeidas();
 if (mounted) {
 setState(() => _totalNotificacionesNoLeidas = count);
 }
 }

 void _navigateToCart() {
 ScaffoldMessenger.of(context).clearSnackBars();
 Navigator.of(context).push(
 MaterialPageRoute(builder: (_) => const CartScreen()),
 );
 }

 void _navigateToReservas() {
 ScaffoldMessenger.of(context).clearSnackBars();
 Navigator.of(context).push(
 MaterialPageRoute(builder: (_) => const ReservasScreen()),
 );
 }

 void _navigateToNotificaciones() async {
 ScaffoldMessenger.of(context).clearSnackBars();
 await Navigator.of(context).push(
 MaterialPageRoute(builder: (_) => const NotificacionesScreen()),
 );
 _loadNotificacionesContador();
 }

 void _navigateToAsistenteIA() {
 ScaffoldMessenger.of(context).clearSnackBars();
 Navigator.of(context).push(
 MaterialPageRoute(builder: (_) => const AsistenteIAScreen()),
 );
 }

 void _openProductDetail(Producto producto) {
 showModalBottomSheet<void>(
 context: context,
 isScrollControlled: true,
 shape: const RoundedRectangleBorder(
 borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
 ),
 builder: (_) => ProductDetailSheet(
 producto: producto,
 descuento: _mejorDescuento,
 idSucursalSeleccionada: _sucursalSeleccionada?.codigoSucursal,
 ),
 );
 }

 @override
 Widget build(BuildContext context) {
 final colorScheme = Theme.of(context).colorScheme;
 final textTheme = Theme.of(context).textTheme;
 final nombre = (_session?['nombre'] as String?) ?? '';

 return Scaffold(
 appBar: AppBar(
 title: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 const Text(
 'Attention',
 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
 ),
 if (nombre.isNotEmpty)
 Text(
 '¡Hola, $nombre!',
 style: textTheme.bodySmall?.copyWith(
 color: colorScheme.onSurface.withValues(alpha: 0.7),
 ),
 ),
 ],
 ),
 actions: [
 // Attention AI Assistant Button
 IconButton(
 icon: Container(
 padding: const EdgeInsets.all(4),
 decoration: const BoxDecoration(
 gradient: LinearGradient(
 colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
 begin: Alignment.topLeft,
 end: Alignment.bottomRight,
 ),
 shape: BoxShape.circle,
 ),
 child: const Icon(
 Icons.auto_awesome,
 size: 16,
 color: Colors.white,
 ),
 ),
 tooltip: 'Attention AI (Asistente de Moda)',
 onPressed: _navigateToAsistenteIA,
 ),
 // Shopping Cart with dynamic badge
 ListenableBuilder(
 listenable: CartService.instance,
 builder: (context, _) {
 final count = CartService.instance.totalItemCount;
 return IconButton(
 icon: Badge(
 isLabelVisible: count > 0,
 label: Text('$count'),
 child: const Icon(Icons.shopping_bag_outlined),
 ),
 tooltip: 'Mi Carrito ($count)',
 onPressed: _navigateToCart,
 );
 },
 ),
 IconButton(
 icon: const Icon(Icons.bookmark_border_rounded),
 tooltip: 'Mis Reservas',
 onPressed: _navigateToReservas,
 ),
 IconButton(
 icon: Badge(
 isLabelVisible: _totalNotificacionesNoLeidas > 0,
 label: Text('$_totalNotificacionesNoLeidas'),
 child: const Icon(Icons.notifications_none_rounded),
 ),
 tooltip: 'Notificaciones ($_totalNotificacionesNoLeidas)',
 onPressed: _navigateToNotificaciones,
 ),
 ],
 ),
 body: RefreshIndicator(
 onRefresh: () async {
 await _loadCategories();
 await _loadProducts(q: _searchController.text);
 },
 child: CustomScrollView(
 slivers: [
 SliverToBoxAdapter(
 child: Padding(
 padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Branch (Sucursal) selector with live stock filtering
 _buildSucursalesSelector(colorScheme),
 const SizedBox(height: 10),

 // Search bar
 TextField(
 controller: _searchController,
 decoration: InputDecoration(
 hintText: 'Buscar prendas en el catálogo...',
 prefixIcon: const Icon(Icons.search),
 suffixIcon: _isSearching
 ? const SizedBox(
 width: 20,
 height: 20,
 child: CircularProgressIndicator(strokeWidth: 2),
 )
 : (_searchController.text.isEmpty
 ? null
 : IconButton(
 icon: const Icon(Icons.close),
 onPressed: () {
 _searchController.clear();
 _handleSearch('');
 },
 )),
 ),
 onSubmitted: _handleSearch,
 ),
 const SizedBox(height: 14),

 // Integrated Horizontal Category Filter Bar
 _buildCategoriesFilterBar(colorScheme),

 const SizedBox(height: 10),

 // Quick AI Assistant Discovery Banner
 InkWell(
 onTap: _navigateToAsistenteIA,
 borderRadius: BorderRadius.circular(12),
 child: Container(
 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
 decoration: BoxDecoration(
 gradient: LinearGradient(
 colors: [
 const Color(0xFF7C3AED).withValues(alpha: 0.08),
 const Color(0xFF4F46E5).withValues(alpha: 0.05),
 ],
 ),
 borderRadius: BorderRadius.circular(12),
 border: Border.all(
 color: const Color(0xFF7C3AED).withValues(alpha: 0.22),
 ),
 ),
 child: const Row(
 children: [
 Icon(Icons.auto_awesome, size: 16, color: Color(0xFF7C3AED)),
 SizedBox(width: 8),
 Expanded(
 child: Text(
 '¿Buscas una combinación u outfit? Consulta a Attention AI',
 style: TextStyle(
 fontSize: 12,
 fontWeight: FontWeight.w600,
 color: Color(0xFF7C3AED),
 ),
 ),
 ),
 Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF7C3AED)),
 ],
 ),
 ),
 ),

 const SizedBox(height: 10),

 // Results count and active filter indicator
 Row(
 children: [
 Text(
 '$_total prendas encontradas',
 style: textTheme.bodySmall?.copyWith(
 color: colorScheme.onSurface.withValues(alpha: 0.7),
 fontWeight: FontWeight.w600,
 ),
 ),
 if (_categoriaSeleccionada != null) ...[
 const SizedBox(width: 6),
 Container(
 padding: const EdgeInsets.symmetric(
 horizontal: 8,
 vertical: 2,
 ),
 decoration: BoxDecoration(
 color: colorScheme.primary.withValues(alpha: 0.1),
 borderRadius: BorderRadius.circular(10),
 ),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Text(
 _categoriaSeleccionada!.nombre,
 style: TextStyle(
 fontSize: 11,
 fontWeight: FontWeight.bold,
 color: colorScheme.primary,
 ),
 ),
 const SizedBox(width: 4),
 InkWell(
 onTap: () => _onCategorySelected(null),
 child: Icon(
 Icons.close,
 size: 13,
 color: colorScheme.primary,
 ),
 ),
 ],
 ),
 ),
 ],
 ],
 ),
 const SizedBox(height: 6),
 ],
 ),
 ),
 ),

 // Promotional banner linking to Tab 2
 SliverToBoxAdapter(
 child: PromocionesBannerSection(
 onVerPromociones: () => widget.onNavigateToTab(2),
 ),
 ),

 // Async states
 if (_isLoading)
 const SliverFillRemaining(
 child: LoadingView(
 message: 'Cargando catálogo de moda Attention...',
 ),
 )
 else if (_error != null)
 SliverFillRemaining(
 child: ErrorRetryView(
 title: 'No se pudieron cargar las prendas',
 message: _error!,
 onRetry: () {
 setState(() => _isLoading = true);
 _loadProducts(q: _searchController.text);
 },
 ),
 )
 else if (_productos.isEmpty)
 SliverFillRemaining(
 child: EmptyView(
 icon: Icons.checkroom_outlined,
 title: 'No encontramos prendas',
 message: _searchController.text.isNotEmpty
 ? 'No hay productos que coincidan con "${_searchController.text}". Prueba buscando otra categoría o prenda.'
 : (_categoriaSeleccionada != null
 ? 'No hay prendas disponibles en la categoría "${_categoriaSeleccionada!.nombre}".'
 : 'Actualmente no hay prendas disponibles en el catálogo.'),
 actionLabel: _searchController.text.isNotEmpty ||
 _categoriaSeleccionada != null
 ? 'Restablecer filtros'
 : null,
 onAction: _searchController.text.isNotEmpty ||
 _categoriaSeleccionada != null
 ? () {
 _searchController.clear();
 _onCategorySelected(null);
 }
 : null,
 ),
 )
 else
 SliverPadding(
 padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
 sliver: SliverGrid(
 gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
 maxCrossAxisExtent: 250,
 mainAxisSpacing: 12,
 crossAxisSpacing: 12,
 childAspectRatio: 0.72,
 ),
 delegate: SliverChildBuilderDelegate(
 (context, index) {
 final p = _productos[index];
 return _ProductCard(
 producto: p,
 descuento: _mejorDescuento,
 onTap: () => _openProductDetail(p),
 );
 },
 childCount: _productos.length,
 ),
 ),
 ),
 ],
 ),
 ),
 floatingActionButton: FloatingActionButton.extended(
 onPressed: () => widget.onNavigateToTab(3),
 backgroundColor: Colors.purple.shade700,
 foregroundColor: Colors.white,
 icon: const Icon(Icons.auto_awesome_rounded),
 label: const Text(
 'Probador IA',
 style: TextStyle(fontWeight: FontWeight.bold),
 ),
 ),
 );
 }

 /// Selector de sucursal física para consulta de stock independiente en tiempo real.
 Widget _buildSucursalesSelector(ColorScheme colorScheme) {
 return Container(
 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
 decoration: BoxDecoration(
 color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
 borderRadius: BorderRadius.circular(12),
 border: Border.all(
 color: colorScheme.outline.withValues(alpha: 0.15),
 ),
 ),
 child: Row(
 children: [
 Icon(Icons.storefront_rounded, size: 18, color: colorScheme.primary),
 const SizedBox(width: 8),
 Text(
 'Sucursal:',
 style: TextStyle(
 fontSize: 12,
 fontWeight: FontWeight.bold,
 color: colorScheme.onSurface,
 ),
 ),
 const SizedBox(width: 8),
 Expanded(
 child: DropdownButtonHideUnderline(
 child: DropdownButton<int?>(
 value: _sucursalSeleccionada?.codigoSucursal,
 isDense: true,
 isExpanded: true,
 icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
 items: [
 const DropdownMenuItem<int?>(
 value: null,
 child: Text(
 'Todas las sucursales (Inventario Global)',
 style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
 overflow: TextOverflow.ellipsis,
 ),
 ),
 ..._sucursales.map(
 (s) => DropdownMenuItem<int?>(
 value: s.codigoSucursal,
 child: Text(
 '${s.nombre} (${s.ciudad.nombre})',
 style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
 overflow: TextOverflow.ellipsis,
 ),
 ),
 ),
 ],
 onChanged: (int? cod) {
 setState(() {
 _sucursalSeleccionada = cod == null
 ? null
 : _sucursales.where((s) => s.codigoSucursal == cod).firstOrNull;
 _isLoading = true;
 });
 _loadProducts(
 q: _searchController.text,
 idCategoria: _categoriaSeleccionada?.idCategoria,
 );
 },
 ),
 ),
 ),
 ],
 ),
 );
 }

 /// Horizontal scrolling category selector integrated seamlessly in catalog.
 Widget _buildCategoriesFilterBar(ColorScheme colorScheme) {
 final isAllSelected = _categoriaSeleccionada == null;

 return SingleChildScrollView(
 scrollDirection: Axis.horizontal,
 child: Row(
 children: [
 // "Todas" chip
 FilterChip(
 selected: isAllSelected,
 showCheckmark: false,
 avatar: Icon(
 Icons.grid_view_rounded,
 size: 16,
 color: isAllSelected ? colorScheme.onPrimary : colorScheme.primary,
 ),
 label: const Text(
 'Todas',
 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
 ),
 selectedColor: colorScheme.primary,
 labelStyle: TextStyle(
 color: isAllSelected ? colorScheme.onPrimary : colorScheme.onSurface,
 ),
 backgroundColor: colorScheme.surface,
 shape: RoundedRectangleBorder(
 borderRadius: BorderRadius.circular(20),
 side: BorderSide(
 color: isAllSelected
 ? Colors.transparent
 : colorScheme.outline.withValues(alpha: 0.25),
 ),
 ),
 onSelected: (_) => _onCategorySelected(null),
 ),
 const SizedBox(width: 8),

 // Dynamic category chips loaded from API
 for (final cat in _categorias) ...[
 Builder(
 builder: (context) {
 final isSelected =
 _categoriaSeleccionada?.idCategoria == cat.idCategoria;
 return Padding(
 padding: const EdgeInsets.only(right: 8),
 child: FilterChip(
 selected: isSelected,
 showCheckmark: false,
 label: Text(
 cat.nombre,
 style: TextStyle(
 fontSize: 13,
 fontWeight:
 isSelected ? FontWeight.bold : FontWeight.w500,
 ),
 ),
 selectedColor: colorScheme.primary,
 labelStyle: TextStyle(
 color: isSelected
 ? colorScheme.onPrimary
 : colorScheme.onSurface,
 ),
 backgroundColor: colorScheme.surface,
 shape: RoundedRectangleBorder(
 borderRadius: BorderRadius.circular(20),
 side: BorderSide(
 color: isSelected
 ? Colors.transparent
 : colorScheme.outline.withValues(alpha: 0.25),
 ),
 ),
 onSelected: (_) => _onCategorySelected(cat),
 ),
 );
 },
 ),
 ],
 ],
 ),
 );
 }
}

/// Tarjeta minimalista de producto para el grid móvil:
/// Muestra estrictamente lo esencial: Foto + Badge de Promoción, Nombre y Precio con descuento.
class _ProductCard extends StatelessWidget {
 const _ProductCard({
 required this.producto,
 required this.onTap,
 this.descuento,
 });

 final Producto producto;
 final VoidCallback onTap;
 final DescuentoModel? descuento;

 double get precioFinal {
 if (descuento != null && descuento!.activo) {
 if (descuento!.esPorcentaje) {
 return (producto.precioVenta * (1.0 - (descuento!.valor / 100.0)))
 .clamp(0.0, double.infinity);
 } else {
 return (producto.precioVenta - descuento!.valor)
 .clamp(0.0, double.infinity);
 }
 }
 return producto.precioVenta;
 }

 @override
 Widget build(BuildContext context) {
 final colorScheme = Theme.of(context).colorScheme;
 final textTheme = Theme.of(context).textTheme;

 final hasImage = producto.imagenUrl != null &&
 producto.imagenUrl!.isNotEmpty &&
 producto.imagenUrl!.startsWith('http');

 final tieneDescuento = descuento != null && precioFinal < producto.precioVenta;

 return Card(
 clipBehavior: Clip.antiAlias,
 elevation: 0.8,
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
 child: InkWell(
 onTap: onTap,
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.stretch,
 children: [
 // Imagen de la prenda con badge de oferta si aplica
 Expanded(
 child: Stack(
 fit: StackFit.expand,
 children: [
 hasImage
 ? Image.network(
 producto.imagenUrl!,
 fit: BoxFit.cover,
 errorBuilder: (_, _, _) => _imagePlaceholder(context),
 )
 : _imagePlaceholder(context),
 if (tieneDescuento)
 Positioned(
 top: 8,
 right: 8,
 child: Container(
 padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
 decoration: BoxDecoration(
 color: Colors.red.shade700,
 borderRadius: BorderRadius.circular(8),
 boxShadow: [
 BoxShadow(
 color: Colors.black.withAlpha(50),
 blurRadius: 4,
 ),
 ],
 ),
 child: Text(
 descuento!.badgeTexto,
 style: const TextStyle(
 color: Colors.white,
 fontSize: 10,
 fontWeight: FontWeight.bold,
 ),
 ),
 ),
 ),
 ],
 ),
 ),
 // Detalles esenciales: Nombre y Precio (con descuento o regular)
 Padding(
 padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 producto.nombre,
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 style: textTheme.titleSmall?.copyWith(
 fontWeight: FontWeight.w600,
 ),
 ),
 const SizedBox(height: 4),
 if (tieneDescuento) ...[
 Row(
 crossAxisAlignment: CrossAxisAlignment.baseline,
 textBaseline: TextBaseline.alphabetic,
 children: [
 Text(
 'Bs ${precioFinal.toStringAsFixed(2)}',
 style: textTheme.titleSmall?.copyWith(
 color: colorScheme.primary,
 fontWeight: FontWeight.bold,
 ),
 ),
 const SizedBox(width: 6),
 Text(
 'Bs ${producto.precioVenta.toStringAsFixed(2)}',
 style: TextStyle(
 decoration: TextDecoration.lineThrough,
 color: colorScheme.outline,
 fontSize: 11,
 ),
 ),
 ],
 ),
 ] else ...[
 Text(
 'Bs ${producto.precioVenta.toStringAsFixed(2)}',
 style: textTheme.titleSmall?.copyWith(
 color: colorScheme.primary,
 fontWeight: FontWeight.bold,
 ),
 ),
 ],
 ],
 ),
 ),
 ],
 ),
 ),
 );
 }

 Widget _imagePlaceholder(BuildContext context) {
 final colorScheme = Theme.of(context).colorScheme;
 return Container(
 color: colorScheme.primaryContainer.withValues(alpha: 0.2),
 child: Icon(
 Icons.checkroom_outlined,
 size: 48,
 color: colorScheme.onPrimaryContainer.withValues(alpha: 0.6),
 ),
 );
 }
}

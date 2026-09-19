import 'package:flutter/material.dart';

import '../../../../core/storage/secure_storage_service.dart';
import '../../../auth/data/auth_service.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../branches/presentation/screens/sucursales_screen.dart';
import '../../../cart/logic/cart_service.dart';
import '../../../cart/presentation/screens/cart_screen.dart';
import '../../../categories/presentation/screens/categorias_screen.dart';
import '../../../reservations/presentation/screens/reservas_screen.dart';
import '../../../tallas/presentation/screens/tallas_screen.dart';
import '../../data/productos_service.dart';
import '../widgets/product_detail_sheet.dart';

/// Clients-only home screen: catalog (CU6) with full navigation drawer and
/// quick-access module cards reflecting all mobile Use Cases.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Producto> _productos = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String? _error;
  int _total = 0;
  Map<String, dynamic>? _session;

  @override
  void initState() {
    super.initState();
    CartService.instance.init();
    _loadSession();
    _loadProducts();
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

  Future<void> _loadProducts({String? q}) async {
    final result = await ProductosService.listar(q: q, limit: 50);

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

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas salir de tu cuenta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  /// Displays an informative dialog for modules currently under development.
  void _showComingSoonDialog({
    required String title,
    required String cu,
    required String description,
    required IconData icon,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: colorScheme.primary),
          ),
          title: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.shade400),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: Colors.amber.shade900,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Módulo en desarrollo - Próximamente',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.75),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Identificador del sistema: $cu',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.outline,
                ),
              ),
            ],
          ),
          actions: [
            Center(
              child: FilledButton.tonal(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Entendido'),
              ),
            ),
          ],
        );
      },
    );
  }

  void _navigateToSucursales() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SucursalesScreen()),
    );
  }

  void _navigateToCategorias() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CategoriasScreen()),
    );
  }

  void _navigateToTallas() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TallasScreen()),
    );
  }

  void _navigateToCart() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );
  }

  void _navigateToReservas() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ReservasScreen()),
    );
  }

  void _openProductDetail(Producto producto) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ProductDetailSheet(producto: producto),
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
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesión',
            onPressed: _handleLogout,
          ),
        ],
      ),
      drawer: _buildNavigationDrawer(context),
      body: RefreshIndicator(
        onRefresh: () => _loadProducts(q: _searchController.text),
        child: CustomScrollView(
          slivers: [
            // Quick Access Actions Carousel / Row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: _handleSearch,
                    ),
                    const SizedBox(height: 14),

                    // Quick access shortcuts row with active client modules
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _QuickActionChip(
                            icon: Icons.shopping_bag_rounded,
                            label: 'Mi Carrito (CU15)',
                            isPrimary: true,
                            onTap: _navigateToCart,
                          ),
                          const SizedBox(width: 8),
                          _QuickActionChip(
                            icon: Icons.bookmark_added_rounded,
                            label: 'Mis Reservas (CU14)',
                            isPrimary: true,
                            onTap: _navigateToReservas,
                          ),
                          const SizedBox(width: 8),
                          _QuickActionChip(
                            icon: Icons.store_mall_directory_rounded,
                            label: 'Sucursales (CU17)',
                            onTap: _navigateToSucursales,
                          ),
                          const SizedBox(width: 8),
                          _QuickActionChip(
                            icon: Icons.category_rounded,
                            label: 'Categorías (CU9)',
                            onTap: _navigateToCategorias,
                          ),
                          const SizedBox(width: 8),
                          _QuickActionChip(
                            icon: Icons.straighten_rounded,
                            label: 'Tallas (CU7)',
                            onTap: _navigateToTallas,
                          ),
                          const SizedBox(width: 8),
                          _QuickActionChip(
                            icon: Icons.view_in_ar_rounded,
                            label: 'Probador AR (CU8)',
                            onTap: () => _showComingSoonDialog(
                              title: 'Probador Virtual AR',
                              cu: 'CU8',
                              description:
                                  'Prueba ropa en tiempo real sobre tu modelo 3D o cámara utilizando Realidad Aumentada.',
                              icon: Icons.view_in_ar_rounded,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _QuickActionChip(
                            icon: Icons.auto_awesome_rounded,
                            label: 'Asistente IA (CU25)',
                            onTap: () => _showComingSoonDialog(
                              title: 'Asistente de Moda IA',
                              cu: 'CU25',
                              description:
                                  'Recomendador inteligente de outfits y combinaciones basado en tu estilo y ocasión.',
                              icon: Icons.auto_awesome_rounded,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Results count
                    Text(
                      '$_total prendas disponibles para compra y reserva',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(32),
                  children: [
                    Icon(
                      Icons.cloud_off_outlined,
                      size: 56,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        setState(() => _isLoading = true);
                        _loadProducts(q: _searchController.text);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              )
            else if (_productos.isEmpty)
              SliverFillRemaining(
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(32),
                  children: [
                    Icon(
                      Icons.checkroom_outlined,
                      size: 56,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No encontramos prendas con ese criterio.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge,
                    ),
                  ],
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 250,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.62,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final p = _productos[index];
                      return _ProductCard(
                        producto: p,
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
        onPressed: () => _showComingSoonDialog(
          title: 'Probador Virtual AR',
          cu: 'CU8',
          description:
              'Visualiza prendas en tiempo real sobre tu imagen con Realidad Aumentada.',
          icon: Icons.face_retouching_natural_outlined,
        ),
        icon: const Icon(Icons.face_retouching_natural_outlined),
        label: const Text('Probador AR'),
      ),
    );
  }

  /// Complete Drawer Navigation reflecting all Mobile Use Cases organized
  /// into logical business categories for the Client role.
  Widget _buildNavigationDrawer(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final nombre = (_session?['nombre'] as String?) ?? 'Cliente Attention';
    final correo = (_session?['correo'] as String?) ?? 'cliente@attention.com';

    return Drawer(
      child: Column(
        children: [
          // Drawer Header with user profile info
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: colorScheme.primary,
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: colorScheme.onPrimary,
              child: Text(
                nombre.isNotEmpty ? nombre[0].toUpperCase() : 'A',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
            accountName: Text(
              nombre,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: Row(
              children: [
                Expanded(
                  child: Text(
                    correo,
                    style: TextStyle(
                      color: colorScheme.onPrimary.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Cliente Móvil',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable list of modules
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // SECTION 1: MÓDULOS ACTIVOS DEL CLIENTE
                _buildSectionHeader('MÓDULOS ACTIVOS (CLIENTE)'),
                ListTile(
                  leading: Icon(
                    Icons.storefront_rounded,
                    color: colorScheme.primary,
                  ),
                  title: const Text(
                    'Catálogo de Prendas',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('CU6 • Consulta y búsqueda de productos'),
                  trailing: _buildActiveBadge(),
                  selected: true,
                  selectedTileColor:
                      colorScheme.primaryContainer.withValues(alpha: 0.25),
                  onTap: () => Navigator.of(context).pop(),
                ),
                ListenableBuilder(
                  listenable: CartService.instance,
                  builder: (context, _) {
                    final count = CartService.instance.totalItemCount;
                    return ListTile(
                      leading: Icon(
                        Icons.shopping_bag_rounded,
                        color: colorScheme.primary,
                      ),
                      title: const Text(
                        'Carrito de Compras',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('CU15/CU21 • $count prendas añadidas'),
                      trailing: _buildActiveBadge(),
                      onTap: () {
                        Navigator.of(context).pop();
                        _navigateToCart();
                      },
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.bookmark_added_rounded,
                    color: colorScheme.primary,
                  ),
                  title: const Text(
                    'Mis Reservas de Prendas',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('CU14 • Apartar y recoger en sucursal'),
                  trailing: _buildActiveBadge(),
                  onTap: () {
                    Navigator.of(context).pop();
                    _navigateToReservas();
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.store_mall_directory_rounded,
                    color: colorScheme.primary,
                  ),
                  title: const Text(
                    'Nuestras Sucursales',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('CU17 • Ubicaciones y horarios reales'),
                  trailing: _buildActiveBadge(),
                  onTap: () {
                    Navigator.of(context).pop();
                    _navigateToSucursales();
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.category_rounded,
                    color: colorScheme.primary,
                  ),
                  title: const Text(
                    'Categorías de Prendas',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('CU9 • Exploración por líneas de moda'),
                  trailing: _buildActiveBadge(),
                  onTap: () {
                    Navigator.of(context).pop();
                    _navigateToCategorias();
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.straighten_rounded,
                    color: colorScheme.primary,
                  ),
                  title: const Text(
                    'Tallas y Variantes',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('CU7 • Guía de medidas y colores'),
                  trailing: _buildActiveBadge(),
                  onTap: () {
                    Navigator.of(context).pop();
                    _navigateToTallas();
                  },
                ),

                const Divider(height: 24),

                // SECTION 2: INNOVACIÓN E INTELIGENCIA ARTIFICIAL
                _buildSectionHeader('INNOVACIÓN & IA'),
                _buildPlaceholderTile(
                  title: 'Probador Virtual AR',
                  cu: 'CU8',
                  subtitle: 'Pruébate ropa en 3D con Realidad Aumentada',
                  icon: Icons.view_in_ar_rounded,
                  badgeLabel: 'Próximamente AR',
                  description:
                      'Experimenta el probador virtual con superposición de prendas 3D sobre tu cuerpo mediante la cámara del móvil.',
                ),
                _buildPlaceholderTile(
                  title: 'Asistente de Moda IA',
                  cu: 'CU25',
                  subtitle: 'Recomendaciones personalizadas de estilo',
                  icon: Icons.auto_awesome_rounded,
                  badgeLabel: 'Próximamente IA',
                  description:
                      'Interactúa con un modelo de Inteligencia Artificial para recibir sugerencias de outfits y combinaciones ideales según tu tipo de evento.',
                ),

                const Divider(height: 24),

                // SECTION 3: OTROS SERVICIOS
                _buildSectionHeader('EN ENVÍOS Y CUENTA'),
                _buildPlaceholderTile(
                  title: 'Seguimiento de Envíos',
                  cu: 'CU18',
                  subtitle: 'Rastreo de delivery en tiempo real',
                  icon: Icons.local_shipping_rounded,
                  description:
                      'Monitorea la ruta del repartidor y el estado de entrega de tus compras directamente en el mapa.',
                ),
                _buildPlaceholderTile(
                  title: 'Notificaciones',
                  cu: 'CU10',
                  subtitle: 'Alertas de ofertas, pedidos y reservas',
                  icon: Icons.notifications_none_rounded,
                  description:
                      'Bandeja de avisos en tiempo real sobre confirmaciones de reserva, envíos y descuentos exclusivos.',
                ),

                const Divider(height: 16),

                ListTile(
                  leading: Icon(
                    Icons.logout_rounded,
                    color: colorScheme.error,
                  ),
                  title: Text(
                    'Cerrar Sesión',
                    style: TextStyle(
                      color: colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text('Salir de la cuenta en este dispositivo'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _handleLogout();
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Text(
        'Activo',
        style: TextStyle(
          color: Colors.green.shade800,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }

  Widget _buildPlaceholderTile({
    required String title,
    required String cu,
    required String subtitle,
    required IconData icon,
    required String description,
    String badgeLabel = 'Próximamente',
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(
        icon,
        color: colorScheme.onSurface.withValues(alpha: 0.7),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      subtitle: Text(
        '$cu • $subtitle',
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.shade300),
        ),
        child: Text(
          badgeLabel,
          style: TextStyle(
            color: Colors.amber.shade900,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      onTap: () {
        Navigator.of(context).pop();
        _showComingSoonDialog(
          title: title,
          cu: cu,
          description: description,
          icon: icon,
        );
      },
    );
  }
}

/// Compact chip widget for horizontal quick-actions row
class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ActionChip(
      avatar: Icon(
        icon,
        size: 16,
        color: isPrimary ? colorScheme.onPrimary : colorScheme.primary,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isPrimary ? FontWeight.bold : FontWeight.w500,
          color: isPrimary ? colorScheme.onPrimary : colorScheme.onSurface,
        ),
      ),
      backgroundColor: isPrimary ? colorScheme.primary : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isPrimary
              ? Colors.transparent
              : colorScheme.outline.withValues(alpha: 0.25),
        ),
      ),
      onPressed: onTap,
    );
  }
}

/// Catalog card for a product (image, name, price, tallas, colores).
class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.producto, required this.onTap});

  final Producto producto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final hasImage = producto.imagenUrl != null &&
        producto.imagenUrl!.isNotEmpty &&
        producto.imagenUrl!.startsWith('http');

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: hasImage
                  ? Image.network(
                      producto.imagenUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _imagePlaceholder(context),
                    )
                  : _imagePlaceholder(context),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  if (producto.tallas.isNotEmpty) ...[
                    Text(
                      'Tallas: ${producto.tallas.join(', ')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Row(
                    children: [
                      if (producto.colores.isNotEmpty) ...[
                        for (final c in producto.colores.take(4))
                          Container(
                            margin: const EdgeInsets.only(right: 4),
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: _parseColor(c.hex),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    colorScheme.outline.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        const SizedBox(width: 4),
                      ],
                      const Spacer(),
                      Text(
                        'Bs ${producto.precioVenta.toStringAsFixed(2)}',
                        style: textTheme.titleSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
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
      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Icon(
        Icons.checkroom_outlined,
        size: 48,
        color: colorScheme.onPrimaryContainer.withValues(alpha: 0.6),
      ),
    );
  }

  /// Parses '#RRGGBB' hex strings; white fallback for missing/invalid.
  Color _parseColor(String? hex) {
    if (hex == null) return Colors.white;
    var value = hex.replaceAll('#', '').trim();
    if (value.length == 6) {
      value = 'FF$value';
    }
    final parsed = int.tryParse(value, radix: 16);
    if (parsed == null) return Colors.white;
    return Color(parsed);
  }
}

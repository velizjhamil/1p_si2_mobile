import 'package:flutter/material.dart';

import '../services/productos_service.dart';
import '../services/secure_storage_service.dart';
import 'login_screen.dart';

/// Clients-only home screen: the product catalog (CU6) shown right after
/// login, with a personalized greeting and logout.
///
/// Feature cards (Probador, Reservas, Mis Compras) live in the drawer
/// until their screens exist.
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
    await SecureStorageService.clearAll();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showComingSoon(String title) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$title estará disponible próximamente'),
          behavior: SnackBarBehavior.floating,
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
        title: Text(nombre.isEmpty ? 'Attention' : '¡Hola, $nombre!'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadProducts(q: _searchController.text),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar prendas...',
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onSubmitted: _handleSearch,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_total prendas disponibles',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                        onTap: () => _showComingSoon(p.nombre),
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
        onPressed: () => _showComingSoon('Probador Virtual'),
        icon: const Icon(Icons.face_retouching_natural_outlined),
        label: const Text('Probador'),
      ),
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
                                color: colorScheme.outline.withValues(alpha: 0.3),
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

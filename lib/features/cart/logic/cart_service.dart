import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../data/cart_item.dart';

/// Singleton and reactive CartService for managing client items,
/// calculating subtotals, applying Attention free-shipping rules,
/// and persisting cart state.
class CartService extends ChangeNotifier {
  CartService._();

  static final CartService instance = CartService._();

  final List<CartItem> _items = [];
  bool _initialized = false;

  static const String _storageKey = 'attention_client_cart_v1';
  static const double envioGratisDesde = 300.0;
  static const double costoEnvioFijo = 25.0;

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalItemCount => _items.fold(0, (sum, item) => sum + item.cantidad);

  double get subtotal =>
      _items.fold(0.0, (sum, item) => sum + item.subtotal);

  double get costoEnvio =>
      (subtotal >= envioGratisDesde || _items.isEmpty) ? 0.0 : costoEnvioFijo;

  double get total => subtotal + costoEnvio;

  bool get isEnvioGratis => subtotal >= envioGratisDesde && _items.isNotEmpty;

  /// Loads persisted cart on startup
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final jsonStr = await SecureStorageService.storage.read(key: _storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr);
        if (decoded is List) {
          _items.clear();
          for (final raw in decoded) {
            if (raw is Map<String, dynamic>) {
              _items.add(CartItem.fromJson(raw));
            }
          }
          notifyListeners();
        }
      }
    } catch (_) {
      // Non-fatal if storage read fails
    }
  }

  Future<void> _persist() async {
    try {
      final jsonStr = jsonEncode(_items.map((i) => i.toJson()).toList());
      await SecureStorageService.storage.write(key: _storageKey, value: jsonStr);
    } catch (_) {
      // Non-fatal
    }
  }

  /// Adds an item to the cart or increments quantity if matching key exists.
  void addItem({
    required int idProducto,
    required String nombre,
    required double precioUnitario,
    required int cantidad,
    String? talla,
    String? color,
    String? imagenUrl,
  }) {
    final key = '$idProducto-${talla ?? ""}-${color ?? ""}';
    final existingIndex = _items.indexWhere((i) => i.itemKey == key);

    if (existingIndex >= 0) {
      _items[existingIndex].cantidad += cantidad;
    } else {
      _items.add(
        CartItem(
          idProducto: idProducto,
          nombre: nombre,
          precioUnitario: precioUnitario,
          cantidad: cantidad,
          talla: talla,
          color: color,
          imagenUrl: imagenUrl,
        ),
      );
    }

    _persist();
    notifyListeners();
  }

  void updateQuantity(CartItem item, int delta) {
    final index = _items.indexOf(item);
    if (index >= 0) {
      final newQty = _items[index].cantidad + delta;
      if (newQty <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].cantidad = newQty;
      }
      _persist();
      notifyListeners();
    }
  }

  void removeItem(CartItem item) {
    _items.remove(item);
    _persist();
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _persist();
    notifyListeners();
  }
}

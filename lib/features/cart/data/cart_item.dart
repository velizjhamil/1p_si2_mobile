/// Model representing an item in the client shopping cart.
///
/// Composite key: [idProducto] + [talla] + [color].
class CartItem {
  CartItem({
    required this.idProducto,
    required this.nombre,
    required this.precioUnitario,
    required this.cantidad,
    this.talla,
    this.color,
    this.imagenUrl,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        idProducto: json['id_producto'] as int? ?? 0,
        nombre: json['nombre'] as String? ?? '',
        precioUnitario: (json['precio_unitario'] as num?)?.toDouble() ?? 0.0,
        cantidad: json['cantidad'] as int? ?? 1,
        talla: json['talla'] as String?,
        color: json['color'] as String?,
        imagenUrl: json['imagen_url'] as String?,
      );

  final int idProducto;
  final String nombre;
  final double precioUnitario;
  int cantidad;
  final String? talla;
  final String? color;
  final String? imagenUrl;

  /// Unique composite identifier for cart item aggregation
  String get itemKey => '$idProducto-${talla ?? ""}-${color ?? ""}';

  double get subtotal => precioUnitario * cantidad;

  Map<String, dynamic> toJson() => {
        'id_producto': idProducto,
        'nombre': nombre,
        'precio_unitario': precioUnitario,
        'cantidad': cantidad,
        'talla': talla,
        'color': color,
        'imagen_url': imagenUrl,
      };
}

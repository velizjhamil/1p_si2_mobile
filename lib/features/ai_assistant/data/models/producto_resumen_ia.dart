import '../../../catalog/data/productos_service.dart';

/// Representation of a color option returned by the AI assistant.
class ColorResumenIA {
 const ColorResumenIA({
 required this.nombreColor,
 this.codigoHex,
 });

 factory ColorResumenIA.fromJson(Map<String, dynamic> json) {
 return ColorResumenIA(
 nombreColor: json['nombre_color'] as String? ?? 'Único',
 codigoHex: json['codigo_hex'] as String?,
 );
 }

 final String nombreColor;
 final String? codigoHex;
}

/// Compact product model returned in the `productos_detalle` payload of `/api/v1/ia/chat`.
///
/// Tailored for fast visual card rendering directly under assistant chat bubbles.
class ProductoResumenIA {
 const ProductoResumenIA({
 required this.idProducto,
 required this.nombre,
 required this.precioVenta,
 this.imagenUrl,
 this.categoria,
 this.linea,
 this.tallas = const [],
 this.colores = const [],
 this.stockTotal = 0,
 });

 factory ProductoResumenIA.fromJson(Map<String, dynamic> json) {
 final tallasRaw = json['tallas'];
 final coloresRaw = json['colores'];

 final List<String> tallas = tallasRaw is List
 ? tallasRaw.map((e) => e.toString()).toList()
 : const [];

 final List<ColorResumenIA> colores = coloresRaw is List
 ? coloresRaw
 .whereType<Map<String, dynamic>>()
 .map(ColorResumenIA.fromJson)
 .toList()
 : const [];

 return ProductoResumenIA(
 idProducto: (json['id_producto'] as num?)?.toInt() ?? 0,
 nombre: json['nombre'] as String? ?? '',
 precioVenta: (json['precio_venta'] as num?)?.toDouble() ?? 0.0,
 imagenUrl: json['imagen_url'] as String?,
 categoria: json['categoria'] as String?,
 linea: json['linea'] as String?,
 tallas: tallas,
 colores: colores,
 stockTotal: (json['stock_total'] as num?)?.toInt() ?? 0,
 );
 }

 final int idProducto;
 final String nombre;
 final double precioVenta;
 final String? imagenUrl;
 final String? categoria;
 final String? linea;
 final List<String> tallas;
 final List<ColorResumenIA> colores;
 final int stockTotal;

 /// Converts this AI summary into the standard [Producto] model
 /// used by [ProductDetailSheet] and the shopping cart.
 Producto toProducto() {
 return Producto(
 idProducto: idProducto,
 nombre: nombre,
 precioVenta: precioVenta,
 imagenUrl: imagenUrl,
 descripcion: categoria != null ? 'Prenda en categoría $categoria' : null,
 estado: 'Activo',
 tallas: tallas,
 colores: colores
 .map((c) => ColorDto(nombre: c.nombreColor, hex: c.codigoHex))
 .toList(),
 );
 }
}

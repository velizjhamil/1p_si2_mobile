import 'package:flutter/material.dart';

import '../../../catalog/presentation/widgets/product_detail_sheet.dart';
import '../../data/models/producto_resumen_ia.dart';

/// Horizontal carousel displaying interactive product recommendation cards
/// directly below an AI assistant message bubble.
class IAProductCarousel extends StatelessWidget {
 const IAProductCarousel({
 super.key,
 required this.productos,
 });

 final List<ProductoResumenIA> productos;

 void _abrirDetalle(BuildContext context, ProductoResumenIA item) {
 showModalBottomSheet(
 context: context,
 isScrollControlled: true,
 backgroundColor: Colors.transparent,
 builder: (_) => ProductDetailSheet(producto: item.toProducto()),
 );
 }

 @override
 Widget build(BuildContext context) {
 if (productos.isEmpty) return const SizedBox.shrink();

 final theme = Theme.of(context);
 final isDark = theme.brightness == Brightness.dark;

 return Container(
 margin: const EdgeInsets.only(top: 8, bottom: 4),
 height: 236,
 child: ListView.separated(
 scrollDirection: Axis.horizontal,
 clipBehavior: Clip.none,
 padding: const EdgeInsets.symmetric(horizontal: 4),
 itemCount: productos.length,
 separatorBuilder: (context, index) => const SizedBox(width: 12),
 itemBuilder: (context, index) {
 final item = productos[index];
 return _buildProductCard(context, item, isDark);
 },
 ),
 );
 }

 Widget _buildProductCard(BuildContext context, ProductoResumenIA item, bool isDark) {
 return Container(
 width: 172,
 decoration: BoxDecoration(
 color: isDark ? const Color(0xFF1E293B) : Colors.white,
 borderRadius: BorderRadius.circular(16),
 border: Border.all(
 color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
 width: 1,
 ),
 boxShadow: [
 BoxShadow(
 color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
 blurRadius: 8,
 offset: const Offset(0, 3),
 ),
 ],
 ),
 child: Material(
 color: Colors.transparent,
 child: InkWell(
 borderRadius: BorderRadius.circular(16),
 onTap: () => _abrirDetalle(context, item),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Image thumbnail with category badge
 Stack(
 children: [
 ClipRRect(
 borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
 child: Container(
 height: 108,
 width: double.infinity,
 color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
 child: item.imagenUrl != null && item.imagenUrl!.isNotEmpty
 ? Image.network(
 item.imagenUrl!,
 fit: BoxFit.cover,
 errorBuilder: (context, error, stackTrace) => _buildPlaceholder(isDark),
 )
 : _buildPlaceholder(isDark),
 ),
 ),
 if (item.categoria != null && item.categoria!.isNotEmpty)
 Positioned(
 top: 6,
 left: 6,
 child: Container(
 padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
 decoration: BoxDecoration(
 color: Colors.black.withValues(alpha: 0.68),
 borderRadius: BorderRadius.circular(8),
 ),
 child: Text(
 item.categoria!,
 style: const TextStyle(
 color: Colors.white,
 fontSize: 10,
 fontWeight: FontWeight.w600,
 ),
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 ),
 ),
 ),
 ],
 ),

 // Product Info Body
 Padding(
 padding: const EdgeInsets.all(10),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Title
 Text(
 item.nombre,
 style: TextStyle(
 fontSize: 13,
 fontWeight: FontWeight.w600,
 height: 1.2,
 color: isDark ? Colors.white : const Color(0xFF1E293B),
 ),
 maxLines: 2,
 overflow: TextOverflow.ellipsis,
 ),
 const SizedBox(height: 4),

 // Sizes & Colors Summary
 Row(
 children: [
 if (item.tallas.isNotEmpty)
 Expanded(
 child: Text(
 'Tallas: ${item.tallas.join(", ")}',
 style: TextStyle(
 fontSize: 10.5,
 color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
 ),
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 ),
 )
 else
 Expanded(
 child: Text(
 'Prenda disponible',
 style: TextStyle(
 fontSize: 10.5,
 color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
 ),
 ),
 ),
 ],
 ),
 const SizedBox(height: 6),

 // Price and Action Button
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 crossAxisAlignment: CrossAxisAlignment.center,
 children: [
 Text(
 'Bs ${item.precioVenta.toStringAsFixed(2)}',
 style: TextStyle(
 fontSize: 13.5,
 fontWeight: FontWeight.bold,
 color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF7C3AED),
 ),
 ),
 Container(
 padding: const EdgeInsets.all(4),
 decoration: BoxDecoration(
 color: isDark
 ? const Color(0xFF7C3AED).withValues(alpha: 0.2)
 : const Color(0xFF7C3AED).withValues(alpha: 0.1),
 shape: BoxShape.circle,
 ),
 child: const Icon(
 Icons.arrow_forward_rounded,
 size: 14,
 color: Color(0xFF7C3AED),
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
 ),
 );
 }

 Widget _buildPlaceholder(bool isDark) {
 return Center(
 child: Icon(
 Icons.checkroom_rounded,
 size: 36,
 color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
 ),
 );
 }
}

import 'package:flutter/material.dart';

import '../../../shipping/presentation/screens/seguimiento_envio_screen.dart';
import '../../data/compras_cliente_service.dart';

/// Pantalla de detalle de una compra específica seleccionada por el cliente.
class DetalleCompraScreen extends StatelessWidget {
 const DetalleCompraScreen({
 super.key,
 required this.compra,
 });

 final CompraClienteModel compra;

 @override
 Widget build(BuildContext context) {
 return Scaffold(
 appBar: AppBar(
 title: Text(
 compra.codigo,
 style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8),
 ),
 actions: [
 Padding(
 padding: const EdgeInsets.only(right: 16),
 child: Center(
 child: _buildStatusBadge(context),
 ),
 ),
 ],
 ),
 body: SingleChildScrollView(
 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.stretch,
 children: [
 // Status Header Banner
 _buildStatusHeader(context),
 const SizedBox(height: 16),

 // Order Metadata Card
 _buildOrderInfoCard(context),
 const SizedBox(height: 16),

 // Items breakdown Card
 _buildProductsCard(context),
 const SizedBox(height: 16),

 // Shipping / Delivery Card
 if (compra.datosEntrega != null) ...[
 _buildDeliveryCard(context),
 const SizedBox(height: 16),
 ],

 // Payment & Financial breakdown Card
 _buildFinancialSummaryCard(context),
 const SizedBox(height: 24),

 // Action Buttons
 FilledButton.icon(
 onPressed: () => Navigator.of(context).pop(),
 style: FilledButton.styleFrom(
 minimumSize: const Size.fromHeight(50),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
 ),
 icon: const Icon(Icons.arrow_back_rounded),
 label: const Text('Volver al Historial', style: TextStyle(fontWeight: FontWeight.bold)),
 ),
 const SizedBox(height: 8),
 TextButton.icon(
 onPressed: () {
 Navigator.of(context).popUntil((route) => route.isFirst);
 },
 icon: const Icon(Icons.storefront_rounded),
 label: const Text('Ir a la Tienda'),
 ),
 const SizedBox(height: 20),
 ],
 ),
 ),
 );
 }

 Widget _buildStatusHeader(BuildContext context) {
 final textTheme = Theme.of(context).textTheme;

 Color bg;
 Color border;
 Color iconColor;
 IconData icon;
 String title;
 String subtitle;

 if (compra.esCompletada) {
 bg = Colors.green.shade50;
 border = Colors.green.shade200;
 iconColor = Colors.green.shade700;
 icon = Icons.check_circle_rounded;
 title = '¡Compra Completada!';
 subtitle = 'El pago fue procesado y confirmado con éxito.';
 } else if (compra.esPendiente) {
 bg = Colors.amber.shade50;
 border = Colors.amber.shade200;
 iconColor = Colors.amber.shade800;
 icon = Icons.hourglass_top_rounded;
 title = 'Pago Pendiente';
 subtitle = 'Tu pedido está registrado y pendiente de confirmación de pago.';
 } else {
 bg = Colors.red.shade50;
 border = Colors.red.shade200;
 iconColor = Colors.red.shade700;
 icon = Icons.cancel_rounded;
 title = 'Compra Cancelada';
 subtitle = 'Esta orden fue anulada o el pago fue rechazado.';
 }

 return Container(
 padding: const EdgeInsets.all(16),
 decoration: BoxDecoration(
 color: bg,
 borderRadius: BorderRadius.circular(16),
 border: Border.all(color: border),
 ),
 child: Row(
 children: [
 Icon(icon, color: iconColor, size: 36),
 const SizedBox(width: 14),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 title,
 style: textTheme.titleMedium?.copyWith(
 fontWeight: FontWeight.bold,
 color: iconColor,
 ),
 ),
 const SizedBox(height: 2),
 Text(
 subtitle,
 style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
 ),
 ],
 ),
 ),
 ],
 ),
 );
 }

 Widget _buildStatusBadge(BuildContext context) {
 Color bg;
 Color fg;
 Color border;

 if (compra.esCompletada) {
 bg = Colors.green.shade50;
 fg = Colors.green.shade800;
 border = Colors.green.shade300;
 } else if (compra.esPendiente) {
 bg = Colors.amber.shade50;
 fg = Colors.amber.shade900;
 border = Colors.amber.shade300;
 } else {
 bg = Colors.red.shade50;
 fg = Colors.red.shade800;
 border = Colors.red.shade300;
 }

 return Container(
 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
 decoration: BoxDecoration(
 color: bg,
 borderRadius: BorderRadius.circular(8),
 border: Border.all(color: border),
 ),
 child: Text(
 compra.estadoLegible,
 style: TextStyle(
 color: fg,
 fontSize: 11,
 fontWeight: FontWeight.bold,
 ),
 ),
 );
 }

 Widget _buildOrderInfoCard(BuildContext context) {
 final colorScheme = Theme.of(context).colorScheme;
 final textTheme = Theme.of(context).textTheme;

 return Card(
 elevation: 1,
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
 child: Padding(
 padding: const EdgeInsets.all(16),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 children: [
 Icon(Icons.receipt_long_rounded, color: colorScheme.primary, size: 20),
 const SizedBox(width: 8),
 Text(
 'Datos del Pedido',
 style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
 ),
 ],
 ),
 const Divider(height: 20),
 _buildRow('Código de comprobante:', compra.codigo),
 _buildRow('Fecha de emisión:', compra.fechaFormateada),
 _buildRow('Método de pago:', compra.metodoPago),
 _buildRow('Total de prendas:', '${compra.totalPrendas} unidad(es)'),
 ],
 ),
 ),
 );
 }

 Widget _buildProductsCard(BuildContext context) {
 final colorScheme = Theme.of(context).colorScheme;
 final textTheme = Theme.of(context).textTheme;

 return Card(
 elevation: 1,
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
 child: Padding(
 padding: const EdgeInsets.all(16),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 children: [
 Icon(Icons.checkroom_rounded, color: colorScheme.primary, size: 20),
 const SizedBox(width: 8),
 Text(
 'Prendas Adquiridas (${compra.items.length})',
 style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
 ),
 ],
 ),
 const Divider(height: 20),
 if (compra.items.isEmpty)
 const Padding(
 padding: EdgeInsets.symmetric(vertical: 8),
 child: Text('No hay detalles de productos registrados.'),
 )
 else
 ListView.separated(
 shrinkWrap: true,
 physics: const NeverScrollableScrollPhysics(),
 itemCount: compra.items.length,
 separatorBuilder: (_, _) => const Divider(height: 16),
 itemBuilder: (context, index) {
 final item = compra.items[index];
 return Row(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Container(
 padding: const EdgeInsets.all(8),
 decoration: BoxDecoration(
 color: colorScheme.primaryContainer.withAlpha(50),
 borderRadius: BorderRadius.circular(10),
 ),
 child: Text(
 '${item.cantidad}x',
 style: TextStyle(
 fontWeight: FontWeight.bold,
 color: colorScheme.primary,
 fontSize: 13,
 ),
 ),
 ),
 const SizedBox(width: 12),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 item.nombre,
 style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
 ),
 const SizedBox(height: 2),
 if (item.talla != null || item.color != null)
 Text(
 '${item.talla != null ? "Talla: ${item.talla} " : ""}${item.color != null ? "• Color: ${item.color}" : ""}',
 style: TextStyle(fontSize: 11, color: colorScheme.outline),
 ),
 Text(
 'Bs ${item.precioUnitario.toStringAsFixed(2)} c/u',
 style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
 ),
 ],
 ),
 ),
 Text(
 'Bs ${item.subtotal.toStringAsFixed(2)}',
 style: const TextStyle(
 fontWeight: FontWeight.bold,
 fontSize: 14,
 ),
 ),
 ],
 );
 },
 ),
 ],
 ),
 ),
 );
 }

 Widget _buildDeliveryCard(BuildContext context) {
 final colorScheme = Theme.of(context).colorScheme;
 final textTheme = Theme.of(context).textTheme;
 final entrega = compra.datosEntrega!;

 return Card(
 elevation: 1,
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
 child: Padding(
 padding: const EdgeInsets.all(16),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 children: [
 Icon(Icons.local_shipping_outlined, color: colorScheme.primary, size: 20),
 const SizedBox(width: 8),
 Text(
 'Datos de Entrega y Envío',
 style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
 ),
 ],
 ),
 const Divider(height: 20),
 _buildRow('Destinatario:', entrega.nombreCliente),
 _buildRow('Teléfono:', entrega.telefono),
 _buildRow('Dirección:', entrega.direccion),
 _buildRow('Ciudad:', entrega.ciudad),
 if (entrega.referencia != null && entrega.referencia!.isNotEmpty)
 _buildRow('Referencia:', entrega.referencia!),
 const SizedBox(height: 12),
 SizedBox(
 width: double.infinity,
 child: FilledButton.tonalIcon(
 onPressed: () {
 ScaffoldMessenger.of(context).clearSnackBars();
 Navigator.of(context).push(
 MaterialPageRoute(
 builder: (_) => SeguimientoEnvioScreen(idVenta: compra.idVenta),
 ),
 );
 },
 icon: const Icon(Icons.local_shipping_rounded),
 label: const Text('Rastrear Envío en Tiempo Real'),
 ),
 ),
 ],
 ),
 ),
 );
 }

 Widget _buildFinancialSummaryCard(BuildContext context) {
 final colorScheme = Theme.of(context).colorScheme;
 final textTheme = Theme.of(context).textTheme;

 final subtotalProductos = compra.items.fold(0.0, (sum, i) => sum + i.subtotal);
 final costoEnvioStr = compra.costoEnvio <= 0 ? 'Gratis' : 'Bs ${compra.costoEnvio.toStringAsFixed(2)}';

 return Card(
 elevation: 1,
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
 child: Padding(
 padding: const EdgeInsets.all(16),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 children: [
 Icon(Icons.account_balance_wallet_outlined, color: colorScheme.primary, size: 20),
 const SizedBox(width: 8),
 Text(
 'Resumen de Pago',
 style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
 ),
 ],
 ),
 const Divider(height: 20),
 if (subtotalProductos > 0)
 _buildRow('Subtotal de prendas:', 'Bs ${subtotalProductos.toStringAsFixed(2)}'),
 _buildRow('Costo de envío:', costoEnvioStr),
 _buildRow('Método de pago:', compra.metodoPago),
 const Divider(height: 20),
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 const Text(
 'Total Cancelado:',
 style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
 ),
 Text(
 'Bs ${compra.total.toStringAsFixed(2)}',
 style: TextStyle(
 fontSize: 20,
 fontWeight: FontWeight.bold,
 color: colorScheme.primary,
 ),
 ),
 ],
 ),
 ],
 ),
 ),
 );
 }

 Widget _buildRow(String label, String value) {
 return Padding(
 padding: const EdgeInsets.only(bottom: 6),
 child: Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 label,
 style: const TextStyle(fontSize: 12, color: Colors.grey),
 ),
 const SizedBox(width: 12),
 Flexible(
 child: Text(
 value,
 textAlign: TextAlign.right,
 style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
 ),
 ),
 ],
 ),
 );
 }
}

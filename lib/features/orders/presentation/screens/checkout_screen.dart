import 'package:flutter/material.dart';

import '../../../../core/storage/secure_storage_service.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../../../branches/data/sucursales_service.dart';
import '../../../cart/logic/cart_service.dart';
import '../../../payments/presentation/screens/payment_gateway_screen.dart';

/// Full-screen Checkout flow for client order placement.
class CheckoutScreen extends StatefulWidget {
 const CheckoutScreen({super.key});

 @override
 State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
 final _formKey = GlobalKey<FormState>();

 final _nombreController = TextEditingController();
 final _correoController = TextEditingController();
 final _telefonoController = TextEditingController();
 final _direccionController = TextEditingController();
 final _ciudadController =
 TextEditingController(text: 'Santa Cruz de la Sierra');
 final _referenciaController = TextEditingController();

 String _metodoPago = 'QR'; // QR | EFECTIVO | TARJETA
 String? _error;

 List<Sucursal> _sucursales = [];
 int? _idSucursalSeleccionada;

 @override
 void initState() {
 super.initState();
 _loadUserSession();
 _loadSucursales();
 }

 Future<void> _loadSucursales() async {
 try {
 final res = await SucursalesService.listar();
 if (!mounted) return;
 if (res['success'] == true && res['sucursales'] is List<Sucursal>) {
 final list = res['sucursales'] as List<Sucursal>;
 setState(() {
 _sucursales = list;
 if (_sucursales.isNotEmpty) {
 _idSucursalSeleccionada = _sucursales.first.codigoSucursal;
 }
 });
 }
 } catch (_) {}
 }

 @override
 void dispose() {
 _nombreController.dispose();
 _correoController.dispose();
 _telefonoController.dispose();
 _direccionController.dispose();
 _ciudadController.dispose();
 _referenciaController.dispose();
 super.dispose();
 }

 Future<void> _loadUserSession() async {
 final session = await SecureStorageService.getUserSession();
 if (session != null && mounted) {
 setState(() {
 if (_nombreController.text.isEmpty) {
 _nombreController.text = (session['nombre'] as String?) ?? '';
 }
 if (_correoController.text.isEmpty) {
 _correoController.text = (session['correo'] as String?) ?? '';
 }
 });
 }
 }

 void _confirmarCompra() {
 if (!_formKey.currentState!.validate()) return;

 final cart = CartService.instance;
 if (cart.items.isEmpty) {
 ScaffoldMessenger.of(context)
 ..clearSnackBars()
 ..showSnackBar(
 const SnackBar(
 content: Text('Tu carrito está vacío.'),
 behavior: SnackBarBehavior.floating,
 duration: Duration(seconds: 2),
 ),
 );
 return;
 }

 Navigator.of(context).push(
 MaterialPageRoute(
 builder: (_) => PaymentGatewayScreen(
 items: cart.items,
 total: cart.total,
 costoEnvio: cart.costoEnvio,
 subtotal: cart.subtotal,
 nombreCliente: _nombreController.text.trim(),
 correo: _correoController.text.trim(),
 telefono: _telefonoController.text.trim(),
 direccion: _direccionController.text.trim(),
 ciudad: _ciudadController.text.trim(),
 referencia: _referenciaController.text.trim(),
 idSucursal: _idSucursalSeleccionada,
 metodoPagoInicial: _metodoPago,
 ),
 ),
 );
 }

 @override
 Widget build(BuildContext context) {
 final colorScheme = Theme.of(context).colorScheme;
 final textTheme = Theme.of(context).textTheme;
 final cart = CartService.instance;

 if (cart.items.isEmpty) {
 return Scaffold(
 appBar: AppBar(
 title: const Text('Confirmar Compra'),
 ),
 body: EmptyView(
 icon: Icons.shopping_bag_outlined,
 title: 'No hay prendas para comprar',
 message: 'Tu carrito no contiene productos en este momento.',
 actionLabel: 'Volver a la tienda',
 onAction: () => Navigator.of(context).pop(),
 ),
 );
 }

 return Scaffold(
 appBar: AppBar(
 title: const Text('Confirmar Compra'),
 ),
 body: Form(
 key: _formKey,
 child: Column(
 children: [
 Expanded(
 child: ListView(
 padding: const EdgeInsets.all(16),
 children: [
 if (_error != null) ...[
 Container(
 padding: const EdgeInsets.all(12),
 margin: const EdgeInsets.only(bottom: 16),
 decoration: BoxDecoration(
 color: colorScheme.errorContainer.withValues(alpha: 0.35),
 borderRadius: BorderRadius.circular(12),
 border: Border.all(
 color: colorScheme.error.withValues(alpha: 0.4),
 ),
 ),
 child: Row(
 children: [
 Icon(Icons.error_outline,
 color: colorScheme.error, size: 22),
 const SizedBox(width: 10),
 Expanded(
 child: Text(
 _error!,
 style: TextStyle(
 color: colorScheme.error,
 fontSize: 13,
 ),
 ),
 ),
 ],
 ),
 ),
 ],

 // 1. Resumen de prendas
 _buildSectionCard(
 title: '1. Resumen de Prendas (${cart.totalItemCount})',
 icon: Icons.checkroom_rounded,
 child: Column(
 children: cart.items.map((item) {
 return Padding(
 padding: const EdgeInsets.only(bottom: 8),
 child: Row(
 children: [
 Container(
 width: 44,
 height: 44,
 decoration: BoxDecoration(
 color: colorScheme.primaryContainer
 .withValues(alpha: 0.25),
 borderRadius: BorderRadius.circular(8),
 ),
 child: const Icon(
 Icons.checkroom_outlined,
 size: 22,
 ),
 ),
 const SizedBox(width: 12),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 item.nombre,
 style: textTheme.bodyMedium?.copyWith(
 fontWeight: FontWeight.bold,
 ),
 ),
 Text(
 '${item.talla != null ? "Talla: ${item.talla} " : ""}${item.color != null ? "• Color: ${item.color} " : ""}• Cantidad: ${item.cantidad}',
 style: TextStyle(
 fontSize: 11,
 color: colorScheme.outline,
 ),
 ),
 ],
 ),
 ),
 Text(
 'Bs ${item.subtotal.toStringAsFixed(2)}',
 style: const TextStyle(
 fontWeight: FontWeight.bold,
 fontSize: 13,
 ),
 ),
 ],
 ),
 );
 }).toList(),
 ),
 ),
 const SizedBox(height: 16),

 // 2. Datos de Envío y Facturación
 _buildSectionCard(
 title: '2. Datos de Envío y Facturación',
 icon: Icons.local_shipping_outlined,
 child: Column(
 children: [
 TextFormField(
 controller: _nombreController,
 decoration: const InputDecoration(
 labelText: 'Nombre completo *',
 prefixIcon: Icon(Icons.person_outline),
 border: OutlineInputBorder(),
 isDense: true,
 ),
 validator: (v) => (v == null || v.trim().length < 3)
 ? 'Ingresa tu nombre'
 : null,
 ),
 const SizedBox(height: 10),
 Row(
 children: [
 Expanded(
 child: TextFormField(
 controller: _correoController,
 keyboardType: TextInputType.emailAddress,
 decoration: const InputDecoration(
 labelText: 'Correo *',
 prefixIcon: Icon(Icons.email_outlined),
 border: OutlineInputBorder(),
 isDense: true,
 ),
 validator: (v) =>
 (v == null || !v.contains('@'))
 ? 'Correo inválido'
 : null,
 ),
 ),
 const SizedBox(width: 10),
 Expanded(
 child: TextFormField(
 controller: _telefonoController,
 keyboardType: TextInputType.phone,
 decoration: const InputDecoration(
 labelText: 'Teléfono *',
 prefixIcon: Icon(Icons.phone_outlined),
 border: OutlineInputBorder(),
 isDense: true,
 ),
 validator: (v) =>
 (v == null || v.trim().length < 6)
 ? 'Teléfono requerido'
 : null,
 ),
 ),
 ],
 ),
 const SizedBox(height: 10),
 TextFormField(
 controller: _direccionController,
 decoration: const InputDecoration(
 labelText: 'Dirección de entrega (Calle, Nro) *',
 prefixIcon: Icon(Icons.home_outlined),
 border: OutlineInputBorder(),
 isDense: true,
 ),
 validator: (v) => (v == null || v.trim().length < 4)
 ? 'Ingresa tu dirección de entrega'
 : null,
 ),
 const SizedBox(height: 10),
 Row(
 children: [
 Expanded(
 child: TextFormField(
 controller: _ciudadController,
 decoration: const InputDecoration(
 labelText: 'Ciudad *',
 prefixIcon:
 Icon(Icons.location_city_outlined),
 border: OutlineInputBorder(),
 isDense: true,
 ),
 validator: (v) =>
 (v == null || v.trim().isEmpty)
 ? 'Ciudad requerida'
 : null,
 ),
 ),
 const SizedBox(width: 10),
 Expanded(
 child: TextFormField(
 controller: _referenciaController,
 decoration: const InputDecoration(
 labelText: 'Referencia (opcional)',
 prefixIcon: Icon(Icons.info_outline),
 border: OutlineInputBorder(),
 isDense: true,
 ),
 ),
 ),
 ],
 ),
 ],
 ),
 ),
 const SizedBox(height: 16),

 // 2.1 Sucursal de Despacho / Retiro
 _buildSectionCard(
 title: '2.1 Sucursal de Despacho / Retiro',
 icon: Icons.storefront_rounded,
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 const Text(
 'Selecciona la sucursal de donde se despachará o retirarás tu pedido (descuento de stock en tiempo real):',
 style: TextStyle(fontSize: 12, color: Colors.black54),
 ),
 const SizedBox(height: 8),
 if (_sucursales.isNotEmpty)
 DropdownButtonFormField<int>(
 initialValue: _idSucursalSeleccionada,
 isExpanded: true,
 decoration: const InputDecoration(
 prefixIcon: Icon(Icons.storefront_rounded),
 border: OutlineInputBorder(),
 isDense: true,
 ),
 items: _sucursales.map((s) {
 return DropdownMenuItem<int>(
 value: s.codigoSucursal,
 child: Text(
 '${s.nombre} • ${s.ciudad.nombre}',
 style: const TextStyle(fontSize: 13),
 overflow: TextOverflow.ellipsis,
 ),
 );
 }).toList(),
 onChanged: (val) => setState(() => _idSucursalSeleccionada = val),
 )
 else
 const Padding(
 padding: EdgeInsets.symmetric(vertical: 4),
 child: Text('Cargando sucursales de atención...', style: TextStyle(fontSize: 12, color: Colors.grey)),
 ),
 ],
 ),
 ),
 const SizedBox(height: 16),

 // 3. Método de Pago
 _buildSectionCard(
 title: '3. Método de Pago',
 icon: Icons.payment_rounded,
 child: Column(
 children: [
 Row(
 children: [
 _PaymentCardOption(
 title: 'Pago QR',
 subtitle: 'Simple y rápido',
 icon: Icons.qr_code_2_rounded,
 isSelected: _metodoPago == 'QR',
 onTap: () => setState(() => _metodoPago = 'QR'),
 ),
 const SizedBox(width: 10),
 _PaymentCardOption(
 title: 'Tarjeta',
 subtitle: 'Débito / Crédito',
 icon: Icons.credit_card_rounded,
 isSelected: _metodoPago == 'TARJETA',
 onTap: () =>
 setState(() => _metodoPago = 'TARJETA'),
 ),
 const SizedBox(width: 10),
 _PaymentCardOption(
 title: 'Efectivo',
 subtitle: 'Contra entrega',
 icon: Icons.payments_outlined,
 isSelected: _metodoPago == 'EFECTIVO',
 onTap: () =>
 setState(() => _metodoPago = 'EFECTIVO'),
 ),
 ],
 ),
 if (_metodoPago == 'QR') ...[
 const SizedBox(height: 14),
 Container(
 padding: const EdgeInsets.all(12),
 decoration: BoxDecoration(
 color: colorScheme.surfaceContainerHighest
 .withValues(alpha: 0.35),
 borderRadius: BorderRadius.circular(12),
 border: Border.all(
 color:
 colorScheme.outline.withValues(alpha: 0.2),
 ),
 ),
 child: Row(
 children: [
 Container(
 padding: const EdgeInsets.all(8),
 decoration: BoxDecoration(
 color: Colors.white,
 borderRadius: BorderRadius.circular(8),
 ),
 child: const Icon(
 Icons.qr_code_rounded,
 size: 40,
 color: Colors.black87,
 ),
 ),
 const SizedBox(width: 12),
 Expanded(
 child: Column(
 crossAxisAlignment:
 CrossAxisAlignment.start,
 children: [
 const Text(
 'Generación de QR Automático',
 style: TextStyle(
 fontWeight: FontWeight.bold,
 fontSize: 12,
 ),
 ),
 const SizedBox(height: 2),
 Text(
 'Al confirmar la compra, se generará tu comprobante digital y podrás pagar desde tu app bancaria.',
 style: TextStyle(
 fontSize: 11,
 color: colorScheme.outline,
 ),
 ),
 ],
 ),
 ),
 ],
 ),
 ),
 ],
 ],
 ),
 ),
 const SizedBox(height: 16),

 // 4. Desglose de Precios
 _buildSectionCard(
 title: '4. Resumen del Pedido',
 icon: Icons.receipt_long_rounded,
 child: Column(
 children: [
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 const Text('Subtotal:'),
 Text(
 'Bs ${cart.subtotal.toStringAsFixed(2)}',
 style:
 const TextStyle(fontWeight: FontWeight.w600),
 ),
 ],
 ),
 const SizedBox(height: 6),
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Row(
 children: [
 const Text('Costo de envío:'),
 if (cart.isEnvioGratis) ...[
 const SizedBox(width: 6),
 Container(
 padding: const EdgeInsets.symmetric(
 horizontal: 6,
 vertical: 2,
 ),
 decoration: BoxDecoration(
 color: Colors.green.shade100,
 borderRadius: BorderRadius.circular(6),
 ),
 child: Text(
 '¡Gratis!',
 style: TextStyle(
 color: Colors.green.shade900,
 fontSize: 10,
 fontWeight: FontWeight.bold,
 ),
 ),
 ),
 ],
 ],
 ),
 Text(
 cart.isEnvioGratis
 ? 'Bs 0.00'
 : 'Bs ${cart.costoEnvio.toStringAsFixed(2)}',
 style: TextStyle(
 fontWeight: FontWeight.w600,
 color: cart.isEnvioGratis
 ? Colors.green.shade800
 : null,
 ),
 ),
 ],
 ),
 const Divider(height: 20),
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 const Text(
 'Total a pagar:',
 style: TextStyle(
 fontWeight: FontWeight.bold,
 fontSize: 16,
 ),
 ),
 Text(
 'Bs ${cart.total.toStringAsFixed(2)}',
 style: TextStyle(
 fontWeight: FontWeight.bold,
 fontSize: 20,
 color: colorScheme.primary,
 ),
 ),
 ],
 ),
 ],
 ),
 ),
 const SizedBox(height: 24),
 ],
 ),
 ),

 // Bottom Confirm Button Bar
 Container(
 padding: const EdgeInsets.all(16),
 decoration: BoxDecoration(
 color: colorScheme.surface,
 boxShadow: [
 BoxShadow(
 color: Colors.black.withValues(alpha: 0.06),
 blurRadius: 10,
 offset: const Offset(0, -4),
 ),
 ],
 ),
 child: SafeArea(
 top: false,
 child: SizedBox(
 width: double.infinity,
 child: FilledButton.icon(
 onPressed: _confirmarCompra,
 style: FilledButton.styleFrom(
 padding: const EdgeInsets.symmetric(vertical: 16),
 shape: RoundedRectangleBorder(
 borderRadius: BorderRadius.circular(14),
 ),
 ),
 icon: const Icon(Icons.lock_outline),
 label: Text(
 'Continuar al Pago (Bs ${cart.total.toStringAsFixed(2)})',
 style: const TextStyle(
 fontWeight: FontWeight.bold,
 fontSize: 15,
 ),
 ),
 ),
 ),
 ),
 ),
 ],
 ),
 ),
 );
 }

 Widget _buildSectionCard({
 required String title,
 required IconData icon,
 required Widget child,
 }) {
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
 Icon(icon, color: colorScheme.primary, size: 20),
 const SizedBox(width: 8),
 Text(
 title,
 style: textTheme.titleSmall?.copyWith(
 fontWeight: FontWeight.bold,
 ),
 ),
 ],
 ),
 const SizedBox(height: 12),
 child,
 ],
 ),
 ),
 );
 }
}

class _PaymentCardOption extends StatelessWidget {
 const _PaymentCardOption({
 required this.title,
 required this.subtitle,
 required this.icon,
 required this.isSelected,
 required this.onTap,
 });

 final String title;
 final String subtitle;
 final IconData icon;
 final bool isSelected;
 final VoidCallback onTap;

 @override
 Widget build(BuildContext context) {
 final colorScheme = Theme.of(context).colorScheme;

 return Expanded(
 child: InkWell(
 borderRadius: BorderRadius.circular(12),
 onTap: onTap,
 child: Container(
 padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
 decoration: BoxDecoration(
 color: isSelected
 ? colorScheme.primaryContainer.withValues(alpha: 0.45)
 : colorScheme.surface,
 borderRadius: BorderRadius.circular(12),
 border: Border.all(
 color: isSelected
 ? colorScheme.primary
 : colorScheme.outline.withValues(alpha: 0.25),
 width: isSelected ? 2 : 1,
 ),
 ),
 child: Column(
 children: [
 Icon(
 icon,
 size: 24,
 color: isSelected ? colorScheme.primary : colorScheme.onSurface,
 ),
 const SizedBox(height: 6),
 Text(
 title,
 textAlign: TextAlign.center,
 style: TextStyle(
 fontSize: 11,
 fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
 color:
 isSelected ? colorScheme.primary : colorScheme.onSurface,
 ),
 ),
 const SizedBox(height: 2),
 Text(
 subtitle,
 textAlign: TextAlign.center,
 style: TextStyle(
 fontSize: 9,
 color: colorScheme.outline,
 ),
 ),
 ],
 ),
 ),
 ),
 );
 }
}

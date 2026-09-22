import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../cart/data/cart_item.dart';
import '../../../cart/logic/cart_service.dart';
import '../../../orders/data/compra_service.dart';
import '../../../orders/presentation/screens/comprobante_screen.dart';
import '../../data/pasarela_service.dart';
import '../../data/payment_model.dart';

/// Screen representing the secure Payment Gateway.
class PaymentGatewayScreen extends StatefulWidget {
 const PaymentGatewayScreen({
 super.key,
 required this.items,
 required this.total,
 required this.costoEnvio,
 required this.subtotal,
 required this.nombreCliente,
 required this.correo,
 required this.telefono,
 required this.direccion,
 required this.ciudad,
 this.referencia,
 this.idSucursal,
 this.tipoEntrega = 'DOMICILIO',
 this.metodoPagoInicial = 'TARJETA',
 });

 final List<CartItem> items;
 final double total;
 final double costoEnvio;
 final double subtotal;
 final String nombreCliente;
 final String correo;
 final String telefono;
 final String direccion;
 final String ciudad;
 final String? referencia;
 final int? idSucursal;
 final String tipoEntrega;
 final String metodoPagoInicial;

 @override
 State<PaymentGatewayScreen> createState() => _PaymentGatewayScreenState();
}

class _PaymentGatewayScreenState extends State<PaymentGatewayScreen> {
 late String _metodoPago; // TARJETA | QR | EFECTIVO

 // Card Controllers
 final _tarjetaFormKey = GlobalKey<FormState>();
 final _numeroTarjetaController = TextEditingController();
 final _titularController = TextEditingController();
 final _expiracionController = TextEditingController();
 final _cvvController = TextEditingController();

 // State flags
 bool _procesando = false;
 String? _errorMensaje;

 // QR Live State
 TransaccionPagoModel? _transaccionIniciada;
 Timer? _pollingTimer;
 int _qrSegundosRestantes = 900; // 15 minutos
 Timer? _countdownTimer;

 @override
 void initState() {
 super.initState();
 _metodoPago = widget.metodoPagoInicial;
 _titularController.text = widget.nombreCliente.toUpperCase();
 }

 @override
 void dispose() {
 _numeroTarjetaController.dispose();
 _titularController.dispose();
 _expiracionController.dispose();
 _cvvController.dispose();
 _pollingTimer?.cancel();
 _countdownTimer?.cancel();
 super.dispose();
 }

 void _startCountdown() {
 _countdownTimer?.cancel();
 _qrSegundosRestantes = 900;
 _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
 if (!mounted) return;
 setState(() {
 if (_qrSegundosRestantes > 0) {
 _qrSegundosRestantes--;
 } else {
 t.cancel();
 }
 });
 });
 }

 void _startPollingEstado(String codigoTxn) {
 _pollingTimer?.cancel();
 _pollingTimer = Timer.periodic(const Duration(seconds: 4), (t) async {
 if (!mounted) {
 t.cancel();
 return;
 }
 final res = await PasarelaService.consultarEstado(codigoTxn);
 if (res['success'] == true && res['transaccion'] is TransaccionPagoModel) {
 final txn = res['transaccion'] as TransaccionPagoModel;
 if (txn.isPagado) {
 t.cancel();
 _onPagoExitoso(txn.codigoVenta ?? 'ATT-000000', txn.idVenta ?? 0);
 } else if (txn.isRechazado) {
 t.cancel();
 if (mounted) {
 setState(() {
 _errorMensaje = 'El pago fue rechazado por la pasarela o la entidad bancaria.';
 _procesando = false;
 });
 }
 }
 }
 });
 }

 Future<void> _procesarPago() async {
 setState(() {
 _errorMensaje = null;
 });

 DatosTarjetaModel? datosTarjeta;
 if (_metodoPago == 'TARJETA') {
 if (!_tarjetaFormKey.currentState!.validate()) return;
 datosTarjeta = DatosTarjetaModel(
 titular: _titularController.text.trim(),
 numeroTarjeta: _numeroTarjetaController.text.replaceAll(' ', '').trim(),
 expiracion: _expiracionController.text.trim(),
 cvv: _cvvController.text.trim(),
 );
 }

 setState(() => _procesando = true);

 final res = await PasarelaService.iniciarPago(
 items: widget.items,
 metodoPago: _metodoPago,
 nombreCliente: widget.nombreCliente,
 correo: widget.correo,
 telefono: widget.telefono,
 direccion: widget.direccion,
 ciudad: widget.ciudad,
 referencia: widget.referencia,
 datosTarjeta: datosTarjeta,
 idSucursal: widget.idSucursal,
 tipoEntrega: widget.tipoEntrega,
 );

 if (!mounted) return;

 if (res['success'] == true) {
 final transaccion = res['transaccion'] as TransaccionPagoModel?;
 final idVenta = res['id_venta'] as int? ?? 0;
 final codigoVenta = res['codigo_venta'] as String? ?? 'ATT-000000';

 if (_metodoPago == 'EFECTIVO') {
 // Efectivo contra entrega se confirma de inmediato en el flujo
 _onPagoExitoso(codigoVenta, idVenta);
 return;
 }

 if (_metodoPago == 'QR' && transaccion != null) {
 setState(() {
 _transaccionIniciada = transaccion;
 _procesando = false;
 });
 _startCountdown();
 _startPollingEstado(transaccion.codigoTransaccion);
 return;
 }

 if (_metodoPago == 'TARJETA' && transaccion != null) {
 setState(() {
 _transaccionIniciada = transaccion;
 });
 // En pasarela integrada con webhook, simulamos la confirmación del gateway bancario
 final confirmacion = await PasarelaService.simularConfirmacion(
 codigoTransaccion: transaccion.codigoTransaccion,
 aprobar: true,
 );

 if (!mounted) return;

 if (confirmacion['success'] == true) {
 _onPagoExitoso(codigoVenta, idVenta);
 } else {
 setState(() {
 _procesando = false;
 _errorMensaje = confirmacion['message'] ?? 'Error al confirmar cargo en tarjeta.';
 });
 }
 return;
 }
 }

 setState(() {
 _procesando = false;
 _errorMensaje = res['message'] ?? 'No se pudo completar el pago.';
 });
 }

 void _onPagoExitoso(String codigoVenta, int idVenta) {
 _pollingTimer?.cancel();
 _countdownTimer?.cancel();

 // Vaciar carrito
 CartService.instance.clear();

 // Crear VentaModel para el comprobante
 final ventaModel = VentaModel(
 idVenta: idVenta,
 codigo: codigoVenta,
 fechaVenta: DateTime.now(),
 total: widget.total,
 costoEnvio: widget.costoEnvio,
 metodoPago: _metodoPago,
 estadoPago: 'PAGADO',
 items: widget.items
 .map((i) => VentaItemModel(
 idDetalle: 0,
 productoId: i.idProducto,
 nombre: i.nombre,
 talla: i.talla,
 color: i.color,
 cantidad: i.cantidad,
 precioUnitario: i.precioUnitario,
 subtotal: i.subtotal,
 ))
 .toList(),
 datosEntrega: DatosEntregaModel(
 nombreCliente: widget.nombreCliente,
 correo: widget.correo,
 telefono: widget.telefono,
 direccion: widget.direccion,
 ciudad: widget.ciudad,
 referencia: widget.referencia,
 ),
 );

 Navigator.of(context).pushReplacement(
 MaterialPageRoute(
 builder: (_) => ComprobanteScreen(venta: ventaModel),
 ),
 );
 }

 Future<void> _simularAprobacionQR() async {
 if (_transaccionIniciada == null) return;
 setState(() => _procesando = true);

 final res = await PasarelaService.simularConfirmacion(
 codigoTransaccion: _transaccionIniciada!.codigoTransaccion,
 aprobar: true,
 );

 if (!mounted) return;

 if (res['success'] == true) {
 _onPagoExitoso(
 _transaccionIniciada!.codigoVenta ?? 'ATT-000000',
 _transaccionIniciada!.idVenta ?? 0,
 );
 } else {
 setState(() {
 _procesando = false;
 _errorMensaje = res['message'] ?? 'Error al simular confirmación QR.';
 });
 }
 }

 @override
 Widget build(BuildContext context) {
 final colorScheme = Theme.of(context).colorScheme;

 return Scaffold(
 appBar: AppBar(
 title: const Text('Pasarela de Pagos Segura'),
 elevation: 0,
 ),
 body: SafeArea(
 child: Column(
 children: [
 Expanded(
 child: SingleChildScrollView(
 padding: const EdgeInsets.all(16),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.stretch,
 children: [
 // Resumen de Monto a Pagar
 _buildMontoHeader(colorScheme),
 const SizedBox(height: 16),

 if (_errorMensaje != null) ...[
 _buildErrorBanner(colorScheme),
 const SizedBox(height: 16),
 ],

 // Si ya se generó el QR, mostramos la vista interactiva del QR
 if (_metodoPago == 'QR' && _transaccionIniciada != null) ...[
 _buildQRView(colorScheme),
 ] else ...[
 // Selector de Métodos de Pago
 _buildMetodoSelector(colorScheme),
 const SizedBox(height: 16),

 // Formulario según método seleccionado
 if (_metodoPago == 'TARJETA') _buildTarjetaForm(colorScheme),
 if (_metodoPago == 'QR') _buildQRInfoPrevia(colorScheme),
 if (_metodoPago == 'EFECTIVO') _buildEfectivoInfo(colorScheme),
 ],

 const SizedBox(height: 20),
 _buildSecurityBadge(colorScheme),
 ],
 ),
 ),
 ),

 // Botón Inferior de Pago
 if (!(_metodoPago == 'QR' && _transaccionIniciada != null))
 _buildBottomBar(colorScheme),
 ],
 ),
 ),
 );
 }

 Widget _buildMontoHeader(ColorScheme colorScheme) {
 return Container(
 padding: const EdgeInsets.all(16),
 decoration: BoxDecoration(
 gradient: LinearGradient(
 colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.85)],
 begin: Alignment.topLeft,
 end: Alignment.bottomRight,
 ),
 borderRadius: BorderRadius.circular(16),
 boxShadow: [
 BoxShadow(
 color: colorScheme.primary.withValues(alpha: 0.25),
 blurRadius: 10,
 offset: const Offset(0, 4),
 ),
 ],
 ),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 const Text(
 'Total a Liquidar',
 style: TextStyle(color: Colors.white70, fontSize: 13),
 ),
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
 decoration: BoxDecoration(
 color: Colors.white24,
 borderRadius: BorderRadius.circular(10),
 ),
 child: Text(
 '${widget.items.length} prendas',
 style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
 ),
 ),
 ],
 ),
 const SizedBox(height: 6),
 Text(
 'Bs ${widget.total.toStringAsFixed(2)}',
 style: const TextStyle(
 color: Colors.white,
 fontSize: 28,
 fontWeight: FontWeight.bold,
 letterSpacing: 0.5,
 ),
 ),
 const SizedBox(height: 4),
 Text(
 'Subtotal: Bs ${widget.subtotal.toStringAsFixed(2)} • Envío: ${widget.costoEnvio == 0 ? "Gratis" : "Bs ${widget.costoEnvio.toStringAsFixed(2)}"}',
 style: const TextStyle(color: Colors.white70, fontSize: 11),
 ),
 ],
 ),
 );
 }

 Widget _buildErrorBanner(ColorScheme colorScheme) {
 return Container(
 padding: const EdgeInsets.all(12),
 decoration: BoxDecoration(
 color: colorScheme.errorContainer.withValues(alpha: 0.4),
 borderRadius: BorderRadius.circular(12),
 border: Border.all(color: colorScheme.error),
 ),
 child: Row(
 children: [
 Icon(Icons.error_outline, color: colorScheme.error, size: 22),
 const SizedBox(width: 10),
 Expanded(
 child: Text(
 _errorMensaje!,
 style: TextStyle(color: colorScheme.error, fontSize: 12),
 ),
 ),
 ],
 ),
 );
 }

 Widget _buildMetodoSelector(ColorScheme colorScheme) {
 return Row(
 children: [
 _buildMetodoChip('TARJETA', 'Tarjeta', Icons.credit_card_rounded, colorScheme),
 const SizedBox(width: 10),
 _buildMetodoChip('QR', 'Pago QR', Icons.qr_code_2_rounded, colorScheme),
 const SizedBox(width: 10),
 _buildMetodoChip('EFECTIVO', 'Efectivo', Icons.payments_outlined, colorScheme),
 ],
 );
 }

 Widget _buildMetodoChip(String id, String label, IconData icon, ColorScheme colorScheme) {
 final isSelected = _metodoPago == id;
 return Expanded(
 child: InkWell(
 onTap: _procesando ? null : () => setState(() => _metodoPago = id),
 borderRadius: BorderRadius.circular(12),
 child: AnimatedContainer(
 duration: const Duration(milliseconds: 200),
 padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
 decoration: BoxDecoration(
 color: isSelected ? colorScheme.primaryContainer.withValues(alpha: 0.4) : colorScheme.surface,
 borderRadius: BorderRadius.circular(12),
 border: Border.all(
 color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.25),
 width: isSelected ? 2 : 1,
 ),
 ),
 child: Column(
 children: [
 Icon(icon, color: isSelected ? colorScheme.primary : colorScheme.onSurface, size: 22),
 const SizedBox(height: 4),
 Text(
 label,
 style: TextStyle(
 fontSize: 12,
 fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
 color: isSelected ? colorScheme.primary : colorScheme.onSurface,
 ),
 ),
 ],
 ),
 ),
 ),
 );
 }

 Widget _buildTarjetaForm(ColorScheme colorScheme) {
 final ultimos4 = _numeroTarjetaController.text.replaceAll(' ', '');
 final previewNumero = ultimos4.isEmpty
 ? '•••• •••• •••• ••••'
 : ultimos4.padRight(16, '•').replaceAllMapped(RegExp(r'.{4}'), (match) => '${match.group(0)} ').trim();

 return Form(
 key: _tarjetaFormKey,
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.stretch,
 children: [
 // Visual Card Simulation
 Container(
 height: 180,
 padding: const EdgeInsets.all(20),
 decoration: BoxDecoration(
 gradient: const LinearGradient(
 colors: [Color(0xFF1F2937), Color(0xFF111827)],
 begin: Alignment.topLeft,
 end: Alignment.bottomRight,
 ),
 borderRadius: BorderRadius.circular(18),
 boxShadow: const [
 BoxShadow(
 color: Colors.black26,
 blurRadius: 10,
 offset: Offset(0, 5),
 ),
 ],
 ),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 const Text(
 'AttentionPay',
 style: TextStyle(
 color: Colors.white,
 fontWeight: FontWeight.bold,
 fontSize: 15,
 letterSpacing: 1.2,
 ),
 ),
 Icon(
 _numeroTarjetaController.text.startsWith('5')
 ? Icons.payment_rounded
 : Icons.credit_card_rounded,
 color: Colors.amber.shade400,
 size: 28,
 ),
 ],
 ),
 Text(
 previewNumero,
 style: const TextStyle(
 color: Colors.white,
 fontSize: 18,
 letterSpacing: 2.2,
 fontFamily: 'monospace',
 ),
 ),
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 const Text('TITULAR', style: TextStyle(color: Colors.white54, fontSize: 9)),
 Text(
 _titularController.text.isEmpty ? 'NOMBRE Y APELLIDO' : _titularController.text,
 style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
 ),
 ],
 ),
 Column(
 crossAxisAlignment: CrossAxisAlignment.end,
 children: [
 const Text('VENCE', style: TextStyle(color: Colors.white54, fontSize: 9)),
 Text(
 _expiracionController.text.isEmpty ? 'MM/AA' : _expiracionController.text,
 style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
 ),
 ],
 ),
 ],
 ),
 ],
 ),
 ),
 const SizedBox(height: 16),

 // Card Form Inputs
 TextFormField(
 controller: _numeroTarjetaController,
 keyboardType: TextInputType.number,
 inputFormatters: [
 FilteringTextInputFormatter.digitsOnly,
 LengthLimitingTextInputFormatter(16),
 _CardNumberFormatter(),
 ],
 decoration: const InputDecoration(
 labelText: 'Número de Tarjeta *',
 prefixIcon: Icon(Icons.credit_card_outlined),
 border: OutlineInputBorder(),
 hintText: '4500 0000 0000 0000',
 isDense: true,
 ),
 onChanged: (_) => setState(() {}),
 validator: (v) {
 final clean = (v ?? '').replaceAll(' ', '');
 if (clean.length < 13 || clean.length > 19) {
 return 'Ingresa un número de tarjeta válido (16 dígitos)';
 }
 return null;
 },
 ),
 const SizedBox(height: 10),

 TextFormField(
 controller: _titularController,
 textCapitalization: TextCapitalization.characters,
 decoration: const InputDecoration(
 labelText: 'Titular de la Tarjeta *',
 prefixIcon: Icon(Icons.person_outline),
 border: OutlineInputBorder(),
 isDense: true,
 ),
 onChanged: (_) => setState(() {}),
 validator: (v) => (v == null || v.trim().length < 3) ? 'Ingresa el nombre del titular' : null,
 ),
 const SizedBox(height: 10),

 Row(
 children: [
 Expanded(
 child: TextFormField(
 controller: _expiracionController,
 keyboardType: TextInputType.number,
 inputFormatters: [
 FilteringTextInputFormatter.digitsOnly,
 LengthLimitingTextInputFormatter(4),
 _ExpiryDateFormatter(),
 ],
 decoration: const InputDecoration(
 labelText: 'Expiración (MM/AA) *',
 prefixIcon: Icon(Icons.calendar_month_outlined),
 border: OutlineInputBorder(),
 hintText: '12/28',
 isDense: true,
 ),
 onChanged: (_) => setState(() {}),
 validator: (v) {
 if (v == null || v.length < 5 || !v.contains('/')) {
 return 'Formato MM/AA';
 }
 return null;
 },
 ),
 ),
 const SizedBox(width: 10),
 Expanded(
 child: TextFormField(
 controller: _cvvController,
 keyboardType: TextInputType.number,
 obscureText: true,
 inputFormatters: [
 FilteringTextInputFormatter.digitsOnly,
 LengthLimitingTextInputFormatter(4),
 ],
 decoration: const InputDecoration(
 labelText: 'CVV / CVC *',
 prefixIcon: Icon(Icons.lock_outline),
 border: OutlineInputBorder(),
 hintText: '123',
 isDense: true,
 ),
 validator: (v) {
 if (v == null || v.length < 3) {
 return '3 o 4 dígitos';
 }
 return null;
 },
 ),
 ),
 ],
 ),
 ],
 ),
 );
 }

 Widget _buildQRInfoPrevia(ColorScheme colorScheme) {
 return Container(
 padding: const EdgeInsets.all(16),
 decoration: BoxDecoration(
 color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
 borderRadius: BorderRadius.circular(16),
 border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
 ),
 child: Column(
 children: [
 Icon(Icons.qr_code_2_rounded, size: 64, color: colorScheme.primary),
 const SizedBox(height: 12),
 const Text(
 'Generación de QR Bancario Inmediato',
 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
 ),
 const SizedBox(height: 6),
 Text(
 'Al hacer clic en "Generar QR y Pagar", el sistema generará un código QR Simple interoperable por el monto exacto de Bs ${widget.total.toStringAsFixed(2)}. Podrás escanearlo con cualquier banco (BCP, BNB, Banco Unión, etc.).',
 textAlign: TextAlign.center,
 style: TextStyle(fontSize: 12, color: colorScheme.outline),
 ),
 ],
 ),
 );
 }

 Widget _buildQRView(ColorScheme colorScheme) {
 final minutos = (_qrSegundosRestantes ~/ 60).toString().padLeft(2, '0');
 final segundos = (_qrSegundosRestantes % 60).toString().padLeft(2, '0');

 return Card(
 elevation: 2,
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
 child: Padding(
 padding: const EdgeInsets.all(20),
 child: Column(
 children: [
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 const Text('Código de Transacción', style: TextStyle(fontSize: 10, color: Colors.grey)),
 Text(
 _transaccionIniciada!.codigoTransaccion,
 style: TextStyle(
 fontSize: 12,
 fontWeight: FontWeight.bold,
 color: colorScheme.primary,
 ),
 ),
 ],
 ),
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
 decoration: BoxDecoration(
 color: Colors.amber.shade50,
 borderRadius: BorderRadius.circular(8),
 border: Border.all(color: Colors.amber.shade300),
 ),
 child: Row(
 children: [
 Icon(Icons.timer_outlined, size: 14, color: Colors.amber.shade900),
 const SizedBox(width: 4),
 Text(
 '$minutos:$segundos',
 style: TextStyle(
 fontSize: 12,
 fontWeight: FontWeight.bold,
 color: Colors.amber.shade900,
 ),
 ),
 ],
 ),
 ),
 ],
 ),
 const Divider(height: 24),

 // Visual QR Code
 Container(
 padding: const EdgeInsets.all(16),
 decoration: BoxDecoration(
 color: Colors.white,
 borderRadius: BorderRadius.circular(16),
 border: Border.all(color: Colors.grey.shade300, width: 2),
 boxShadow: [
 BoxShadow(
 color: Colors.black.withValues(alpha: 0.05),
 blurRadius: 10,
 offset: const Offset(0, 4),
 ),
 ],
 ),
 child: Column(
 children: [
 // Placeholder for dynamic QR graphic
 Stack(
 alignment: Alignment.center,
 children: [
 Icon(
 Icons.qr_code_2_rounded,
 size: 200,
 color: Colors.grey.shade900,
 ),
 Container(
 padding: const EdgeInsets.all(6),
 decoration: const BoxDecoration(
 color: Colors.white,
 shape: BoxShape.circle,
 ),
 child: Icon(
 Icons.shopping_bag_rounded,
 color: colorScheme.primary,
 size: 28,
 ),
 ),
 ],
 ),
 const SizedBox(height: 8),
 Text(
 'Escanea con tu aplicación bancaria',
 style: TextStyle(
 fontSize: 11,
 fontWeight: FontWeight.bold,
 color: Colors.grey.shade700,
 ),
 ),
 ],
 ),
 ),
 const SizedBox(height: 16),

 // Waiting indicator
 Row(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 SizedBox(
 width: 16,
 height: 16,
 child: CircularProgressIndicator(
 strokeWidth: 2,
 color: colorScheme.primary,
 ),
 ),
 const SizedBox(width: 10),
 const Text(
 'Esperando confirmación automática por Webhook...',
 style: TextStyle(fontSize: 11, color: Colors.grey),
 ),
 ],
 ),
 const SizedBox(height: 20),

 // Action: Simulate Successful Payment (Demo webhook trigger)
 OutlinedButton.icon(
 onPressed: _procesando ? null : _simularAprobacionQR,
 style: OutlinedButton.styleFrom(
 minimumSize: const Size.fromHeight(46),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
 ),
 icon: _procesando
 ? const SizedBox(
 width: 18,
 height: 18,
 child: CircularProgressIndicator(strokeWidth: 2),
 )
 : const Icon(Icons.flash_on_rounded, color: Colors.green),
 label: Text(
 _procesando ? 'Procesando confirmación...' : 'Simular Confirmación Bancaria',
 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
 ),
 ),
 ],
 ),
 ),
 );
 }

 Widget _buildEfectivoInfo(ColorScheme colorScheme) {
 return Container(
 padding: const EdgeInsets.all(16),
 decoration: BoxDecoration(
 color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
 borderRadius: BorderRadius.circular(16),
 border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
 ),
 child: Column(
 children: [
 Icon(Icons.payments_rounded, size: 54, color: colorScheme.primary),
 const SizedBox(height: 10),
 const Text(
 'Pago en Efectivo Contra Entrega',
 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
 ),
 const SizedBox(height: 6),
 Text(
 widget.tipoEntrega == 'DOMICILIO'
 ? 'Pagarás en efectivo al repartidor cuando entregue las prendas en tu dirección registrada. Por favor prepara el importe exacto de Bs ${widget.total.toStringAsFixed(2)}.'
 : 'Pagarás en efectivo directamente en la caja de la sucursal seleccionada al recoger tus prendas.',
 textAlign: TextAlign.center,
 style: TextStyle(fontSize: 12, color: colorScheme.outline),
 ),
 ],
 ),
 );
 }

 Widget _buildSecurityBadge(ColorScheme colorScheme) {
 return Row(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 Icon(Icons.lock_rounded, size: 14, color: colorScheme.outline),
 const SizedBox(width: 6),
 Text(
 'Pasarela AttentionPay • Encriptación TLS 256-bit • Pagos Seguros',
 style: TextStyle(fontSize: 10, color: colorScheme.outline),
 ),
 ],
 );
 }

 Widget _buildBottomBar(ColorScheme colorScheme) {
 String labelBoton;
 if (_metodoPago == 'TARJETA') {
 labelBoton = 'Pagar Ahora (Bs ${widget.total.toStringAsFixed(2)})';
 } else if (_metodoPago == 'QR') {
 labelBoton = 'Generar Código QR';
 } else {
 labelBoton = 'Confirmar Pedido en Efectivo';
 }

 return Container(
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
 child: SizedBox(
 width: double.infinity,
 child: FilledButton.icon(
 onPressed: _procesando ? null : _procesarPago,
 style: FilledButton.styleFrom(
 padding: const EdgeInsets.symmetric(vertical: 16),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
 ),
 icon: _procesando
 ? const SizedBox(
 width: 20,
 height: 20,
 child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
 )
 : const Icon(Icons.lock_outline),
 label: Text(
 _procesando ? 'Procesando...' : labelBoton,
 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
 ),
 ),
 ),
 );
 }
}

/// Custom TextInputFormatter to format card number into 4-digit blocks.
class _CardNumberFormatter extends TextInputFormatter {
 @override
 TextEditingValue formatEditUpdate(
 TextEditingValue oldValue,
 TextEditingValue newValue,
 ) {
 final text = newValue.text.replaceAll(' ', '');
 final buffer = StringBuffer();
 for (int i = 0; i < text.length; i++) {
 buffer.write(text[i]);
 final nonZeroIndex = i + 1;
 if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
 buffer.write(' ');
 }
 }
 final formatted = buffer.toString();
 return TextEditingValue(
 text: formatted,
 selection: TextSelection.collapsed(offset: formatted.length),
 );
 }
}

/// Custom TextInputFormatter for MM/YY expiry dates.
class _ExpiryDateFormatter extends TextInputFormatter {
 @override
 TextEditingValue formatEditUpdate(
 TextEditingValue oldValue,
 TextEditingValue newValue,
 ) {
 final text = newValue.text.replaceAll('/', '');
 final buffer = StringBuffer();
 for (int i = 0; i < text.length; i++) {
 buffer.write(text[i]);
 final nonZeroIndex = i + 1;
 if (nonZeroIndex == 2 && nonZeroIndex != text.length) {
 buffer.write('/');
 }
 }
 final formatted = buffer.toString();
 return TextEditingValue(
 text: formatted,
 selection: TextSelection.collapsed(offset: formatted.length),
 );
 }
}

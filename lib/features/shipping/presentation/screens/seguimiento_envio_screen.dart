import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/envio_tracking_model.dart';
import '../../data/envios_service.dart';

/// Pantalla de Seguimiento de Envíos en tiempo real.
class SeguimientoEnvioScreen extends StatefulWidget {
 const SeguimientoEnvioScreen({
 super.key,
 this.idVenta,
 this.initialTracking,
 });

 final int? idVenta;
 final EnvioTrackingModel? initialTracking;

 @override
 State<SeguimientoEnvioScreen> createState() => _SeguimientoEnvioScreenState();
}

class _SeguimientoEnvioScreenState extends State<SeguimientoEnvioScreen> {
 EnvioTrackingModel? _tracking;
 List<EnvioTrackingModel> _misEnvios = [];
 bool _isLoading = true;
 String? _errorMessage;

 @override
 void initState() {
 super.initState();
 if (widget.initialTracking != null) {
 _tracking = widget.initialTracking;
 _isLoading = false;
 } else {
 _cargarSeguimiento();
 }
 }

 Future<void> _cargarSeguimiento() async {
 setState(() {
 _isLoading = true;
 _errorMessage = null;
 });

 if (widget.idVenta != null && widget.idVenta! > 0) {
 final result = await EnviosService.obtenerSeguimiento(widget.idVenta!);

 if (!mounted) return;

 setState(() {
 _isLoading = false;
 if (result['success'] == true) {
 _tracking = result['tracking'] as EnvioTrackingModel;
 _errorMessage = null;
 } else {
 _errorMessage = result['message'] as String? ??
 'No se pudo obtener el estado de tu envío.';
 }
 });
 } else {
 final result = await EnviosService.obtenerMisEnvios();

 if (!mounted) return;

 setState(() {
 _isLoading = false;
 if (result['success'] == true) {
 final list = result['envios'] as List<EnvioTrackingModel>;
 _misEnvios = list;
 if (list.isNotEmpty) {
 _tracking = list.first;
 _errorMessage = null;
 } else {
 _tracking = null;
 _errorMessage = null;
 }
 } else {
 _errorMessage = result['message'] as String? ??
 'Error al consultar tus envíos.';
 }
 });
 }
 }

 void _copiarCodigo(String codigo) {
 Clipboard.setData(ClipboardData(text: codigo));
 final messenger = ScaffoldMessenger.of(context);
 messenger.clearSnackBars();
 messenger.showSnackBar(
 SnackBar(
 content: Row(
 children: [
 const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
 const SizedBox(width: 8),
 Text('Código "$codigo" copiado al portapapeles.'),
 ],
 ),
 behavior: SnackBarBehavior.floating,
 duration: const Duration(seconds: 2),
 ),
 );
 }

 void _contactarRepartidor(String? telefono, String tipo) {
 final messenger = ScaffoldMessenger.of(context);
 messenger.clearSnackBars();
 messenger.showSnackBar(
 SnackBar(
 content: Row(
 children: [
 Icon(
 tipo == 'Llamar' ? Icons.phone_rounded : Icons.chat_rounded,
 color: Colors.white,
 size: 20,
 ),
 const SizedBox(width: 8),
 Text('$tipo al repartidor ($telefono)...'),
 ],
 ),
 behavior: SnackBarBehavior.floating,
 duration: const Duration(seconds: 2),
 ),
 );
 }

 @override
 Widget build(BuildContext context) {
 return Scaffold(
 appBar: AppBar(
 title: const Text(
 'Rastreo de Envío',
 style: TextStyle(fontWeight: FontWeight.bold),
 ),
 actions: [
 IconButton(
 icon: const Icon(Icons.refresh_rounded),
 tooltip: 'Actualizar estado',
 onPressed: _isLoading ? null : _cargarSeguimiento,
 ),
 ],
 ),
 body: _buildBody(context),
 );
 }

 Widget _buildBody(BuildContext context) {
 if (_isLoading && _tracking == null) {
 return const Center(
 child: Column(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 CircularProgressIndicator(),
 SizedBox(height: 16),
 Text('Localizando tu paquete...'),
 ],
 ),
 );
 }

 if (_errorMessage != null && _tracking == null) {
 final colorScheme = Theme.of(context).colorScheme;
 return Center(
 child: Padding(
 padding: const EdgeInsets.all(32),
 child: Column(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 Icon(Icons.location_off_rounded, size: 64, color: colorScheme.error),
 const SizedBox(height: 16),
 const Text(
 'No pudimos rastrear el envío',
 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
 textAlign: TextAlign.center,
 ),
 const SizedBox(height: 8),
 Text(
 _errorMessage!,
 style: TextStyle(
 color: colorScheme.onSurface.withValues(alpha: 0.7),
 fontSize: 13,
 ),
 textAlign: TextAlign.center,
 ),
 const SizedBox(height: 20),
 FilledButton.icon(
 onPressed: _cargarSeguimiento,
 icon: const Icon(Icons.refresh_rounded),
 label: const Text('Reintentar'),
 ),
 ],
 ),
 ),
 );
 }

 if (_tracking == null) {
 final colorScheme = Theme.of(context).colorScheme;
 return Center(
 child: Padding(
 padding: const EdgeInsets.all(32),
 child: Column(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 Container(
 padding: const EdgeInsets.all(24),
 decoration: BoxDecoration(
 color: colorScheme.primaryContainer.withValues(alpha: 0.3),
 shape: BoxShape.circle,
 ),
 child: Icon(
 Icons.local_shipping_outlined,
 size: 64,
 color: colorScheme.primary,
 ),
 ),
 const SizedBox(height: 20),
 const Text(
 'No tienes envíos registrados',
 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
 textAlign: TextAlign.center,
 ),
 const SizedBox(height: 8),
 Text(
 'Cuando realices compras con entrega a domicilio, podrás ver el rastreo del repartidor en tiempo real aquí.',
 style: TextStyle(
 color: colorScheme.onSurface.withValues(alpha: 0.7),
 fontSize: 13,
 height: 1.4,
 ),
 textAlign: TextAlign.center,
 ),
 const SizedBox(height: 24),
 FilledButton.tonalIcon(
 onPressed: () => Navigator.of(context).pop(),
 icon: const Icon(Icons.storefront_rounded),
 label: const Text('Explorar el Catálogo'),
 ),
 ],
 ),
 ),
 );
 }

 final t = _tracking!;
 return RefreshIndicator(
 onRefresh: _cargarSeguimiento,
 child: ListView(
 padding: const EdgeInsets.all(16),
 children: [
 // Selector de compras si hay múltiples envíos registrados
 if (_misEnvios.length > 1) ...[
 SingleChildScrollView(
 scrollDirection: Axis.horizontal,
 child: Row(
 children: _misEnvios.map((env) {
 final isSelected = env.idVenta == _tracking?.idVenta;
 return Padding(
 padding: const EdgeInsets.only(right: 8),
 child: ChoiceChip(
 label: Text('#${env.codigoVenta} (${env.estadoLegible})'),
 selected: isSelected,
 onSelected: (val) {
 if (val) setState(() => _tracking = env);
 },
 ),
 );
 }).toList(),
 ),
 ),
 const SizedBox(height: 12),
 ],
 // 1. HEADER CARD: Estado general y código
 _buildHeaderCard(context, t),
 const SizedBox(height: 16),

 // 2. TIMELINE VISUAL STEPPER
 _buildTimelineCard(context, t),
 const SizedBox(height: 16),

 // 3. REPARTIDOR ASIGNADO
 if (t.repartidorNombre != null) ...[
 _buildRepartidorCard(context, t),
 const SizedBox(height: 16),
 ],

 // 4. DIRECCIÓN DE ENTREGA
 _buildDestinoCard(context, t),
 const SizedBox(height: 16),

 // 5. RESUMEN DE LA ORDEN
 _buildOrdenInfoCard(context, t),
 const SizedBox(height: 24),
 ],
 ),
 );
 }

 Widget _buildHeaderCard(BuildContext context, EnvioTrackingModel t) {
 final colorScheme = Theme.of(context).colorScheme;

 return Container(
 padding: const EdgeInsets.all(18),
 decoration: BoxDecoration(
 color: colorScheme.surface,
 borderRadius: BorderRadius.circular(20),
 border: Border.all(
 color: t.colorEstado.withValues(alpha: 0.35),
 width: 1.5,
 ),
 boxShadow: [
 BoxShadow(
 color: t.colorEstado.withValues(alpha: 0.08),
 blurRadius: 10,
 offset: const Offset(0, 4),
 ),
 ],
 ),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 children: [
 Container(
 padding: const EdgeInsets.all(10),
 decoration: BoxDecoration(
 color: t.colorEstado.withValues(alpha: 0.12),
 shape: BoxShape.circle,
 ),
 child: Icon(t.iconoEstado, color: t.colorEstado, size: 28),
 ),
 const SizedBox(width: 12),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 t.estadoLegible,
 style: TextStyle(
 fontSize: 17,
 fontWeight: FontWeight.bold,
 color: t.colorEstado,
 ),
 ),
 const SizedBox(height: 2),
 Text(
 'Agencia: ${t.agencia ?? "Attention Delivery"}',
 style: TextStyle(
 fontSize: 12,
 color: colorScheme.onSurface.withValues(alpha: 0.6),
 ),
 ),
 ],
 ),
 ),
 ],
 ),
 const Divider(height: 24),
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 'Código de seguimiento:',
 style: TextStyle(
 fontSize: 11,
 color: colorScheme.onSurface.withValues(alpha: 0.6),
 ),
 ),
 const SizedBox(height: 2),
 Row(
 children: [
 Text(
 t.codigoRastreo,
 style: const TextStyle(
 fontFamily: 'monospace',
 fontWeight: FontWeight.bold,
 fontSize: 14,
 ),
 ),
 const SizedBox(width: 6),
 InkWell(
 onTap: () => _copiarCodigo(t.codigoRastreo),
 borderRadius: BorderRadius.circular(6),
 child: Icon(
 Icons.copy_rounded,
 size: 16,
 color: colorScheme.primary,
 ),
 ),
 ],
 ),
 ],
 ),
 Column(
 crossAxisAlignment: CrossAxisAlignment.end,
 children: [
 Text(
 'Entrega estimada:',
 style: TextStyle(
 fontSize: 11,
 color: colorScheme.onSurface.withValues(alpha: 0.6),
 ),
 ),
 const SizedBox(height: 2),
 Text(
 t.fechaEstimadaFormateada,
 style: const TextStyle(
 fontWeight: FontWeight.bold,
 fontSize: 13,
 ),
 ),
 ],
 ),
 ],
 ),
 ],
 ),
 );
 }

 Widget _buildTimelineCard(BuildContext context, EnvioTrackingModel t) {
 final colorScheme = Theme.of(context).colorScheme;

 return Card(
 elevation: 0,
 shape: RoundedRectangleBorder(
 borderRadius: BorderRadius.circular(20),
 side: BorderSide(
 color: colorScheme.outlineVariant.withValues(alpha: 0.4),
 ),
 ),
 child: Padding(
 padding: const EdgeInsets.all(18),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 const Text(
 'Trazabilidad de la Entrega',
 style: TextStyle(
 fontWeight: FontWeight.bold,
 fontSize: 16,
 ),
 ),
 const SizedBox(height: 16),
 ...t.hitos.asMap().entries.map((entry) {
 final idx = entry.key;
 final hito = entry.value;
 final isLast = idx == t.hitos.length - 1;
 return _buildTimelineItem(context, hito, isLast);
 }),
 ],
 ),
 ),
 );
 }

 Widget _buildTimelineItem(
 BuildContext context,
 HitoSeguimientoModel hito,
 bool isLast,
 ) {
 final colorScheme = Theme.of(context).colorScheme;

 Color iconColor;
 Color dotBg;
 IconData icon;

 if (hito.completado) {
 iconColor = Colors.white;
 dotBg = Colors.green.shade600;
 icon = Icons.check;
 } else if (hito.enCurso) {
 iconColor = Colors.white;
 dotBg = colorScheme.primary;
 icon = Icons.sync_rounded;
 } else {
 iconColor = colorScheme.outline;
 dotBg = colorScheme.surfaceContainerHighest;
 icon = Icons.radio_button_unchecked;
 }

 return IntrinsicHeight(
 child: Row(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Left: Indicator and connecting line
 Column(
 children: [
 Container(
 width: 28,
 height: 28,
 decoration: BoxDecoration(
 color: dotBg,
 shape: BoxShape.circle,
 boxShadow: hito.enCurso
 ? [
 BoxShadow(
 color: colorScheme.primary.withValues(alpha: 0.4),
 blurRadius: 6,
 spreadRadius: 2,
 ),
 ]
 : null,
 ),
 child: Icon(icon, color: iconColor, size: 16),
 ),
 if (!isLast)
 Expanded(
 child: Container(
 width: 2.5,
 color: hito.completado
 ? Colors.green.shade500
 : colorScheme.outlineVariant.withValues(alpha: 0.5),
 ),
 ),
 ],
 ),
 const SizedBox(width: 14),

 // Right: Content
 Expanded(
 child: Padding(
 padding: const EdgeInsets.only(bottom: 20),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 children: [
 Expanded(
 child: Text(
 hito.titulo,
 style: TextStyle(
 fontWeight: hito.enCurso || hito.completado
 ? FontWeight.bold
 : FontWeight.normal,
 fontSize: 14.5,
 color: hito.enCurso
 ? colorScheme.primary
 : colorScheme.onSurface,
 ),
 ),
 ),
 if (hito.enCurso)
 Container(
 padding: const EdgeInsets.symmetric(
 horizontal: 6,
 vertical: 1,
 ),
 decoration: BoxDecoration(
 color: colorScheme.primaryContainer,
 borderRadius: BorderRadius.circular(10),
 ),
 child: Text(
 'En progreso',
 style: TextStyle(
 fontSize: 10,
 fontWeight: FontWeight.bold,
 color: colorScheme.primary,
 ),
 ),
 ),
 ],
 ),
 const SizedBox(height: 2),
 Text(
 hito.descripcion,
 style: TextStyle(
 fontSize: 12.5,
 color: colorScheme.onSurface.withValues(alpha: 0.7),
 height: 1.3,
 ),
 ),
 if (hito.fecha != null) ...[
 const SizedBox(height: 4),
 Text(
 hito.fechaFormateada,
 style: TextStyle(
 fontSize: 11,
 color: colorScheme.onSurface.withValues(alpha: 0.5),
 fontWeight: FontWeight.w500,
 ),
 ),
 ],
 ],
 ),
 ),
 ),
 ],
 ),
 );
 }

 Widget _buildRepartidorCard(BuildContext context, EnvioTrackingModel t) {
 final colorScheme = Theme.of(context).colorScheme;

 return Card(
 elevation: 0,
 shape: RoundedRectangleBorder(
 borderRadius: BorderRadius.circular(20),
 side: BorderSide(
 color: colorScheme.outlineVariant.withValues(alpha: 0.4),
 ),
 ),
 child: Padding(
 padding: const EdgeInsets.all(16),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 const Text(
 'Repartidor Asignado',
 style: TextStyle(
 fontWeight: FontWeight.bold,
 fontSize: 15,
 ),
 ),
 const SizedBox(height: 12),
 Row(
 children: [
 CircleAvatar(
 radius: 24,
 backgroundColor: colorScheme.primaryContainer,
 child: Icon(
 Icons.two_wheeler_rounded,
 color: colorScheme.primary,
 size: 26,
 ),
 ),
 const SizedBox(width: 14),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 t.repartidorNombre ?? 'Repartidor Attention',
 style: const TextStyle(
 fontWeight: FontWeight.bold,
 fontSize: 14.5,
 ),
 ),
 const SizedBox(height: 2),
 Text(
 t.repartidorVehiculo ?? 'Vehículo oficial',
 style: TextStyle(
 fontSize: 12,
 color: colorScheme.onSurface.withValues(alpha: 0.65),
 ),
 ),
 ],
 ),
 ),
 ],
 ),
 const SizedBox(height: 14),
 Row(
 children: [
 Expanded(
 child: OutlinedButton.icon(
 onPressed: () => _contactarRepartidor(
 t.repartidorTelefono,
 'Llamar',
 ),
 icon: const Icon(Icons.phone_rounded, size: 18),
 label: const Text('Llamar'),
 ),
 ),
 const SizedBox(width: 10),
 Expanded(
 child: FilledButton.tonalIcon(
 onPressed: () => _contactarRepartidor(
 t.repartidorTelefono,
 'Enviar WhatsApp',
 ),
 icon: const Icon(Icons.chat_rounded, size: 18),
 label: const Text('WhatsApp'),
 ),
 ),
 ],
 ),
 ],
 ),
 ),
 );
 }

 Widget _buildDestinoCard(BuildContext context, EnvioTrackingModel t) {
 final colorScheme = Theme.of(context).colorScheme;

 return Card(
 elevation: 0,
 shape: RoundedRectangleBorder(
 borderRadius: BorderRadius.circular(20),
 side: BorderSide(
 color: colorScheme.outlineVariant.withValues(alpha: 0.4),
 ),
 ),
 child: Padding(
 padding: const EdgeInsets.all(16),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 const Text(
 'Destino de la Entrega',
 style: TextStyle(
 fontWeight: FontWeight.bold,
 fontSize: 15,
 ),
 ),
 const SizedBox(height: 12),
 _infoRow(
 context,
 icon: Icons.person_outline_rounded,
 title: 'Recibe:',
 value: t.destinatario,
 ),
 const SizedBox(height: 8),
 _infoRow(
 context,
 icon: Icons.location_on_outlined,
 title: 'Dirección:',
 value: '${t.direccionEntrega}, ${t.ciudad}',
 ),
 if (t.referencia != null && t.referencia!.isNotEmpty) ...[
 const SizedBox(height: 8),
 _infoRow(
 context,
 icon: Icons.info_outline_rounded,
 title: 'Referencia:',
 value: t.referencia!,
 ),
 ],
 const SizedBox(height: 8),
 _infoRow(
 context,
 icon: Icons.phone_outlined,
 title: 'Teléfono:',
 value: t.telefono,
 ),
 ],
 ),
 ),
 );
 }

 Widget _buildOrdenInfoCard(BuildContext context, EnvioTrackingModel t) {
 final colorScheme = Theme.of(context).colorScheme;

 return Card(
 elevation: 0,
 shape: RoundedRectangleBorder(
 borderRadius: BorderRadius.circular(20),
 side: BorderSide(
 color: colorScheme.outlineVariant.withValues(alpha: 0.4),
 ),
 ),
 child: Padding(
 padding: const EdgeInsets.all(16),
 child: Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 'Pedido #${t.codigoVenta}',
 style: const TextStyle(fontWeight: FontWeight.bold),
 ),
 const SizedBox(height: 2),
 Text(
 '${t.totalPrendas} prenda(s) • Total: Bs ${t.totalVenta.toStringAsFixed(2)}',
 style: TextStyle(
 fontSize: 12,
 color: colorScheme.onSurface.withValues(alpha: 0.65),
 ),
 ),
 ],
 ),
 TextButton(
 onPressed: () => Navigator.of(context).pop(),
 child: const Text('Cerrar'),
 ),
 ],
 ),
 ),
 );
 }

 Widget _infoRow(
 BuildContext context, {
 required IconData icon,
 required String title,
 required String value,
 }) {
 final colorScheme = Theme.of(context).colorScheme;
 return Row(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Icon(icon, size: 18, color: colorScheme.primary),
 const SizedBox(width: 10),
 Text(
 title,
 style: TextStyle(
 fontWeight: FontWeight.w600,
 fontSize: 13,
 color: colorScheme.onSurface.withValues(alpha: 0.8),
 ),
 ),
 const SizedBox(width: 6),
 Expanded(
 child: Text(
 value,
 style: const TextStyle(fontSize: 13),
 ),
 ),
 ],
 );
 }
}

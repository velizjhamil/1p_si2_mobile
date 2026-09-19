import 'package:flutter/material.dart';

import '../../../../core/storage/secure_storage_service.dart';
import '../../data/checkout_service.dart';
import '../../logic/cart_service.dart';

/// Modal bottom sheet for finalizing the checkout (CU21).
class CheckoutModal extends StatefulWidget {
  const CheckoutModal({super.key});

  @override
  State<CheckoutModal> createState() => _CheckoutModalState();
}

class _CheckoutModalState extends State<CheckoutModal> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _ciudadController = TextEditingController(text: 'Santa Cruz de la Sierra');
  final _referenciaController = TextEditingController();

  String _metodoPago = 'QR'; // QR | EFECTIVO | TARJETA
  bool _procesando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserSession();
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

  Future<void> _submitCheckout() async {
    if (!_formKey.currentState!.validate()) return;

    final cart = CartService.instance;
    if (cart.items.isEmpty) return;

    setState(() {
      _procesando = true;
      _error = null;
    });

    final result = await CheckoutService.procesarCompra(
      items: cart.items,
      metodoPago: _metodoPago,
      nombreCliente: _nombreController.text.trim(),
      correo: _correoController.text.trim(),
      telefono: _telefonoController.text.trim(),
      direccion: _direccionController.text.trim(),
      ciudad: _ciudadController.text.trim(),
      referencia: _referenciaController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _procesando = false);

    if (result['success'] == true) {
      final venta = result['venta'] as Map<String, dynamic>?;
      final codigo = venta?['codigo'] as String? ?? 'ATT-${DateTime.now().millisecondsSinceEpoch % 1000000}';
      final total = cart.total;

      // Clear shopping cart
      cart.clear();

      Navigator.of(context).pop(); // Close checkout sheet

      // Show success dialog
      _showSuccessDialog(codigo: codigo, total: total);
    } else {
      setState(() {
        _error = result['message'] as String? ?? 'Ocurrió un error al procesar el pedido.';
      });
    }
  }

  void _showSuccessDialog({required String codigo, required double total}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, size: 48, color: Colors.green),
          ),
          title: const Text('¡Pedido Confirmado!', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tu compra ha sido procesada con éxito.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    const Text('Código de Comprobante:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(
                      codigo,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Theme.of(ctx).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Total pagado: Bs ${total.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                'Método de pago: $_metodoPago',
                style: TextStyle(fontSize: 12, color: Theme.of(ctx).colorScheme.outline),
              ),
            ],
          ),
          actions: [
            Center(
              child: FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Entendido y Finalizar'),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final cart = CartService.instance;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.shopping_bag_rounded, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Finalizar Compra',
                    style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Ingresa tus datos para la entrega y confirmación de la venta.',
                style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
              ),
              const SizedBox(height: 16),

              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colorScheme.error.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, size: 20, color: colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: colorScheme.error, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Delivery details
              Text('Datos de Entrega', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo *',
                  prefixIcon: Icon(Icons.person_outline),
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().length < 3) ? 'Ingresa tu nombre' : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _correoController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico *',
                        prefixIcon: Icon(Icons.email_outlined),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || !v.contains('@')) ? 'Correo inválido' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _telefonoController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono / WhatsApp *',
                        prefixIcon: Icon(Icons.phone_outlined),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().length < 6) ? 'Teléfono requerido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _direccionController,
                decoration: const InputDecoration(
                  labelText: 'Dirección de envío (Calle, Nro) *',
                  prefixIcon: Icon(Icons.home_outlined),
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().length < 4) ? 'Ingresa tu dirección' : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ciudadController,
                      decoration: const InputDecoration(
                        labelText: 'Ciudad *',
                        prefixIcon: Icon(Icons.location_city_outlined),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Ciudad requerida' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _referenciaController,
                      decoration: const InputDecoration(
                        labelText: 'Referencia (opcional)',
                        prefixIcon: Icon(Icons.info_outline),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Payment method
              Text('Método de Pago', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _PaymentOption(
                    title: 'Pago QR',
                    icon: Icons.qr_code_2_rounded,
                    isSelected: _metodoPago == 'QR',
                    onTap: () => setState(() => _metodoPago = 'QR'),
                  ),
                  const SizedBox(width: 8),
                  _PaymentOption(
                    title: 'Tarjeta',
                    icon: Icons.credit_card_rounded,
                    isSelected: _metodoPago == 'TARJETA',
                    onTap: () => setState(() => _metodoPago = 'TARJETA'),
                  ),
                  const SizedBox(width: 8),
                  _PaymentOption(
                    title: 'Efectivo',
                    icon: Icons.payments_outlined,
                    isSelected: _metodoPago == 'EFECTIVO',
                    onTap: () => setState(() => _metodoPago = 'EFECTIVO'),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Order pricing summary
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:'),
                        Text('Bs ${cart.subtotal.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text('Costo de envío:'),
                            if (cart.isEnvioGratis) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('¡Gratis!', style: TextStyle(color: Colors.green.shade800, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                        Text(cart.isEnvioGratis ? 'Bs 0.00' : 'Bs ${cart.costoEnvio.toStringAsFixed(2)}'),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total a pagar:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          'Bs ${cart.total.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Submit button
              FilledButton.icon(
                onPressed: _procesando ? null : _submitCheckout,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _procesando
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.lock_outline),
                label: Text(
                  _procesando ? 'Procesando compra...' : 'Confirmar y Pagar (Bs ${cart.total.toStringAsFixed(2)})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primaryContainer.withValues(alpha: 0.5) : colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: isSelected ? colorScheme.primary : colorScheme.onSurface),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

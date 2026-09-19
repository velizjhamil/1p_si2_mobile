import 'package:flutter/material.dart';

import '../../data/cart_item.dart';
import '../../logic/cart_service.dart';
import '../widgets/checkout_modal.dart';

/// Shopping cart screen (CU15) displaying client selected items,
/// quantity controls, shipping calculation, and checkout trigger.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  void _openCheckout(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const CheckoutModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: CartService.instance,
      builder: (context, _) {
        final cart = CartService.instance;
        final isEmpty = cart.items.isEmpty;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mi Carrito de Compras'),
            actions: [
              if (!isEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined),
                  tooltip: 'Vaciar carrito',
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Vaciar carrito'),
                        content: const Text('¿Deseas remover todos los artículos del carrito?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton(
                            onPressed: () {
                              cart.clear();
                              Navigator.of(ctx).pop();
                            },
                            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
                            child: const Text('Vaciar'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
          body: isEmpty
              ? _buildEmptyState(context)
              : Column(
                  children: [
                    // Free shipping indicator banner
                    _buildShippingBanner(context, cart),

                    // Items list
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        itemCount: cart.items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = cart.items[index];
                          return _CartItemCard(
                            item: item,
                            onIncrement: () => cart.updateQuantity(item, 1),
                            onDecrement: () => cart.updateQuantity(item, -1),
                            onRemove: () => cart.removeItem(item),
                          );
                        },
                      ),
                    ),

                    // Bottom checkout summary panel
                    _buildSummaryPanel(context, cart),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildShippingBanner(BuildContext context, CartService cart) {
    final isFree = cart.isEnvioGratis;
    final falta = CartService.envioGratisDesde - cart.subtotal;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isFree ? Colors.green.shade50 : Colors.amber.shade50,
      child: Row(
        children: [
          Icon(
            isFree ? Icons.local_shipping_rounded : Icons.info_outline_rounded,
            size: 20,
            color: isFree ? Colors.green.shade800 : Colors.amber.shade900,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isFree
                  ? '¡Felicidades! Tienes Envío Gratis en este pedido.'
                  : 'Agrega Bs ${falta.toStringAsFixed(2)} más para obtener ¡Envío Gratis!',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isFree ? Colors.green.shade900 : Colors.amber.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPanel(BuildContext context, CartService cart) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal:'),
                Text(
                  'Bs ${cart.subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Costo de envío:'),
                Text(
                  cart.isEnvioGratis ? 'Gratis' : 'Bs ${cart.costoEnvio.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: cart.isEnvioGratis ? Colors.green.shade700 : null,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _openCheckout(context),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(
                  'Continuar al Pago (${cart.totalItemCount} prendas)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 72,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tu carrito está vacío',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Explora las prendas del catálogo y agrégalas para comprarlas o reservarlas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.storefront_rounded),
              label: const Text('Explorar Prendas'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final hasImage = item.imagenUrl != null &&
        item.imagenUrl!.isNotEmpty &&
        item.imagenUrl!.startsWith('http');

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 70,
                height: 70,
                color: colorScheme.primaryContainer.withValues(alpha: 0.25),
                child: hasImage
                    ? Image.network(
                        item.imagenUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(Icons.checkroom_outlined),
                      )
                    : const Icon(Icons.checkroom_outlined),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children: [
                      if (item.talla?.isNotEmpty == true)
                        _TagChip(label: 'Talla: ${item.talla!}'),
                      if (item.color?.isNotEmpty == true)
                        _TagChip(label: 'Color: ${item.color!}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bs ${item.precioUnitario.toStringAsFixed(2)} c/u',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Stepper controls
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.close, size: 18, color: colorScheme.error),
                  tooltip: 'Remover',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onRemove,
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: onDecrement,
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.remove, size: 16),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '${item.cantidad}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      InkWell(
                        onTap: onIncrement,
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.add, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../ar_tryon/presentation/screens/probador_virtual_screen.dart';
import '../../../cart/logic/cart_service.dart';
import '../../../cart/presentation/screens/cart_screen.dart';
import '../../../reservations/presentation/widgets/crear_reserva_dialog.dart';
import '../../data/productos_service.dart';

/// Interactive client-oriented bottom sheet for garment inspection,
/// size/color selection, adding to cart, or reserving in store.
class ProductDetailSheet extends StatefulWidget {
  const ProductDetailSheet({super.key, required this.producto});

  final Producto producto;

  @override
  State<ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<ProductDetailSheet> {
  String? _tallaSeleccionada;
  String? _colorSeleccionado;
  int _cantidad = 1;

  @override
  void initState() {
    super.initState();
    if (widget.producto.tallas.isNotEmpty) {
      _tallaSeleccionada = widget.producto.tallas.first;
    }
    if (widget.producto.colores.isNotEmpty) {
      _colorSeleccionado = widget.producto.colores.first.nombre;
    }
  }

  void _agregarAlCarrito() {
    CartService.instance.addItem(
      idProducto: widget.producto.idProducto,
      nombre: widget.producto.nombre,
      precioUnitario: widget.producto.precioVenta,
      cantidad: _cantidad,
      talla: _tallaSeleccionada,
      color: _colorSeleccionado,
      imagenUrl: widget.producto.imagenUrl,
    );

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡${widget.producto.nombre} agregada al carrito!'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Ver Carrito',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CartScreen()),
            );
          },
        ),
      ),
    );
  }

  void _abrirReserva() {
    showDialog<bool>(
      context: context,
      builder: (_) => CrearReservaDialog(
        idProducto: widget.producto.idProducto,
        nombreProducto: widget.producto.nombre,
        precioUnitario: widget.producto.precioVenta,
        talla: _tallaSeleccionada,
        color: _colorSeleccionado,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final hasImage = widget.producto.imagenUrl != null &&
        widget.producto.imagenUrl!.isNotEmpty &&
        widget.producto.imagenUrl!.startsWith('http');

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Product Hero image / placeholder
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 200,
                color: colorScheme.primaryContainer.withValues(alpha: 0.25),
                child: hasImage
                    ? Image.network(
                        widget.producto.imagenUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.checkroom_rounded,
                          size: 64,
                          color: Colors.grey,
                        ),
                      )
                    : const Icon(
                        Icons.checkroom_rounded,
                        size: 64,
                        color: Colors.grey,
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Name & Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.producto.nombre,
                    style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  'Bs ${widget.producto.precioVenta.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Description
            if (widget.producto.descripcion?.isNotEmpty == true) ...[
              Text(
                widget.producto.descripcion!,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.75),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Size Selector
            if (widget.producto.tallas.isNotEmpty) ...[
              Text('Seleccionar Talla:', style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: widget.producto.tallas.map((t) {
                  final isSelected = _tallaSeleccionada == t;
                  return ChoiceChip(
                    label: Text(t),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _tallaSeleccionada = t);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
            ],

            // Color Selector
            if (widget.producto.colores.isNotEmpty) ...[
              Text('Color:', style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: widget.producto.colores.map((c) {
                  final isSelected = _colorSeleccionado == c.nombre;
                  return ChoiceChip(
                    avatar: c.hex != null
                        ? CircleAvatar(
                            backgroundColor: _parseColor(c.hex!),
                            radius: 8,
                          )
                        : null,
                    label: Text(c.nombre),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _colorSeleccionado = c.nombre);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
            ],

            // Quantity Stepper
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Cantidad:', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _cantidad > 1 ? () => setState(() => _cantidad--) : null,
                    ),
                    Text('$_cantidad', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => setState(() => _cantidad++),
                    ),
                  ],
                ),
              ],
            ),
            // Try in Virtual Fitting Room Button
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProbadorVirtualScreen(
                      prendaInicial: widget.producto,
                      tallaInicial: _tallaSeleccionada,
                      colorInicial: _colorSeleccionado,
                    ),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.purple.shade700,
                side: BorderSide(color: Colors.purple.shade300),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text(
                'Probar en Probador Virtual IA (CU25)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _abrirReserva,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.bookmark_border_rounded),
                    label: const Text('Reservar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _agregarAlCarrito,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add_shopping_cart_rounded),
                    label: const Text('Añadir al Carrito', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    var cleanHex = hex.replaceAll('#', '').trim();
    if (cleanHex.length == 6) {
      cleanHex = 'FF$cleanHex';
    }
    final parsed = int.tryParse(cleanHex, radix: 16);
    if (parsed == null) return Colors.grey;
    return Color(parsed);
  }
}

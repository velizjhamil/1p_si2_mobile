import 'package:flutter/material.dart';

import '../../../ar_tryon/presentation/screens/probador_virtual_screen.dart';
import '../../../cart/logic/cart_service.dart';
import '../../../cart/presentation/screens/cart_screen.dart';
import '../../../promotions/data/descuento_model.dart';
import '../../../reservations/presentation/widgets/crear_reserva_dialog.dart';
import '../../data/productos_service.dart';

/// Interactive client-oriented bottom sheet for garment inspection,
/// size/color selection, promotional pricing, branch stock inspection, and reserving.
class ProductDetailSheet extends StatefulWidget {
  const ProductDetailSheet({
    super.key,
    required this.producto,
    this.descuento,
    this.idSucursalSeleccionada,
  });

  final Producto producto;
  final DescuentoModel? descuento;
  final int? idSucursalSeleccionada;

  @override
  State<ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<ProductDetailSheet> {
  String? _tallaSeleccionada;
  String? _colorSeleccionado;
  int _cantidad = 1;
  bool _isAdding = false;

  double get _precioFinal {
    final desc = widget.descuento;
    if (desc != null && desc.activo) {
      if (desc.esPorcentaje) {
        return (widget.producto.precioVenta * (1.0 - (desc.valor / 100.0)))
            .clamp(0.0, double.infinity);
      } else {
        return (widget.producto.precioVenta - desc.valor)
            .clamp(0.0, double.infinity);
      }
    }
    return widget.producto.precioVenta;
  }

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

  Future<void> _agregarAlCarrito() async {
    if (_isAdding) return;

    setState(() => _isAdding = true);

    try {
      CartService.instance.addItem(
        idProducto: widget.producto.idProducto,
        nombre: widget.producto.nombre,
        precioUnitario: _precioFinal,
        cantidad: _cantidad,
        talla: _tallaSeleccionada,
        color: _colorSeleccionado,
        imagenUrl: widget.producto.imagenUrl,
      );

      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);

      // Close the bottom sheet modal cleanly
      navigator.pop();

      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text('¡${widget.producto.nombre} agregada al carrito!'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'Ver Carrito',
            onPressed: () {
              messenger.hideCurrentSnackBar();
              navigator.push(
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error al agregar al carrito: $e'),
            duration: const Duration(seconds: 2),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  void _abrirReserva() {
    showDialog<bool>(
      context: context,
      builder: (_) => CrearReservaDialog(
        idProducto: widget.producto.idProducto,
        nombreProducto: widget.producto.nombre,
        precioUnitario: _precioFinal,
        talla: _tallaSeleccionada,
        color: _colorSeleccionado,
        idSucursalInicial: widget.idSucursalSeleccionada,
        disponibilidadSucursales: widget.producto.disponibilidadSucursales,
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

    final tieneDescuento = widget.descuento != null && _precioFinal < widget.producto.precioVenta;

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
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    hasImage
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
                    if (tieneDescuento)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade700,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(40),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Text(
                            widget.descuento!.badgeTexto,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Name & Price (with promo discount)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.producto.nombre,
                        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (tieneDescuento) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            '🔥 Oferta activa: ${widget.descuento!.nombre}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Bs ${_precioFinal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    if (tieneDescuento)
                      Text(
                        'Bs ${widget.producto.precioVenta.toStringAsFixed(2)}',
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: colorScheme.outline,
                          fontSize: 13,
                        ),
                      ),
                  ],
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

            // Disponibilidad por Sucursal en tiempo real
            if (widget.producto.disponibilidadSucursales.isNotEmpty) ...[
              Text(
                'Disponibilidad en Tiendas / Sucursales:',
                style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...widget.producto.disponibilidadSucursales.map((suc) {
                final isLowStock = suc.stock > 0 && suc.stock <= 5;
                final isOutOfStock = suc.stock <= 0;
                final isSelectedBranch = widget.idSucursalSeleccionada == suc.idSucursal;

                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isOutOfStock
                        ? Colors.grey.shade100
                        : (isSelectedBranch
                            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                            : (isLowStock ? Colors.amber.shade50 : Colors.green.shade50)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isOutOfStock
                          ? Colors.grey.shade300
                          : (isSelectedBranch
                              ? colorScheme.primary
                              : (isLowStock ? Colors.amber.shade300 : Colors.green.shade200)),
                      width: isSelectedBranch ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isOutOfStock
                            ? Icons.store_outlined
                            : (isLowStock ? Icons.warning_amber_rounded : Icons.store_rounded),
                        size: 18,
                        color: isOutOfStock
                            ? Colors.grey.shade600
                            : (isLowStock ? Colors.amber.shade800 : Colors.green.shade700),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          suc.nombreSucursal + (suc.ciudad != null ? ' (${suc.ciudad})' : ''),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isOutOfStock ? Colors.grey.shade700 : Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isOutOfStock
                              ? Colors.grey.shade300
                              : (isLowStock ? Colors.amber.shade200 : Colors.green.shade200),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isOutOfStock
                              ? 'Agotado'
                              : (isLowStock ? '¡Últimas ${suc.stock} unids!' : '${suc.stock} disponibles'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isOutOfStock
                                ? Colors.grey.shade800
                                : (isLowStock ? Colors.amber.shade900 : Colors.green.shade900),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
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
            const SizedBox(height: 8),

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
                'Vestidor Virtual (Probarse Prenda)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),

            // Action Buttons (Reservar + Añadir al Carrito)
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
                    label: const Text('Reservar Prenda'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _isAdding ? null : _agregarAlCarrito,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _isAdding
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add_shopping_cart_rounded),
                    label: Text(
                      _isAdding ? 'Añadiendo...' : 'Añadir al Carrito',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
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

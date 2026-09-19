import 'package:flutter/material.dart';

import '../../data/compra_service.dart';
import 'mis_compras_screen.dart';

/// Screen displaying the digital receipt / voucher after a successful purchase.
class ComprobanteScreen extends StatelessWidget {
  const ComprobanteScreen({super.key, required this.venta});

  final VentaModel venta;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final fechaStr = venta.fechaVenta != null
        ? "${venta.fechaVenta!.day}/${venta.fechaVenta!.month}/${venta.fechaVenta!.year} ${venta.fechaVenta!.hour.toString().padLeft(2, '0')}:${venta.fechaVenta!.minute.toString().padLeft(2, '0')}"
        : "Reciente";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comprobante de Compra'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Success Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, size: 36, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '¡Compra Procesada con Éxito!',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gracias por tu preferencia en Attention E-Commerce.',
                    style: TextStyle(fontSize: 12, color: Colors.green.shade800),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Voucher Ticket Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Code and Date Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Código de Pedido', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text(
                              venta.codigo,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Text(
                            venta.estadoPago,
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Fecha: $fechaStr',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const Divider(height: 24),

                    // Products list
                    Text(
                      'Prendas Adquiridas:',
                      style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ...venta.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item.cantidad}x ',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.nombre,
                                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                                  ),
                                  if (item.talla != null || item.color != null)
                                    Text(
                                      '${item.talla != null ? "Talla: ${item.talla} " : ""}${item.color != null ? "• Color: ${item.color}" : ""}',
                                      style: TextStyle(fontSize: 11, color: colorScheme.outline),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              'Bs ${item.subtotal.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }),

                    const Divider(height: 24),

                    // Delivery data
                    if (venta.datosEntrega != null) ...[
                      Text(
                        'Datos de Envío y Facturación:',
                        style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildReceiptRow('Destinatario:', venta.datosEntrega!.nombreCliente),
                      _buildReceiptRow('Teléfono:', venta.datosEntrega!.telefono),
                      _buildReceiptRow('Dirección:', venta.datosEntrega!.direccion),
                      _buildReceiptRow('Ciudad:', venta.datosEntrega!.ciudad),
                      if (venta.datosEntrega!.referencia?.isNotEmpty == true)
                        _buildReceiptRow('Referencia:', venta.datosEntrega!.referencia!),
                      const Divider(height: 24),
                    ],

                    // Payment and totals breakdown
                    _buildReceiptRow('Método de Pago:', venta.metodoPago),
                    _buildReceiptRow(
                      'Costo de Envío:',
                      venta.costoEnvio == 0 ? 'Gratis' : 'Bs ${venta.costoEnvio.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Pagado:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Bs ${venta.total.toStringAsFixed(2)}',
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
            ),
            const SizedBox(height: 24),

            // Action Buttons
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const MisComprasScreen()),
                );
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.receipt_long_rounded),
              label: const Text('Ver Mis Compras', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Volver a la Tienda'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

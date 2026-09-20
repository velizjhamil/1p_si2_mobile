import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:si2_mobile/features/orders/data/compras_cliente_service.dart';
import 'package:si2_mobile/features/orders/presentation/screens/detalle_compra_screen.dart';
import 'package:si2_mobile/features/orders/presentation/screens/historial_compras_screen.dart';

void main() {
  group('CU11 - HistorialComprasScreen and DetalleCompraScreen Widget Tests', () {
    testWidgets('DetalleCompraScreen renders complete order information and products',
        (WidgetTester tester) async {
      const mockCompra = CompraClienteModel(
        idVenta: 10,
        codigo: 'ATT-778899',
        total: 350.0,
        costoEnvio: 0.0,
        metodoPago: 'QR',
        estadoPago: 'PAGADO',
        items: [
          CompraClienteItemModel(
            idDetalle: 1,
            productoId: 3,
            nombre: 'Chaqueta Bomber Premium',
            talla: 'L',
            color: 'Verde Militar',
            cantidad: 1,
            precioUnitario: 350.0,
            subtotal: 350.0,
          ),
        ],
        datosEntrega: CompraClienteEntregaModel(
          nombreCliente: 'Carlos Suárez',
          correo: 'carlos@example.com',
          telefono: '77345678',
          direccion: 'Av. Las Américas #500',
          ciudad: 'Santa Cruz',
          referencia: 'Edificio Torre Real piso 3',
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: DetalleCompraScreen(compra: mockCompra),
        ),
      );

      // Verify header and code
      expect(find.text('ATT-778899'), findsWidgets);
      expect(find.text('¡Compra Completada!'), findsOneWidget);
      expect(find.text('Completada'), findsWidgets);

      // Verify product items
      expect(find.text('Chaqueta Bomber Premium'), findsOneWidget);
      expect(find.text('1x'), findsOneWidget);
      expect(find.text('Bs 350.00'), findsWidgets);

      // Verify delivery details
      expect(find.text('Carlos Suárez'), findsOneWidget);
      expect(find.text('Av. Las Américas #500'), findsOneWidget);
      expect(find.text('Santa Cruz'), findsOneWidget);

      // Verify financial summary
      expect(find.text('Gratis'), findsOneWidget);
      expect(find.text('Total Cancelado:'), findsOneWidget);

      // Verify action buttons
      expect(find.text('Volver al Historial'), findsOneWidget);
      expect(find.text('Ir a la Tienda'), findsOneWidget);
    });

    testWidgets('HistorialComprasScreen renders title, filter chips, and refresh action',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HistorialComprasScreen(),
        ),
      );

      // App bar title
      expect(find.text('Historial de Compras'), findsOneWidget);

      // Filter chips
      expect(find.text('Todas'), findsOneWidget);
      expect(find.text('Completadas'), findsOneWidget);
      expect(find.text('Pendientes'), findsOneWidget);

      // Refresh icon
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    });
  });
}

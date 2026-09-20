import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:si2_mobile/features/shipping/data/envio_tracking_model.dart';
import 'package:si2_mobile/features/shipping/presentation/screens/seguimiento_envio_screen.dart';

void main() {
  group('CU18 - SeguimientoEnvioScreen Widget Tests', () {
    testWidgets('SeguimientoEnvioScreen renders full shipment details with initialTracking',
        (WidgetTester tester) async {
      final mockTracking = EnvioTrackingModel(
        codigoRastreo: 'TRK-ATT-12345',
        idVenta: 10,
        codigoVenta: 'ATT-12345',
        estadoEnvio: 'EN_CAMINO',
        estadoLegible: 'En camino con el repartidor',
        fechaEstimadaEntrega: DateTime(2026, 9, 21, 16, 0),
        fechaVenta: DateTime(2026, 9, 20, 10, 0),
        direccionEntrega: 'Av. Las Américas #500',
        ciudad: 'Santa Cruz',
        destinatario: 'Ana Torres',
        telefono: '78901234',
        referencia: 'Edificio Torre Real piso 4',
        costoEnvio: 0.0,
        totalVenta: 420.0,
        totalPrendas: 3,
        repartidorNombre: 'Juan Carlos Choque',
        repartidorTelefono: '+591 76543210',
        repartidorVehiculo: 'Motocicleta Yamaha Negra (Placa: 4521-XYZ)',
        agencia: 'Attention Delivery Express',
        hitos: const [
          HitoSeguimientoModel(
            etapa: 'ORDEN_RECIBIDA',
            titulo: 'Orden confirmada',
            descripcion: 'Pago procesado exitosamente.',
            completado: true,
          ),
          HitoSeguimientoModel(
            etapa: 'PREPARANDO',
            titulo: 'Preparación en sucursal',
            descripcion: 'Prendas empaquetadas con cuidado.',
            completado: true,
          ),
          HitoSeguimientoModel(
            etapa: 'EN_CAMINO',
            titulo: 'En camino a tu dirección',
            descripcion: 'El repartidor está en ruta.',
            completado: false,
            enCurso: true,
          ),
          HitoSeguimientoModel(
            etapa: 'ENTREGADO',
            titulo: 'Entregado en destino',
            descripcion: 'Entrega final.',
            completado: false,
          ),
        ],
      );

      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: SeguimientoEnvioScreen(
            idVenta: 10,
            initialTracking: mockTracking,
          ),
        ),
      );

      // Verify AppBar
      expect(find.text('Rastreo de Envío'), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

      // Verify Header card
      expect(find.text('TRK-ATT-12345'), findsOneWidget);
      expect(find.text('En camino con el repartidor'), findsOneWidget);
      expect(find.text('Agencia: Attention Delivery Express'), findsOneWidget);

      // Verify Timeline section & hitos
      expect(find.text('Trazabilidad de la Entrega'), findsOneWidget);
      expect(find.text('Orden confirmada'), findsOneWidget);
      expect(find.text('Preparación en sucursal'), findsOneWidget);
      expect(find.text('En camino a tu dirección'), findsOneWidget);
      expect(find.text('En progreso'), findsOneWidget);

      // Verify Driver card
      expect(find.text('Repartidor Asignado'), findsOneWidget);
      expect(find.text('Juan Carlos Choque'), findsOneWidget);
      expect(find.text('Llamar'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);

      // Verify Destination card
      expect(find.text('Destino de la Entrega'), findsOneWidget);
      expect(find.text('Ana Torres'), findsOneWidget);
      expect(find.text('Av. Las Américas #500, Santa Cruz'), findsOneWidget);
      expect(find.text('Edificio Torre Real piso 4'), findsOneWidget);

      // Verify Order summary card
      expect(find.text('Pedido #ATT-12345'), findsOneWidget);
    });

    testWidgets('SeguimientoEnvioScreen renders empty state when no shipments exist',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SeguimientoEnvioScreen(idVenta: null),
        ),
      );

      // Initial loading
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });
  });
}

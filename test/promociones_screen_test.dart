import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:si2_mobile/features/promotions/data/descuento_model.dart';
import 'package:si2_mobile/features/promotions/presentation/screens/promociones_screen.dart';

void main() {
  group('PromocionesScreen Widget Tests', () {
    testWidgets('PromocionesScreen renders title, hero header, and action buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PromocionesScreen(),
        ),
      );

      // Verify AppBar
      expect(find.text('Descuentos y Ofertas'), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    });

    test('DescuentoModel properties produce expected values for UI presentation', () {
      final promo = DescuentoModel(
        idDescuento: 10,
        codigo: 'FIESTA15',
        nombre: 'Oferta Especial Fin de Semana',
        descripcion: 'Válido para vestidos de noche',
        tipo: 'PORCENTAJE',
        valor: 15.0,
        fechaInicio: DateTime(2026, 9, 20),
        fechaFin: DateTime(2026, 9, 25),
        activo: true,
        montoMinimoCompra: 200.0,
      );

      expect(promo.badgeTexto, '15% OFF');
      expect(promo.valorFormateado, '-15%');
      expect(promo.tieneCodigo, isTrue);
      expect(promo.esPorcentaje, isTrue);
      expect(promo.condicionCompraMinima, 'Compra mínima: Bs 200.00');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:si2_mobile/features/promotions/data/descuento_model.dart';

void main() {
  group('CU12 - DescuentoModel Unit Tests', () {
    test('DescuentoModel.fromJson parses percentage discount correctly', () {
      final json = {
        'id_descuento': 1,
        'codigo': 'VERANO20',
        'nombre': 'Descuento Temporada Verano',
        'descripcion': '20% en todas las prendas de playa y vestidos',
        'tipo': 'PORCENTAJE',
        'valor': 20.0,
        'fecha_inicio': '2026-09-01T00:00:00Z',
        'fecha_fin': '2026-09-30T23:59:59Z',
        'activo': true,
        'usos_maximos': 100,
        'usos_actuales': 25,
        'monto_minimo_compra': 150.0,
      };

      final promo = DescuentoModel.fromJson(json);

      expect(promo.idDescuento, equals(1));
      expect(promo.codigo, equals('VERANO20'));
      expect(promo.nombre, equals('Descuento Temporada Verano'));
      expect(promo.descripcion, equals('20% en todas las prendas de playa y vestidos'));
      expect(promo.tipo, equals('PORCENTAJE'));
      expect(promo.valor, equals(20.0));
      expect(promo.activo, isTrue);
      expect(promo.usosMaximos, equals(100));
      expect(promo.usosActuales, equals(25));
      expect(promo.montoMinimoCompra, equals(150.0));

      // Computed properties
      expect(promo.esPorcentaje, isTrue);
      expect(promo.esMontoFijo, isFalse);
      expect(promo.tieneCodigo, isTrue);
      expect(promo.badgeTexto, equals('20% OFF'));
      expect(promo.valorFormateado, equals('-20%'));
      expect(promo.condicionCompraMinima, equals('Compra mínima: Bs 150.00'));
    });

    test('DescuentoModel.fromJson parses fixed amount discount correctly', () {
      final json = {
        'id_descuento': 2,
        'codigo': 'BIENVENIDA50',
        'nombre': 'Bono de Bienvenida',
        'descripcion': 'Rebaja directa de Bs 50 en tu primera compra',
        'tipo': 'MONTO_FIJO',
        'valor': 50.0,
        'fecha_inicio': '2026-01-01T00:00:00Z',
        'fecha_fin': null,
        'activo': true,
        'usos_maximos': null,
        'usos_actuales': 12,
        'monto_minimo_compra': null,
      };

      final promo = DescuentoModel.fromJson(json);

      expect(promo.idDescuento, equals(2));
      expect(promo.codigo, equals('BIENVENIDA50'));
      expect(promo.esPorcentaje, isFalse);
      expect(promo.esMontoFijo, isTrue);
      expect(promo.tieneCodigo, isTrue);
      expect(promo.badgeTexto, equals('Bs 50 OFF'));
      expect(promo.valorFormateado, equals('-Bs 50.00'));
      expect(promo.vigenciaTexto, equals('Por tiempo limitado'));
      expect(promo.condicionCompraMinima, isNull);
    });

    test('DescuentoModel handles promotion without coupon code (direct discount)', () {
      final json = {
        'id_descuento': 3,
        'codigo': null,
        'nombre': 'Liquidación de Stock',
        'descripcion': 'Descuento automático en caja',
        'tipo': 'PORCENTAJE',
        'valor': 35.0,
        'fecha_inicio': null,
        'fecha_fin': null,
        'activo': true,
      };

      final promo = DescuentoModel.fromJson(json);

      expect(promo.idDescuento, equals(3));
      expect(promo.codigo, isNull);
      expect(promo.tieneCodigo, isFalse);
      expect(promo.badgeTexto, equals('35% OFF'));
      expect(promo.vigenciaTexto, equals('Por tiempo limitado'));
    });
  });
}

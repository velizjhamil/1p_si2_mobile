import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:si2_mobile/features/cart/data/cart_item.dart';
import 'package:si2_mobile/features/cart/logic/cart_service.dart';
import 'package:si2_mobile/features/reservations/data/reservas_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    CartService.instance.clear();
  });

  group('CartService and CartItem Unit Tests', () {
    test('CartItem creates and computes subtotal correctly', () {
      final item = CartItem(
        idProducto: 1,
        nombre: 'Camisa Denim',
        precioUnitario: 150.0,
        cantidad: 2,
        talla: 'M',
        color: 'Azul',
      );

      expect(item.subtotal, equals(300.0));
      expect(item.itemKey, equals('1-M-Azul'));
    });

    test('Adding same item increments quantity instead of duplicating', () {
      final cart = CartService.instance;

      cart.addItem(
        idProducto: 1,
        nombre: 'Pantalón Chino',
        precioUnitario: 100.0,
        cantidad: 1,
        talla: '32',
        color: 'Beige',
      );

      expect(cart.items.length, equals(1));
      expect(cart.items.first.cantidad, equals(1));

      // Add same variant
      cart.addItem(
        idProducto: 1,
        nombre: 'Pantalón Chino',
        precioUnitario: 100.0,
        cantidad: 2,
        talla: '32',
        color: 'Beige',
      );

      expect(cart.items.length, equals(1));
      expect(cart.items.first.cantidad, equals(3));
      expect(cart.subtotal, equals(300.0));
    });

    test('Free shipping rule applied when subtotal >= Bs 300', () {
      final cart = CartService.instance;

      // Under 300: shipping is Bs 25
      cart.addItem(
        idProducto: 2,
        nombre: 'Polera Básica',
        precioUnitario: 120.0,
        cantidad: 1,
      );

      expect(cart.subtotal, equals(120.0));
      expect(cart.costoEnvio, equals(25.0));
      expect(cart.total, equals(145.0));
      expect(cart.isEnvioGratis, isFalse);

      // Over/equal 300: shipping is free (Bs 0.0)
      cart.addItem(
        idProducto: 3,
        nombre: 'Chaqueta Cuero',
        precioUnitario: 200.0,
        cantidad: 1,
      );

      expect(cart.subtotal, equals(320.0));
      expect(cart.costoEnvio, equals(0.0));
      expect(cart.total, equals(320.0));
      expect(cart.isEnvioGratis, isTrue);
    });

    test('Quantity update and item removal works as expected', () {
      final cart = CartService.instance;

      cart.addItem(
        idProducto: 5,
        nombre: 'Gorra',
        precioUnitario: 50.0,
        cantidad: 2,
      );

      final item = cart.items.first;
      cart.updateQuantity(item, 1);
      expect(cart.items.first.cantidad, equals(3));

      cart.updateQuantity(item, -3);
      expect(cart.items.isEmpty, isTrue);
    });
  });

  group('ReservasService Models Unit Tests', () {
    test('ReservaItem parses valid JSON with details and totals', () {
      final json = {
        'id_reserva': 12,
        'id_sucursal': 3,
        'sucursal_nombre': 'Sucursal Equipetrol',
        'fecha_reserva': '2026-09-14T12:00:00Z',
        'fecha_expiracion': '2026-09-16T12:00:00Z',
        'fecha_expiracion_dt': '2026-09-16T12:00:00Z',
        'estado': 'PENDIENTE',
        'total_estimado': 250.0,
        'monto_anticipo': 125.0,
        'monto_anticipo_pagado': 0.0,
        'minutos_restantes': 2880,
        'es_expirada': false,
        'productos': [
          {
            'id_detalle': 1,
            'id_producto': 2,
            'nombre': 'Vestido Seda',
            'cantidad': 1,
            'precio_unitario': 250.0,
          }
        ],
      };

      final reserva = ReservaItem.fromJson(json);

      expect(reserva.idReserva, equals(12));
      expect(reserva.idSucursal, equals(3));
      expect(reserva.sucursalNombre, equals('Sucursal Equipetrol'));
      expect(reserva.estado, equals('PENDIENTE'));
      expect(reserva.esPendiente, isTrue);
      expect(reserva.totalEstimado, equals(250.0));
      expect(reserva.montoAnticipo, equals(125.0));
      expect(reserva.montoAnticipoPagado, equals(0.0));
      expect(reserva.saldoPendiente, equals(250.0));
      expect(reserva.esExpirada, isFalse);
      expect(reserva.minutosRestantes, equals(2880));
      expect(reserva.tiempoRestanteTexto, contains('restantes'));
      expect(reserva.productos.length, equals(1));
      expect(reserva.productos.first.nombre, equals('Vestido Seda'));
      expect(reserva.fechaExpiracion, isNotNull);
    });

    test('ReservaItem confirmed state calculates remaining balance properly', () {
      final json = {
        'id_reserva': 15,
        'id_sucursal': 1,
        'sucursal_nombre': 'Sucursal Central',
        'estado': 'CONFIRMADA',
        'total_estimado': 400.0,
        'monto_anticipo': 200.0,
        'monto_anticipo_pagado': 200.0,
        'minutos_restantes': 120,
        'es_expirada': false,
      };

      final reserva = ReservaItem.fromJson(json);

      expect(reserva.esConfirmada, isTrue);
      expect(reserva.montoAnticipoPagado, equals(200.0));
      expect(reserva.saldoPendiente, equals(200.0));
      expect(reserva.tiempoRestanteTexto, equals('2h restantes'));
    });
  });
}

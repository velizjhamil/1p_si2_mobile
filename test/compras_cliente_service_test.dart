import 'package:flutter_test/flutter_test.dart';
import 'package:si2_mobile/features/orders/data/compras_cliente_service.dart';

void main() {
  group('CU11 - ComprasClienteService Models Unit Tests', () {
    test('CompraClienteModel.fromJson parses full sale payload with multiple items', () {
      final json = {
        'id_venta': 42,
        'codigo': 'ATT-123456',
        'fecha_venta': '2026-09-20T14:30:00Z',
        'total': 450.0,
        'costo_envio': 25.0,
        'metodo_pago': 'QR',
        'estado_pago': 'PAGADO',
        'comprobante_url': 'https://storage.attention.com/comp/42.pdf',
        'items': [
          {
            'id_detalle': 101,
            'producto_id': 5,
            'nombre': 'Polera Oversize Basic',
            'talla': 'L',
            'color': 'Blanco',
            'cantidad': 2,
            'precio_unitario': 120.0,
            'subtotal': 240.0,
          },
          {
            'id_detalle': 102,
            'producto_id': 8,
            'nombre': 'Pantalón Cargo Urbano',
            'talla': '32',
            'color': 'Negro',
            'cantidad': 1,
            'precio_unitario': 185.0,
            'subtotal': 185.0,
          },
        ],
        'datos_entrega': {
          'nombre_cliente': 'María López',
          'correo': 'maria@example.com',
          'telefono': '78901234',
          'direccion': 'Av. Banzer 4to Anillo',
          'ciudad': 'Santa Cruz',
          'referencia': 'Portón negro',
        },
      };

      final compra = CompraClienteModel.fromJson(json);

      expect(compra.idVenta, equals(42));
      expect(compra.codigo, equals('ATT-123456'));
      expect(compra.total, equals(450.0));
      expect(compra.costoEnvio, equals(25.0));
      expect(compra.metodoPago, equals('QR'));
      expect(compra.estadoPago, equals('PAGADO'));
      expect(compra.comprobanteUrl, equals('https://storage.attention.com/comp/42.pdf'));
      expect(compra.items.length, equals(2));

      // Helpers test
      expect(compra.totalPrendas, equals(3)); // 2 + 1
      expect(compra.estadoLegible, equals('Completada'));
      expect(compra.esCompletada, isTrue);
      expect(compra.esPendiente, isFalse);
      expect(compra.esCancelada, isFalse);
      expect(compra.fechaFormateada.contains('20/09/2026'), isTrue);

      // Items test
      final item1 = compra.items[0];
      expect(item1.idDetalle, equals(101));
      expect(item1.productoId, equals(5));
      expect(item1.nombre, equals('Polera Oversize Basic'));
      expect(item1.talla, equals('L'));
      expect(item1.color, equals('Blanco'));
      expect(item1.cantidad, equals(2));
      expect(item1.subtotal, equals(240.0));

      // Delivery data
      expect(compra.datosEntrega, isNotNull);
      expect(compra.datosEntrega!.nombreCliente, equals('María López'));
      expect(compra.datosEntrega!.ciudad, equals('Santa Cruz'));
      expect(compra.datosEntrega!.referencia, equals('Portón negro'));
    });

    test('CompraClienteModel status helpers correctly classify PENDIENTE and CANCELADA', () {
      final jsonPendiente = {
        'id_venta': 43,
        'codigo': 'ATT-654321',
        'total': 180.0,
        'estado_pago': 'PENDIENTE',
      };
      final compraPendiente = CompraClienteModel.fromJson(jsonPendiente);
      expect(compraPendiente.estadoLegible, equals('Pendiente'));
      expect(compraPendiente.esPendiente, isTrue);
      expect(compraPendiente.esCompletada, isFalse);

      final jsonCancelada = {
        'id_venta': 44,
        'codigo': 'ATT-000111',
        'total': 90.0,
        'estado_pago': 'RECHAZADO',
      };
      final compraCancelada = CompraClienteModel.fromJson(jsonCancelada);
      expect(compraCancelada.estadoLegible, equals('Cancelada'));
      expect(compraCancelada.esCancelada, isTrue);
      expect(compraCancelada.esCompletada, isFalse);
    });

    test('CompraClienteModel handles minimal and null values gracefully', () {
      final jsonMinimo = <String, dynamic>{
        'id_venta': 1,
        'codigo': 'ATT-000001',
        'total': 50.0,
      };

      final compra = CompraClienteModel.fromJson(jsonMinimo);
      expect(compra.idVenta, equals(1));
      expect(compra.codigo, equals('ATT-000001'));
      expect(compra.total, equals(50.0));
      expect(compra.costoEnvio, equals(0.0));
      expect(compra.metodoPago, equals('QR'));
      expect(compra.estadoPago, equals('PAGADO'));
      expect(compra.totalPrendas, equals(0));
      expect(compra.fechaFormateada, equals('Reciente'));
      expect(compra.items.isEmpty, isTrue);
      expect(compra.datosEntrega, isNull);
    });
  });
}

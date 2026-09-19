import 'package:flutter_test/flutter_test.dart';
import 'package:si2_mobile/features/orders/data/compra_service.dart';

void main() {
  group('CU21 & CU13 - CompraService Models Unit Tests', () {
    test('VentaModel.fromJson parses full sale payload with items and delivery', () {
      final json = {
        'id_venta': 15,
        'codigo': 'ATT-048291',
        'fecha_venta': '2026-09-14T15:45:00Z',
        'total': 360.0,
        'costo_envio': 0.0,
        'metodo_pago': 'QR',
        'estado_pago': 'PAGADO',
        'comprobante_url': null,
        'items': [
          {
            'id_detalle': 28,
            'producto_id': 1,
            'nombre': 'Camisa Denim Casual',
            'talla': 'M',
            'color': 'Negro',
            'cantidad': 2,
            'precio_unitario': 180.0,
            'subtotal': 360.0,
          }
        ],
        'datos_entrega': {
          'nombre_cliente': 'Juan Pérez',
          'correo': 'juan.perez@ejemplo.com',
          'telefono': '77012345',
          'direccion': 'Calle Beni #220',
          'ciudad': 'Santa Cruz de la Sierra',
          'referencia': 'Depto 4B',
        },
      };

      final venta = VentaModel.fromJson(json);

      expect(venta.idVenta, equals(15));
      expect(venta.codigo, equals('ATT-048291'));
      expect(venta.total, equals(360.0));
      expect(venta.costoEnvio, equals(0.0));
      expect(venta.metodoPago, equals('QR'));
      expect(venta.estadoPago, equals('PAGADO'));
      expect(venta.items.length, equals(1));

      final item = venta.items.first;
      expect(item.idDetalle, equals(28));
      expect(item.productoId, equals(1));
      expect(item.nombre, equals('Camisa Denim Casual'));
      expect(item.talla, equals('M'));
      expect(item.color, equals('Negro'));
      expect(item.cantidad, equals(2));
      expect(item.subtotal, equals(360.0));

      expect(venta.datosEntrega, isNotNull);
      expect(venta.datosEntrega!.nombreCliente, equals('Juan Pérez'));
      expect(venta.datosEntrega!.ciudad, equals('Santa Cruz de la Sierra'));
    });

    test('VentaModel.fromJson handles null or empty fields with safe defaults', () {
      final json = <String, dynamic>{
        'id_venta': 99,
        'codigo': 'ATT-999999',
        'total': 120.0,
      };

      final venta = VentaModel.fromJson(json);

      expect(venta.idVenta, equals(99));
      expect(venta.codigo, equals('ATT-999999'));
      expect(venta.total, equals(120.0));
      expect(venta.costoEnvio, equals(0.0));
      expect(venta.metodoPago, equals('QR'));
      expect(venta.estadoPago, equals('PAGADO'));
      expect(venta.items.isEmpty, isTrue);
      expect(venta.datosEntrega, isNull);
    });
  });
}

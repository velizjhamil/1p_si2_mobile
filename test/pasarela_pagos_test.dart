import 'package:flutter_test/flutter_test.dart';
import 'package:si2_mobile/features/payments/data/payment_model.dart';

void main() {
  group('Payment Gateway Models Unit Tests', () {
    test('TransaccionPagoModel.fromJson parses complete transaction payload', () {
      final json = {
        'id_transaccion': 42,
        'codigo_transaccion': 'TXN-ATT-20260920-00123',
        'pasarela': 'AttentionPay',
        'monto': 299.50,
        'moneda': 'BOB',
        'metodo_pago': 'QR',
        'estado': 'PENDIENTE',
        'qr_data': '0002010102122648com.attention',
        'detalles_pago': 'QR Simple generado',
        'fecha_creacion': '2026-09-20T20:00:00Z',
        'fecha_actualizacion': '2026-09-20T20:00:00Z',
        'id_venta': 105,
        'codigo_venta': 'ATT-123456',
        'estado_venta': 'PENDIENTE',
      };

      final txn = TransaccionPagoModel.fromJson(json);

      expect(txn.idTransaccion, 42);
      expect(txn.codigoTransaccion, 'TXN-ATT-20260920-00123');
      expect(txn.pasarela, 'AttentionPay');
      expect(txn.monto, 299.50);
      expect(txn.moneda, 'BOB');
      expect(txn.metodoPago, 'QR');
      expect(txn.estado, 'PENDIENTE');
      expect(txn.isPendiente, isTrue);
      expect(txn.isPagado, isFalse);
      expect(txn.isRechazado, isFalse);
      expect(txn.qrData, isNotNull);
      expect(txn.idVenta, 105);
      expect(txn.codigoVenta, 'ATT-123456');
    });

    test('TransaccionPagoModel correctly flags PAGADO and RECHAZADO', () {
      final pagado = TransaccionPagoModel.fromJson({
        'id_transaccion': 1,
        'codigo_transaccion': 'TXN-01',
        'monto': 100,
        'estado': 'PAGADO',
      });
      expect(pagado.isPagado, isTrue);
      expect(pagado.isPendiente, isFalse);

      final rechazado = TransaccionPagoModel.fromJson({
        'id_transaccion': 2,
        'codigo_transaccion': 'TXN-02',
        'monto': 100,
        'estado': 'RECHAZADO',
      });
      expect(rechazado.isRechazado, isTrue);
      expect(rechazado.isPagado, isFalse);
    });

    test('DatosTarjetaModel.toJson strips whitespace from card numbers', () {
      const tarjeta = DatosTarjetaModel(
        titular: 'JUAN PEREZ',
        numeroTarjeta: '4500 1234 5678 9012',
        expiracion: '12/28',
        cvv: '123',
      );

      final json = tarjeta.toJson();
      expect(json['titular'], 'JUAN PEREZ');
      expect(json['numero_tarjeta'], '4500123456789012');
      expect(json['expiracion'], '12/28');
      expect(json['cvv'], '123');
    });
  });
}

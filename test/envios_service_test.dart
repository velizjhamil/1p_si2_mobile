import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:si2_mobile/features/shipping/data/envio_tracking_model.dart';

void main() {
  group('EnvioTrackingModel Unit Tests', () {
    test('EnvioTrackingModel.fromJson parses complete tracking payload', () {
      final json = {
        'codigo_rastreo': 'TRK-ATT-998877',
        'id_venta': 30,
        'codigo_venta': 'ATT-998877',
        'estado_envio': 'EN_CAMINO',
        'estado_legible': 'En camino con el repartidor',
        'fecha_estimada_entrega': '2026-09-21T18:00:00Z',
        'fecha_venta': '2026-09-20T10:00:00Z',
        'direccion_entrega': 'Av. Busch #123',
        'ciudad': 'Santa Cruz',
        'destinatario': 'Laura Mendez',
        'telefono': '71234567',
        'referencia': 'Casa de dos pisos reja blanca',
        'costo_envio': 25.0,
        'total_venta': 320.0,
        'total_prendas': 2,
        'repartidor_nombre': 'Juan Carlos Choque',
        'repartidor_telefono': '+591 76543210',
        'repartidor_vehiculo': 'Motocicleta Yamaha Negra (Placa: 4521-XYZ)',
        'agencia': 'Attention Delivery Express',
        'hitos': [
          {
            'etapa': 'ORDEN_RECIBIDA',
            'titulo': 'Orden confirmada',
            'descripcion': 'Pago confirmado vía QR.',
            'fecha': '2026-09-20T10:00:00Z',
            'completado': true,
            'en_curso': false,
          },
          {
            'etapa': 'PREPARANDO',
            'titulo': 'Preparación en sucursal',
            'descripcion': 'Prendas empaquetadas.',
            'fecha': '2026-09-20T10:45:00Z',
            'completado': true,
            'en_curso': false,
          },
          {
            'etapa': 'EN_CAMINO',
            'titulo': 'En camino a tu dirección',
            'descripcion': 'El repartidor se dirige a tu domicilio.',
            'fecha': '2026-09-20T12:00:00Z',
            'completado': false,
            'en_curso': true,
          },
        ],
      };

      final tracking = EnvioTrackingModel.fromJson(json);

      expect(tracking.codigoRastreo, equals('TRK-ATT-998877'));
      expect(tracking.idVenta, equals(30));
      expect(tracking.codigoVenta, equals('ATT-998877'));
      expect(tracking.estadoEnvio, equals('EN_CAMINO'));
      expect(tracking.estadoLegible, equals('En camino con el repartidor'));
      expect(tracking.direccionEntrega, equals('Av. Busch #123'));
      expect(tracking.ciudad, equals('Santa Cruz'));
      expect(tracking.destinatario, equals('Laura Mendez'));
      expect(tracking.repartidorNombre, equals('Juan Carlos Choque'));
      expect(tracking.repartidorTelefono, equals('+591 76543210'));
      expect(tracking.repartidorVehiculo, contains('Yamaha'));
      expect(tracking.hitos.length, equals(3));

      // Computed properties
      expect(tracking.esEnCamino, isTrue);
      expect(tracking.esEntregado, isFalse);
      expect(tracking.esPreparando, isFalse);
      expect(tracking.etapaIndex, equals(2)); // EN_CAMINO -> step 2
      expect(tracking.iconoEstado, equals(Icons.delivery_dining_rounded));
      expect(tracking.fechaEstimadaFormateada.contains('21/09/2026'), isTrue);

      // Check hitos
      final hito0 = tracking.hitos[0];
      expect(hito0.completado, isTrue);
      expect(hito0.enCurso, isFalse);

      final hito2 = tracking.hitos[2];
      expect(hito2.completado, isFalse);
      expect(hito2.enCurso, isTrue);
    });

    test('EnvioTrackingModel classifies distinct shipment states correctly', () {
      const tEntregado = EnvioTrackingModel(
        codigoRastreo: 'TRK-1',
        idVenta: 1,
        codigoVenta: 'C1',
        estadoEnvio: 'ENTREGADO',
        estadoLegible: 'Entregado',
        direccionEntrega: 'Dir',
        ciudad: 'C',
        destinatario: 'D',
        telefono: 'T',
      );
      expect(tEntregado.esEntregado, isTrue);
      expect(tEntregado.etapaIndex, equals(3));
      expect(tEntregado.iconoEstado, equals(Icons.check_circle_rounded));

      const tPrep = EnvioTrackingModel(
        codigoRastreo: 'TRK-2',
        idVenta: 2,
        codigoVenta: 'C2',
        estadoEnvio: 'PREPARANDO',
        estadoLegible: 'Preparando',
        direccionEntrega: 'Dir',
        ciudad: 'C',
        destinatario: 'D',
        telefono: 'T',
      );
      expect(tPrep.esPreparando, isTrue);
      expect(tPrep.etapaIndex, equals(1));
      expect(tPrep.iconoEstado, equals(Icons.inventory_2_rounded));
    });

    test('HitoSeguimientoModel formats timestamps cleanly', () {
      final hito = HitoSeguimientoModel(
        etapa: 'PREP',
        titulo: 'Título',
        descripcion: 'Desc',
        fecha: DateTime(2026, 9, 20, 15, 30),
        completado: true,
      );

      expect(hito.fechaFormateada, equals('20/09/2026 15:30'));
    });
  });
}

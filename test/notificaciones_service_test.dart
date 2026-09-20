import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:si2_mobile/features/notifications/data/notificacion_model.dart';

void main() {
  group('CU10 - NotificacionModel Unit Tests', () {
    test('NotificacionModel.fromJson parses full payload correctly', () {
      final json = {
        'id_notificacion': 15,
        'id_usuario': 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        'titulo': 'Tu pedido fue despachado',
        'mensaje': 'Tu orden ATT-10025 ya se encuentra en camino con el repartidor.',
        'tipo': 'PEDIDO',
        'leida': false,
        'fecha_creacion': '2026-09-20T14:30:00Z',
        'referencia_tipo': 'PEDIDO',
        'referencia_id': '10025',
      };

      final noti = NotificacionModel.fromJson(json);

      expect(noti.idNotificacion, equals(15));
      expect(noti.idUsuario, equals('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'));
      expect(noti.titulo, equals('Tu pedido fue despachado'));
      expect(noti.mensaje, equals('Tu orden ATT-10025 ya se encuentra en camino con el repartidor.'));
      expect(noti.tipo, equals('PEDIDO'));
      expect(noti.leida, isFalse);
      expect(noti.referenciaTipo, equals('PEDIDO'));
      expect(noti.referenciaId, equals('10025'));

      // Computed properties
      expect(noti.tipoLegible, equals('Pedido'));
      expect(noti.iconoPorTipo, equals(Icons.shopping_bag_rounded));
      expect(noti.fechaFormateada.contains('20/09/2026'), isTrue);
    });

    test('NotificacionModel handles distinct types and fallbacks correctly', () {
      final jsonReserva = {
        'id_notificacion': 2,
        'titulo': 'Reserva lista',
        'mensaje': 'Tu prenda fue apartada en Sucursal Centro.',
        'tipo': 'RESERVA',
      };
      final notiReserva = NotificacionModel.fromJson(jsonReserva);
      expect(notiReserva.tipoLegible, equals('Reserva'));
      expect(notiReserva.iconoPorTipo, equals(Icons.bookmark_added_rounded));

      final jsonPromo = {
        'id_notificacion': 3,
        'titulo': '20% OFF Verano',
        'mensaje': 'Usa el cupón VERANO20',
        'tipo': 'PROMO',
      };
      final notiPromo = NotificacionModel.fromJson(jsonPromo);
      expect(notiPromo.tipoLegible, equals('Promoción'));
      expect(notiPromo.iconoPorTipo, equals(Icons.local_offer_rounded));

      final jsonDefault = {
        'id_notificacion': 4,
        'titulo': 'Aviso general',
        'mensaje': 'Mantenimiento del sistema hoy a medianoche',
      };
      final notiDefault = NotificacionModel.fromJson(jsonDefault);
      expect(notiDefault.tipoLegible, equals('Aviso'));
      expect(notiDefault.tipo, equals('INFO'));
      expect(notiDefault.leida, isFalse);
      expect(notiDefault.referenciaTipo, isNull);
      expect(notiDefault.referenciaId, isNull);
    });

    test('NotificacionModel.copyWith modifies leida flag without mutating other properties', () {
      final original = NotificacionModel(
        idNotificacion: 8,
        titulo: 'Alerta',
        mensaje: 'Mensaje de prueba',
        tipo: 'SISTEMA',
        leida: false,
        fechaCreacion: DateTime(2026, 9, 20, 10, 0),
      );

      final modified = original.copyWith(leida: true);

      expect(original.leida, isFalse);
      expect(modified.leida, isTrue);
      expect(modified.idNotificacion, equals(8));
      expect(modified.titulo, equals('Alerta'));
      expect(modified.tipo, equals('SISTEMA'));
    });

    test('NotificacionModel.tiempoRelativo formats close and distant timestamps appropriately', () {
      final ahora = DateTime.now();

      final recien = NotificacionModel(
        idNotificacion: 1,
        titulo: 'T1',
        mensaje: 'M1',
        fechaCreacion: ahora.subtract(const Duration(seconds: 20)),
      );
      expect(recien.tiempoRelativo, equals('Ahora mismo'));

      final minutos = NotificacionModel(
        idNotificacion: 2,
        titulo: 'T2',
        mensaje: 'M2',
        fechaCreacion: ahora.subtract(const Duration(minutes: 15)),
      );
      expect(minutos.tiempoRelativo, equals('Hace 15 min'));

      final horas = NotificacionModel(
        idNotificacion: 3,
        titulo: 'T3',
        mensaje: 'M3',
        fechaCreacion: ahora.subtract(const Duration(hours: 3)),
      );
      expect(horas.tiempoRelativo, equals('Hace 3 h'));
    });
  });
}

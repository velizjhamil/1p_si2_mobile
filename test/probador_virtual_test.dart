import 'package:flutter_test/flutter_test.dart';
import 'package:si2_mobile/features/ar_tryon/data/probador_virtual_service.dart';
import 'package:si2_mobile/features/cart/logic/cart_service.dart';

void main() {
  group('Probador Virtual con IA Models & Flow Tests', () {
    test('FotoUsuario.fromJson parses valid payload and dates', () {
      final json = {
        'id_foto': 101,
        'url_imagen': 'data:image/jpeg;base64,/9j/4AAQSkZJRg...',
        'complexion': 'MEDIA',
        'estatura_cm': 172,
        'peso_kg': 68,
        'fecha_subida': '2026-09-19T10:30:00Z',
      };

      final foto = FotoUsuario.fromJson(json);

      expect(foto.idFoto, equals(101));
      expect(foto.urlImagen, startsWith('data:image/jpeg;base64,'));
      expect(foto.complexion, equals('MEDIA'));
      expect(foto.estaturaCm, equals(172));
      expect(foto.pesoKg, equals(68));
      expect(foto.fechaSubida, isNotNull);
      expect(foto.fechaSubida!.year, equals(2026));
    });

    test('SimulacionProbadorResult.fromJson parses full simulation and fit assessment', () {
      final json = {
        'id_simulacion': 42,
        'producto_id': 5,
        'producto_nombre': 'Blusa Seda Elegante',
        'prenda_imagen_url': 'https://storage.googleapis.com/attention/blusa.jpg',
        'resultado_imagen_url': 'data:image/jpeg;base64,...',
        'talla_seleccionada': 'M',
        'talla_recomendada': 'M',
        'ajuste_estimado': 'PERFECTO',
        'color_seleccionado': 'Azul Marino',
        'color_hex': '#000080',
        'precio': 189.50,
        'categoria': 'Blusas',
        'fecha_simulacion': '2026-09-19T10:35:00Z',
        'guardada': true,
      };

      final sim = SimulacionProbadorResult.fromJson(json);

      expect(sim.idSimulacion, equals(42));
      expect(sim.productoId, equals(5));
      expect(sim.productoNombre, equals('Blusa Seda Elegante'));
      expect(sim.tallaSeleccionada, equals('M'));
      expect(sim.tallaRecomendada, equals('M'));
      expect(sim.ajusteEstimado, equals('PERFECTO'));
      expect(sim.colorSeleccionado, equals('Azul Marino'));
      expect(sim.colorHex, equals('#000080'));
      expect(sim.precio, equals(189.50));
      expect(sim.categoria, equals('Blusas'));
      expect(sim.guardada, isTrue);
    });

    test('SimulacionProbadorResult handles AJUSTADO and HOLGADO assessments', () {
      final jsonAjustado = {
        'id_simulacion': 43,
        'producto_id': 2,
        'producto_nombre': 'Top Deportivo Dry-Fit',
        'talla_seleccionada': 'S',
        'talla_recomendada': 'M',
        'ajuste_estimado': 'AJUSTADO',
      };

      final simAjustado = SimulacionProbadorResult.fromJson(jsonAjustado);
      expect(simAjustado.ajusteEstimado, equals('AJUSTADO'));
      expect(simAjustado.tallaSeleccionada, equals('S'));
      expect(simAjustado.tallaRecomendada, equals('M'));

      final jsonHolgado = {
        'id_simulacion': 44,
        'producto_id': 3,
        'producto_nombre': 'Polera Oversized Street',
        'talla_seleccionada': 'XL',
        'talla_recomendada': 'L',
        'ajuste_estimado': 'HOLGADO',
      };

      final simHolgado = SimulacionProbadorResult.fromJson(jsonHolgado);
      expect(simHolgado.ajusteEstimado, equals('HOLGADO'));
    });

    test('Adding simulation result to CartService registers item correctly', () {
      final cart = CartService.instance;
      final initialCount = cart.totalItemCount;

      cart.addItem(
        idProducto: 5,
        nombre: 'Blusa Seda Elegante',
        precioUnitario: 189.50,
        cantidad: 1,
        talla: 'M',
        color: 'Azul Marino',
        imagenUrl: 'https://storage.googleapis.com/attention/blusa.jpg',
      );

      expect(cart.totalItemCount, equals(initialCount + 1));
      final addedItem = cart.items.firstWhere((i) => i.idProducto == 5);
      expect(addedItem.nombre, equals('Blusa Seda Elegante'));
      expect(addedItem.talla, equals('M'));
      expect(addedItem.color, equals('Azul Marino'));
      expect(addedItem.precioUnitario, equals(189.50));
    });
  });
}

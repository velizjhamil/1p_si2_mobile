import 'package:flutter_test/flutter_test.dart';
import 'package:si2_mobile/features/categories/data/categorias_service.dart';
import 'package:si2_mobile/features/tallas/data/tallas_service.dart';

void main() {
  group('CU9 - Categorias Unit Tests', () {
    test('Categoria.fromJson parses valid JSON with all fields', () {
      final json = {
        'id_categoria': 1,
        'nombre': 'Camisas',
        'linea': 'Hombre',
        'descripcion': 'Camisas formales y casuales',
        'activo': true,
        'fecha_creacion': '2026-09-13T00:48:12.480580Z',
      };

      final cat = Categoria.fromJson(json);

      expect(cat.idCategoria, equals(1));
      expect(cat.nombre, equals('Camisas'));
      expect(cat.linea, equals('Hombre'));
      expect(cat.descripcion, equals('Camisas formales y casuales'));
      expect(cat.activo, isTrue);
      expect(cat.fechaCreacion, isNotNull);
      expect(cat.fechaCreacion!.year, equals(2026));
    });

    test('Categoria.fromJson handles missing and null fields gracefully', () {
      final json = <String, dynamic>{
        'id_categoria': 2,
        'nombre': 'Vestidos',
      };

      final cat = Categoria.fromJson(json);

      expect(cat.idCategoria, equals(2));
      expect(cat.nombre, equals('Vestidos'));
      expect(cat.linea, equals('Unisex'));
      expect(cat.descripcion, isNull);
      expect(cat.activo, isTrue);
      expect(cat.fechaCreacion, isNull);
    });
  });

  group('CU7 - Tallas y Colores Unit Tests', () {
    test('Talla.fromJson parses valid JSON correctly', () {
      final json = {
        'id_talla': 3,
        'nombre_talla': 'M',
        'descripcion': 'Talla Mediana',
        'activo': true,
        'fecha_creacion': '2026-09-14T10:00:00Z',
      };

      final talla = Talla.fromJson(json);

      expect(talla.idTalla, equals(3));
      expect(talla.nombreTalla, equals('M'));
      expect(talla.descripcion, equals('Talla Mediana'));
      expect(talla.activo, isTrue);
      expect(talla.fechaCreacion, isNotNull);
    });

    test('ColorItem.fromJson parses valid color with hex code', () {
      final json = {
        'id_color': 1,
        'nombre_color': 'Azul Marino',
        'codigo_hex': '#1d528d',
        'descripcion': 'Tono oscuro',
        'activo': true,
        'fecha_creacion': '2026-09-14T10:00:00Z',
      };

      final color = ColorItem.fromJson(json);

      expect(color.idColor, equals(1));
      expect(color.nombreColor, equals('Azul Marino'));
      expect(color.codigoHex, equals('#1d528d'));
      expect(color.descripcion, equals('Tono oscuro'));
      expect(color.activo, isTrue);
    });

    test('ColorItem.fromJson falls back safely on empty/null values', () {
      final json = <String, dynamic>{
        'id_color': 9,
      };

      final color = ColorItem.fromJson(json);

      expect(color.idColor, equals(9));
      expect(color.nombreColor, equals(''));
      expect(color.codigoHex, equals('#000000'));
      expect(color.activo, isTrue);
      expect(color.descripcion, isNull);
    });
  });
}

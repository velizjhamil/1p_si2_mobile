import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:si2_mobile/features/ai_assistant/data/models/ia_chat_message.dart';
import 'package:si2_mobile/features/ai_assistant/data/models/producto_resumen_ia.dart';
import 'package:si2_mobile/features/ai_assistant/presentation/widgets/ia_product_carousel.dart';
import 'package:si2_mobile/features/ai_assistant/presentation/widgets/rich_markdown_text.dart';
import 'package:si2_mobile/features/ai_assistant/presentation/widgets/typing_indicator.dart';

void main() {
  group('CU25 - Asistente IA Models & Data Tests', () {
    test('ProductoResumenIA.fromJson correctly parses enriched payload', () {
      final json = {
        'id_producto': 4,
        'nombre': 'Vestido Midi Floral',
        'precio_venta': 320.0,
        'imagen_url': 'https://images.unsplash.com/photo-vestido.jpg',
        'categoria': 'Vestidos',
        'linea': 'Mujer',
        'tallas': ['S', 'M', 'L'],
        'colores': [
          {'nombre_color': 'Multicolor', 'codigo_hex': '#E06666'},
          {'nombre_color': 'Azul', 'codigo_hex': '#3366CC'},
        ],
        'stock_total': 8,
      };

      final prod = ProductoResumenIA.fromJson(json);

      expect(prod.idProducto, equals(4));
      expect(prod.nombre, equals('Vestido Midi Floral'));
      expect(prod.precioVenta, equals(320.0));
      expect(prod.imagenUrl, contains('photo-vestido.jpg'));
      expect(prod.categoria, equals('Vestidos'));
      expect(prod.linea, equals('Mujer'));
      expect(prod.tallas, equals(['S', 'M', 'L']));
      expect(prod.colores.length, equals(2));
      expect(prod.colores.first.nombreColor, equals('Multicolor'));
      expect(prod.colores.first.codigoHex, equals('#E06666'));
      expect(prod.stockTotal, equals(8));
    });

    test('ProductoResumenIA.toProducto() correctly creates catalog Producto', () {
      const resumen = ProductoResumenIA(
        idProducto: 10,
        nombre: 'Blusa Seda',
        precioVenta: 180.50,
        imagenUrl: 'https://example.com/blusa.jpg',
        categoria: 'Blusas',
        tallas: ['M'],
        colores: [ColorResumenIA(nombreColor: 'Blanco', codigoHex: '#FFFFFF')],
      );

      final producto = resumen.toProducto();

      expect(producto.idProducto, equals(10));
      expect(producto.nombre, equals('Blusa Seda'));
      expect(producto.precioVenta, equals(180.50));
      expect(producto.tallas, equals(['M']));
      expect(producto.colores.length, equals(1));
      expect(producto.colores.first.nombre, equals('Blanco'));
    });

    test('IAChatMessage constructors and toHistorialMap()', () {
      final userMsg = IAChatMessage.user('¿Qué blusas tienen?');
      expect(userMsg.isUser, isTrue);
      expect(userMsg.isAssistant, isFalse);
      expect(userMsg.toHistorialMap(), equals({
        'rol': 'usuario',
        'contenido': '¿Qué blusas tienen?',
      }));

      final assistantMsg = IAChatMessage.assistant(
        contenido: 'Tenemos blusas de seda y algodón.',
        productosRecomendados: [1, 2],
        sugerencias: ['Ver tallas'],
      );
      expect(assistantMsg.isUser, isFalse);
      expect(assistantMsg.isAssistant, isTrue);
      expect(assistantMsg.productosRecomendados, equals([1, 2]));
      expect(assistantMsg.sugerencias, equals(['Ver tallas']));
      expect(assistantMsg.toHistorialMap(), equals({
        'rol': 'asistente',
        'contenido': 'Tenemos blusas de seda y algodón.',
      }));
    });
  });

  group('CU25 - Asistente IA UI Widgets Tests', () {
    testWidgets('RichMarkdownText renders headers, bullets and bold text', (tester) async {
      const markdown = '''
### Prendas Disponibles
Tenemos las siguientes opciones:
* **Blusa de Seda** - Elegante y fresca
* **Pantalón Palazzo** - Corte moderno
''';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RichMarkdownText(text: markdown),
          ),
        ),
      );

      expect(find.text('Prendas Disponibles'), findsOneWidget);
      expect(find.text('Tenemos las siguientes opciones:'), findsOneWidget);
      expect(find.textContaining('Blusa de Seda'), findsOneWidget);
      expect(find.textContaining('Pantalón Palazzo'), findsOneWidget);
    });

    testWidgets('IAProductCarousel renders products with formatted price', (tester) async {
      const prods = [
        ProductoResumenIA(
          idProducto: 1,
          nombre: 'Vestido Bohemio',
          precioVenta: 250.0,
          categoria: 'Vestidos',
          tallas: ['S', 'M'],
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IAProductCarousel(productos: prods),
          ),
        ),
      );

      expect(find.text('Vestido Bohemio'), findsOneWidget);
      expect(find.text('Bs 250.00'), findsOneWidget);
      expect(find.text('Vestidos'), findsOneWidget);
      expect(find.text('Tallas: S, M'), findsOneWidget);
    });

    testWidgets('TypingIndicator renders thinking message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TypingIndicator(),
          ),
        ),
      );

      expect(find.text('Attention AI está pensando...'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });
  });
}

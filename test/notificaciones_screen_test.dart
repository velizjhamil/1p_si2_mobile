import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:si2_mobile/features/notifications/presentation/screens/notificaciones_screen.dart';

void main() {
  group('CU10 - NotificacionesScreen Widget Tests', () {
    testWidgets('NotificacionesScreen renders title, filter chips, and action buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NotificacionesScreen(),
        ),
      );

      // Verify AppBar title
      expect(find.text('Notificaciones'), findsOneWidget);

      // Verify Actions
      expect(find.byIcon(Icons.done_all_rounded), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

      // Verify Filter chips
      expect(find.text('Todas'), findsOneWidget);
      expect(find.text('No leídas'), findsOneWidget);
    });
  });
}

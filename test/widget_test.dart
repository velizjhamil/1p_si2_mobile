import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:si2_mobile/main.dart';

void main() {
  testWidgets('renders login form', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsWidgets);
  });

  testWidgets('shows validation errors when submitting empty fields',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // The string 'Iniciar Sesión' appears in both the AppBar and the
    // submit button; target the button specifically.
    await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar Sesión'));
    await tester.pump();

    expect(find.text('El correo es requerido.'), findsOneWidget);
    expect(find.text('La contraseña es requerida.'), findsOneWidget);
  });
}

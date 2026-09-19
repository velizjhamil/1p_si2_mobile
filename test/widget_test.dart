import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:si2_mobile/features/auth/presentation/screens/login_screen.dart';

void main() {
  testWidgets('renders login form', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsWidgets);
  });

  testWidgets('shows validation errors when submitting empty fields',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    // The string 'Iniciar Sesión' appears in both the AppBar and the
    // submit button; target the button specifically.
    await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar Sesión'));
    await tester.pump();

    expect(find.text('El correo es requerido.'), findsOneWidget);
    expect(find.text('La contraseña es requerida.'), findsOneWidget);
  });

  testWidgets('tapping register button navigates to RegisterScreen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('Regístrate aquí'), findsOneWidget);
    await tester.tap(find.text('Regístrate aquí'));
    await tester.pumpAndSettle();

    expect(find.text('Únete a Attention'), findsOneWidget);
    expect(find.text('Crear Cuenta'), findsWidgets);
  });
}

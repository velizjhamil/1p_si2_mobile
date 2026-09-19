import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:si2_mobile/features/auth/presentation/screens/register_screen.dart';

void main() {
  testWidgets('renders all register form fields and elements',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

    expect(find.text('Crear Cuenta'), findsWidgets);
    expect(find.text('Únete a Attention'), findsOneWidget);
    expect(find.text('Nombre *'), findsOneWidget);
    expect(find.text('Apellido (opcional)'), findsOneWidget);
    expect(find.text('Correo electrónico *'), findsOneWidget);
    expect(find.text('Contraseña *'), findsOneWidget);
    expect(find.text('Confirmar contraseña *'), findsOneWidget);
    expect(find.text('¿Ya tienes una cuenta?'), findsOneWidget);
    expect(find.text('Inicia sesión'), findsOneWidget);
  });

  testWidgets('shows validation errors when submitting empty required fields',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

    final submitButton =
        find.widgetWithText(ElevatedButton, 'Crear Cuenta');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pump();

    expect(find.text('El nombre es requerido.'), findsOneWidget);
    expect(find.text('El correo es requerido.'), findsOneWidget);
    expect(find.text('La contraseña es requerida.'), findsOneWidget);
  });

  testWidgets('validates password length and password mismatch',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

    // Enter valid name and email
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre *'), 'Carlos');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo electrónico *'),
        'carlos@test.com');

    // Enter short password
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña *'), '123');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmar contraseña *'), '123456');

    final submitButton =
        find.widgetWithText(ElevatedButton, 'Crear Cuenta');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pump();

    expect(find.text('La contraseña debe tener al menos 6 caracteres.'),
        findsOneWidget);

    // Enter longer password but mismatched confirmation
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña *'), 'password123');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmar contraseña *'),
        'different_pass');

    await tester.tap(submitButton);
    await tester.pump();

    expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
  });
}

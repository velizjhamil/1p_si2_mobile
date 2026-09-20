import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:si2_mobile/core/theme/app_theme.dart';
import 'package:si2_mobile/core/theme/theme_controller.dart';
import 'package:si2_mobile/features/catalog/presentation/screens/home_screen.dart';
import 'package:si2_mobile/features/profile/presentation/screens/perfil_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Navigation & Theme System Tests', () {
    test('ThemeController toggles between light and dark mode correctly', () async {
      final controller = ThemeController.instance;

      await controller.setThemeMode(ThemeMode.light);
      expect(controller.themeMode, ThemeMode.light);
      expect(controller.isDarkMode, isFalse);

      await controller.toggleDarkMode(true);
      expect(controller.themeMode, ThemeMode.dark);
      expect(controller.isDarkMode, isTrue);

      await controller.toggleDarkMode(false);
      expect(controller.themeMode, ThemeMode.light);
      expect(controller.isDarkMode, isFalse);
    });

    test('AppTheme generates valid light and dark ThemeData with Material 3', () {
      final light = AppTheme.lightTheme;
      final dark = AppTheme.darkTheme;

      expect(light.useMaterial3, isTrue);
      expect(dark.useMaterial3, isTrue);
      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
      expect(light.colorScheme.primary, AppTheme.brandCharcoal);
    });

    testWidgets('HomeScreen renders NavigationBar with 5 core modules and no Drawer',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const HomeScreen(),
        ),
      );
      await tester.pump();

      // Verify that NavigationBar exists
      expect(find.byType(NavigationBar), findsOneWidget);

      // Verify 5 modules in bottom navigation
      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Sucursales'), findsOneWidget);
      expect(find.text('Promociones'), findsOneWidget);
      expect(find.widgetWithText(NavigationDestination, 'Probador IA'), findsOneWidget);
      expect(find.text('Perfil'), findsOneWidget);

      // Verify Drawer is REMOVED (no Drawer widget)
      expect(find.byType(Drawer), findsNothing);

      // Verify category filter "Todas" is present in catalog tab
      expect(find.text('Todas'), findsOneWidget);
    });

    testWidgets('PerfilScreen renders theme switch, profile headers, and secondary operations',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const PerfilScreen(),
        ),
      );
      await tester.pump();

      // Verify header and title
      expect(find.text('Perfil y Ajustes'), findsOneWidget);
      expect(find.text('PREFERENCIAS Y APARIENCIA'), findsOneWidget);
      expect(find.text('Modo Oscuro'), findsOneWidget);

      // Verify secondary operations in clean fashion store copy
      expect(find.text('MIS PEDIDOS Y GESTIÓN'), findsOneWidget);
      expect(find.text('Mis Compras y Pedidos'), findsOneWidget);
      expect(find.text('Mis Reservas de Prendas'), findsOneWidget);
      expect(find.text('Seguimiento de Envíos'), findsOneWidget);
      expect(find.text('Bandeja de Notificaciones'), findsOneWidget);

      // Verify fashion support services
      expect(find.text('SERVICIOS Y SOPORTE'), findsOneWidget);
      expect(find.text('Asistente de Moda Attention AI'), findsOneWidget);
      expect(find.text('Guía de Tallas y Medidas'), findsOneWidget);
      expect(find.text('Atención al Cliente y Ayuda'), findsOneWidget);

      // Verify logout button
      expect(find.text('Cerrar Sesión'), findsOneWidget);
    });
  });
}

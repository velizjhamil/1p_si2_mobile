import 'package:flutter/material.dart';

/// Central theme definition for the Attention mobile app.
///
/// Implements Material 3 with customized brand colors:
/// - Primary charcoal: #1F2937
/// - Accent violet: #7C3AED
/// - Semantic palettes tailored for both Light and Dark modes.
class AppTheme {
 AppTheme._();

 static const Color brandCharcoal = Color(0xFF1F2937);
 static const Color brandViolet = Color(0xFF7C3AED);

 /// Light Theme tailored for e-commerce shopping.
 static ThemeData get lightTheme {
 final colorScheme = ColorScheme.fromSeed(
 seedColor: brandCharcoal,
 brightness: Brightness.light,
 primary: brandCharcoal,
 secondary: brandViolet,
 surface: Colors.white,
 );

 return ThemeData(
 useMaterial3: true,
 brightness: Brightness.light,
 colorScheme: colorScheme,
 scaffoldBackgroundColor: const Color(0xFFF9FAFB),
 appBarTheme: const AppBarTheme(
 elevation: 0,
 scrolledUnderElevation: 1,
 centerTitle: false,
 backgroundColor: Colors.white,
 foregroundColor: Color(0xFF111827),
 iconTheme: IconThemeData(color: Color(0xFF111827)),
 ),
 cardTheme: CardThemeData(
 elevation: 0.5,
 color: Colors.white,
 shape: RoundedRectangleBorder(
 borderRadius: BorderRadius.circular(16),
 side: const BorderSide(color: Color(0xFFE5E7EB)),
 ),
 ),
 navigationBarTheme: NavigationBarThemeData(
 elevation: 2,
 backgroundColor: Colors.white,
 indicatorColor: brandCharcoal.withValues(alpha: 0.12),
 labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
 labelTextStyle: WidgetStateProperty.resolveWith((states) {
 if (states.contains(WidgetState.selected)) {
 return const TextStyle(
 fontSize: 12,
 fontWeight: FontWeight.bold,
 color: brandCharcoal,
 );
 }
 return const TextStyle(
 fontSize: 11,
 fontWeight: FontWeight.w500,
 color: Color(0xFF6B7280),
 );
 }),
 iconTheme: WidgetStateProperty.resolveWith((states) {
 if (states.contains(WidgetState.selected)) {
 return const IconThemeData(color: brandCharcoal);
 }
 return const IconThemeData(color: Color(0xFF6B7280));
 }),
 ),
 inputDecorationTheme: InputDecorationTheme(
 filled: true,
 fillColor: Colors.white,
 contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
 border: OutlineInputBorder(
 borderRadius: BorderRadius.circular(14),
 borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
 ),
 enabledBorder: OutlineInputBorder(
 borderRadius: BorderRadius.circular(14),
 borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
 ),
 focusedBorder: OutlineInputBorder(
 borderRadius: BorderRadius.circular(14),
 borderSide: const BorderSide(color: brandCharcoal, width: 1.5),
 ),
 ),
 );
 }

 /// Dark Theme with sleek charcoal/slate tones and high-contrast typography.
 static ThemeData get darkTheme {
 final colorScheme = ColorScheme.fromSeed(
 seedColor: const Color(0xFF818CF8),
 brightness: Brightness.dark,
 primary: const Color(0xFF818CF8),
 secondary: const Color(0xFFA78BFA),
 surface: const Color(0xFF1E293B),
 surfaceContainerHighest: const Color(0xFF334155),
 );

 return ThemeData(
 useMaterial3: true,
 brightness: Brightness.dark,
 colorScheme: colorScheme,
 scaffoldBackgroundColor: const Color(0xFF0F172A),
 appBarTheme: const AppBarTheme(
 elevation: 0,
 scrolledUnderElevation: 1,
 centerTitle: false,
 backgroundColor: Color(0xFF1E293B),
 foregroundColor: Color(0xFFF8FAFC),
 iconTheme: IconThemeData(color: Color(0xFFF8FAFC)),
 ),
 cardTheme: CardThemeData(
 elevation: 0,
 color: const Color(0xFF1E293B),
 shape: RoundedRectangleBorder(
 borderRadius: BorderRadius.circular(16),
 side: const BorderSide(color: Color(0xFF334155)),
 ),
 ),
 navigationBarTheme: NavigationBarThemeData(
 elevation: 2,
 backgroundColor: const Color(0xFF1E293B),
 indicatorColor: const Color(0xFF818CF8).withValues(alpha: 0.25),
 labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
 labelTextStyle: WidgetStateProperty.resolveWith((states) {
 if (states.contains(WidgetState.selected)) {
 return const TextStyle(
 fontSize: 12,
 fontWeight: FontWeight.bold,
 color: Color(0xFF818CF8),
 );
 }
 return const TextStyle(
 fontSize: 11,
 fontWeight: FontWeight.w500,
 color: Color(0xFF94A3B8),
 );
 }),
 iconTheme: WidgetStateProperty.resolveWith((states) {
 if (states.contains(WidgetState.selected)) {
 return const IconThemeData(color: Color(0xFF818CF8));
 }
 return const IconThemeData(color: Color(0xFF94A3B8));
 }),
 ),
 inputDecorationTheme: InputDecorationTheme(
 filled: true,
 fillColor: const Color(0xFF1E293B),
 contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
 border: OutlineInputBorder(
 borderRadius: BorderRadius.circular(14),
 borderSide: const BorderSide(color: Color(0xFF475569)),
 ),
 enabledBorder: OutlineInputBorder(
 borderRadius: BorderRadius.circular(14),
 borderSide: const BorderSide(color: Color(0xFF334155)),
 ),
 focusedBorder: OutlineInputBorder(
 borderRadius: BorderRadius.circular(14),
 borderSide: const BorderSide(color: Color(0xFF818CF8), width: 1.5),
 ),
 ),
 );
 }
}

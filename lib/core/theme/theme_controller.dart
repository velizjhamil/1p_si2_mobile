import 'package:flutter/material.dart';

import '../storage/secure_storage_service.dart';

/// Global controller managing the application's active [ThemeMode].
///
/// Implements [ChangeNotifier] for lightweight, reactive updates without
/// introducing heavy external state management packages.
class ThemeController extends ChangeNotifier {
 ThemeController._();

 static final ThemeController instance = ThemeController._();

 ThemeMode _themeMode = ThemeMode.light;

 ThemeMode get themeMode => _themeMode;

 bool get isDarkMode => _themeMode == ThemeMode.dark;

 /// Loads the persisted theme mode from secure storage during app boot.
 Future<void> init() async {
 try {
 final saved = await SecureStorageService.getThemeMode();
 if (saved != null) {
 switch (saved) {
 case 'dark':
 _themeMode = ThemeMode.dark;
 break;
 case 'light':
 _themeMode = ThemeMode.light;
 break;
 case 'system':
 _themeMode = ThemeMode.system;
 break;
 }
 notifyListeners();
 }
 } catch (_) {
 // Fallback cleanly to default light theme on any storage error
 _themeMode = ThemeMode.light;
 }
 }

 /// Toggles between Light and Dark mode directly.
 Future<void> toggleDarkMode(bool isDark) async {
 await setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
 }

 /// Updates and persists the active [ThemeMode].
 Future<void> setThemeMode(ThemeMode mode) async {
 if (_themeMode == mode) return;

 _themeMode = mode;
 notifyListeners();

 try {
 final String serialized;
 switch (mode) {
 case ThemeMode.dark:
 serialized = 'dark';
 break;
 case ThemeMode.light:
 serialized = 'light';
 break;
 case ThemeMode.system:
 serialized = 'system';
 break;
 }
 await SecureStorageService.saveThemeMode(serialized);
 } catch (_) {
 // Ignore storage persistence failure in volatile environments
 }
 }
}

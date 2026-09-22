import 'package:flutter/material.dart';

import 'core/storage/secure_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/catalog/presentation/screens/home_screen.dart';

void main() async {
 WidgetsFlutterBinding.ensureInitialized();
 await ThemeController.instance.init();
 runApp(const MyApp());
}

class MyApp extends StatelessWidget {
 const MyApp({super.key});

 // This widget is the root of your application.
 @override
 Widget build(BuildContext context) {
 return ListenableBuilder(
 listenable: ThemeController.instance,
 builder: (context, _) {
 return MaterialApp(
 title: 'Attention',
 debugShowCheckedModeBanner: false,
 theme: AppTheme.lightTheme,
 darkTheme: AppTheme.darkTheme,
 themeMode: ThemeController.instance.themeMode,
 home: const _SessionGate(),
 );
 },
 );
 }
}

/// Decides the first screen: restored client session -> HomeScreen,
/// otherwise -> LoginScreen.
///
/// The persisted session is only trusted when BOTH the token and the
/// user session blob exist (both are written together in AuthService);
/// a half-cleared state falls back to the login screen.
class _SessionGate extends StatefulWidget {
 const _SessionGate();

 @override
 State<_SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<_SessionGate> {
 @override
 void initState() {
 super.initState();
 _restoreSession();
 }

 Future<void> _restoreSession() async {
 final token = await SecureStorageService.getToken();
 final session = await SecureStorageService.getUserSession();
 if (!mounted) return;

 final Widget home;
 // Clients-only app: a session persisted with a non-client role is a
 // leftover from older builds and must not grant access.
 final nombreRol = session?['nombre_rol'] as String?;
 if (token != null &&
 token.isNotEmpty &&
 session != null &&
 nombreRol == 'C') {
 home = const HomeScreen();
 } else {
 if (token != null || session != null) {
 // Half-cleared or stale state: clean it up before login.
 await SecureStorageService.clearAll();
 }
 home = const LoginScreen();
 }

 if (!mounted) return;
 Navigator.of(context).pushReplacement(
 MaterialPageRoute(builder: (_) => home),
 );
 }

 @override
 Widget build(BuildContext context) {
 return const Scaffold(
 body: Center(child: CircularProgressIndicator()),
 );
 }
}

import 'dart:async';

import 'package:http/http.dart' as http;

/// Resolves which base URL the app should use to reach the backend,
/// defaulting to the deployed cloud backend in production (Render).
///
/// Configurable en tiempo de compilación con `--dart-define`:
/// - `flutter run --dart-define=API_BASE_URL=https://...`
/// - `flutter run --dart-define=USE_LOCAL_BACKEND=true` (activa sondeo local ADR-002)
class ApiConfig {
 ApiConfig._();

 /// URL pública oficial del backend desplegado en la nube (Render).
 static const String productionBaseUrl =
 'https://attention-backend-czw9.onrender.com/api/v1';

 /// URL base configurada para la API.
 /// Por defecto apunta a la URL oficial de producción en la nube.
 /// Soporta sobreescritura en tiempo de compilación:
 /// `flutter run --dart-define=API_BASE_URL=https://...`
 static const String baseUrl = String.fromEnvironment(
 'API_BASE_URL',
 defaultValue: productionBaseUrl,
 );

 /// Bandera para activar el modo de desarrollo local con sondeo de red (ADR-002).
 /// Por defecto es `false` para que la app se conecte siempre directamente a la nube.
 static const bool useLocalBackend = bool.fromEnvironment(
 'USE_LOCAL_BACKEND',
 defaultValue: false,
 );

 /// Determina si la URL configurada es un servicio remoto en la nube.
 static bool get isRemoteUrl =>
 baseUrl.startsWith('https://') ||
 (!baseUrl.contains('localhost') &&
 !baseUrl.contains('127.0.0.1') &&
 !baseUrl.contains('10.0.2.2') &&
 !baseUrl.contains('192.168.'));

 /// Candidate base URLs para desarrollo local (ADR-002):
 /// 1. Localhost via adb reverse (dispositivo físico USB).
 /// 2. Android emulator host loopback (10.0.2.2).
 /// 3. Windows host LAN IP (192.168.0.2).
 static const List<String> candidateBaseUrls = [
 'http://localhost:8000/api/v1',
 'http://10.0.2.2:8000/api/v1',
 'http://192.168.0.2:8000/api/v1',
 ];

 static const Duration _probeTimeout = Duration(milliseconds: 1500);

 /// Base URL resolved by [resolveBaseUrl] (null until first call).
 static String? _resolved;

 /// Memoizes an in-flight [resolveBaseUrl] call so concurrent callers
 /// (e.g. login + catalog load at startup) don't double-probe.
 static Future<String>? _inFlight;

 /// Retorna la URL base activa para comunicarse con el backend.
 ///
 /// Si la URL es remota (producción) y no se indicó `USE_LOCAL_BACKEND`,
 /// retorna de forma instantánea la URL de producción.
 /// Si `USE_LOCAL_BACKEND=true`, sondea los candidatos locales (ADR-002).
 static Future<String> resolveBaseUrl() async {
 if (_resolved != null) return _resolved!;
 if (_inFlight != null) return _inFlight!;

 // Si apuntamos a producción o servicio remoto, retornamos de inmediato
 if (!useLocalBackend && isRemoteUrl) {
 _resolved = baseUrl;
 return _resolved!;
 }

 final future = _probeAll();
 _inFlight = future;
 try {
 return await future;
 } finally {
 _inFlight = null;
 }
 }

 static Future<String> _probeAll() async {
 final candidates = [
 if (!candidateBaseUrls.contains(baseUrl)) baseUrl,
 ...candidateBaseUrls,
 ];

 for (final url in candidates) {
 if (await _probe(url)) {
 _resolved = url;
 return url;
 }
 }
 _resolved = baseUrl.isNotEmpty ? baseUrl : candidateBaseUrls.first;
 return _resolved!;
 }

 static Future<bool> _probe(String targetUrl) async {
 try {
 final response = await http
 .get(Uri.parse('$targetUrl/productos?limit=1'))
 .timeout(_probeTimeout);
 return response.statusCode > 0;
 } catch (_) {
 return false;
 }
 }
}

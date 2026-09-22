import 'dart:async';

import 'package:http/http.dart' as http;

/// Resolves which base URL the app should use to reach the backend,
/// defaulting to the local/USB environment when available and falling back
/// to the deployed cloud backend in production (Render).
///
/// Configurable en tiempo de compilación con `--dart-define`:
/// - `flutter run --dart-define=API_BASE_URL=http://192.168.0.6:8000/api/v1`
/// - `flutter run --dart-define=USE_LOCAL_BACKEND=true`
class ApiConfig {
  ApiConfig._();

  /// URL pública oficial del backend desplegado en la nube (Render).
  static const String productionBaseUrl =
      'https://attention-backend-czw9.onrender.com/api/v1';

  /// URL base configurada para la API.
  /// Soporta sobreescritura en tiempo de compilación:
  /// `flutter run --dart-define=API_BASE_URL=https://...`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: productionBaseUrl,
  );

  /// Bandera para activar el modo de desarrollo local con sondeo de red (ADR-002).
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
  /// 1. Loopback IPv4 directo via `adb reverse tcp:8000 tcp:8000` (dispositivo físico USB).
  /// 2. IP LAN Wi-Fi directa de la máquina host de desarrollo (192.168.0.6 / 192.168.0.2).
  /// 3. Loopback Android emulator (10.0.2.2).
  /// 4. Localhost estándar.
  static const List<String> candidateBaseUrls = [
    'http://127.0.0.1:8000/api/v1',
    'http://192.168.0.6:8000/api/v1',
    'http://10.0.2.2:8000/api/v1',
    'http://localhost:8000/api/v1',
    'http://192.168.0.2:8000/api/v1',
  ];

  static const Duration _probeTimeout = Duration(milliseconds: 1200);

  /// Base URL resolved by [resolveBaseUrl] (null until first call).
  static String? _resolved;

  /// Memoizes an in-flight [resolveBaseUrl] call so concurrent callers
  /// (e.g. login + catalog load at startup) don't double-probe.
  static Future<String>? _inFlight;

  /// Retorna la URL base activa para comunicarse con el backend.
  ///
  /// Sondea primero los candidatos locales (ADR-002): si `adb reverse` o el
  /// servidor local están activos, conecta inmediatamente a la IP local/loopback.
  /// Si ningún entorno local responde, conmuta de forma transparente al
  /// backend de producción en Render.
  static Future<String> resolveBaseUrl() async {
    if (_resolved != null) return _resolved!;
    if (_inFlight != null) return _inFlight!;

    // Si se especificó explícitamente una URL personalizada distinta a producción:
    if (baseUrl != productionBaseUrl && isRemoteUrl) {
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
    // 1. Sondeo prioritario de entornos locales (USB adb reverse, LAN, emulador)
    for (final url in candidateBaseUrls) {
      if (await _probe(url)) {
        _resolved = url;
        return url;
      }
    }

    // 2. Si no hay backend local respondiendo, fallback seguro a la nube (Render)
    _resolved = productionBaseUrl;
    return _resolved!;
  }

  static Future<bool> _probe(String targetUrl) async {
    try {
      final response = await http
          .get(Uri.parse('$targetUrl/categorias?limit=1'))
          .timeout(_probeTimeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

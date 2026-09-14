import 'dart:async';

import 'package:http/http.dart' as http;

/// Resolves which base URL the app should use to reach the backend,
/// depending on where the app is running (Android emulator, physical
/// device via adb reverse, or web/desktop).
///
/// IMPORTANT for physical Android devices: run
///   adb reverse tcp:8000 tcp:8000
/// so the phone's localhost:8000 reaches the host machine's backend.
/// That path works even when the Windows firewall blocks LAN traffic
/// (no admin rights needed to open firewall rules).
class ApiConfig {
  ApiConfig._();

  /// Candidate base URLs, in probe order:
  /// 1. Android emulator host loopback (10.0.2.2).
  /// 2. Localhost via adb reverse (physical device).
  /// 3. Windows host LAN IP (physical device on same Wi-Fi, when the
  ///    firewall allows inbound :8000).
  static const List<String> candidateBaseUrls = [
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

  /// Probes candidates in order and returns the first reachable base URL.
  ///
  /// Never throws: falls back to the first candidate when nothing answers
  /// (the request layer will surface the connectivity error to the user).
  static Future<String> resolveBaseUrl() async {
    if (_resolved != null) return _resolved!;
    if (_inFlight != null) return _inFlight!;

    final future = _probeAll();
    _inFlight = future;
    try {
      return await future;
    } finally {
      _inFlight = null;
    }
  }

  static Future<String> _probeAll() async {
    // Sequential probing keeps logs and failure modes deterministic.
    for (final url in candidateBaseUrls) {
      if (await _probe(url)) {
        _resolved = url;
        return url;
      }
    }
    // Nothing answered: default to the emulator address; the upcoming
    // request will fail with a clear connectivity message.
    _resolved = candidateBaseUrls.first;
    return _resolved!;
  }

  static Future<bool> _probe(String baseUrl) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/productos?limit=1'))
          .timeout(_probeTimeout);
      // Any HTTP answer (even 4xx/5x) means the transport works.
      return response.statusCode > 0;
    } catch (_) {
      return false;
    }
  }
}

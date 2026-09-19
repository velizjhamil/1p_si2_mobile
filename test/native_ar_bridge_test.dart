import 'package:flutter_test/flutter_test.dart';
import 'package:si2_mobile/features/ar_tryon/data/native_ar_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NativeARBridge unit tests', () {
    test('instantiates with contract defaults', () {
      final bridge = NativeARBridge();
      expect(bridge, isA<IARBridge>());
    });

    test('checkDeviceCompatibility returns false when channel unhandled', () async {
      final bridge = NativeARBridge();
      final isSupported = await bridge.checkDeviceCompatibility();
      expect(isSupported, isFalse);
    });

    test('loadGarmentModel validates non-empty modelUrl', () {
      final bridge = NativeARBridge();
      expect(() => bridge.loadGarmentModel(''), throwsArgumentError);
      expect(() => bridge.loadGarmentModel('   '), throwsArgumentError);
    });
  });
}

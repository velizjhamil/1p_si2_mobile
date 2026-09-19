import 'dart:async';
import 'package:flutter/services.dart';

/// States of the AR tracking engine (ARCore / ARKit / body-pose tracking).
enum ARTrackingState {
  unsupported,
  initializing,
  tracking,
  lost,
  stopped,
}

/// Abstract contract for the Augmented Reality & Virtual Try-On subsystem.
///
/// Decouples UI and business logic from platform-specific SDKs (ARCore on Android,
/// ARKit on iOS, or custom native ML body-pose estimators).
abstract class IARBridge {
  /// Verifies if the host device hardware and OS support AR body tracking.
  Future<bool> checkDeviceCompatibility();

  /// Initializes the native AR camera and pose estimation session.
  Future<bool> initializeSession();

  /// Streams 3D garment mesh/asset (.glb, .usdz) to the native renderer.
  Future<bool> loadGarmentModel(String modelUrl);

  /// Broadcast stream emitting the real-time tracking status.
  Stream<ARTrackingState> get trackingStateStream;

  /// Closes the native camera feed, releases ML buffers, and cleans up memory.
  Future<void> disposeSession();
}

/// Default implementation of [IARBridge] communicating via Flutter Platform Channels.
///
/// Communicates with native host code using:
/// - MethodChannel: `com.attention.mobile/ar_bridge`
/// - EventChannel: `com.attention.mobile/ar_bridge/tracking`
class NativeARBridge implements IARBridge {
  NativeARBridge({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  })  : _methodChannel =
            methodChannel ?? const MethodChannel('com.attention.mobile/ar_bridge'),
        _eventChannel = eventChannel ??
            const EventChannel('com.attention.mobile/ar_bridge/tracking');

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  Stream<ARTrackingState>? _trackingStream;

  @override
  Future<bool> checkDeviceCompatibility() async {
    try {
      final bool? isSupported =
          await _methodChannel.invokeMethod<bool>('checkCompatibility');
      return isSupported ?? false;
    } on MissingPluginException {
      // Platform channel not registered in test environment or mock device.
      return false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  @override
  Future<bool> initializeSession() async {
    try {
      final bool? success =
          await _methodChannel.invokeMethod<bool>('initializeSession');
      return success ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  @override
  Future<bool> loadGarmentModel(String modelUrl) async {
    if (modelUrl.trim().isEmpty) {
      throw ArgumentError.notNull('modelUrl cannot be empty');
    }

    try {
      final bool? loaded = await _methodChannel.invokeMethod<bool>(
        'loadGarmentModel',
        {'modelUrl': modelUrl},
      );
      return loaded ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  @override
  Stream<ARTrackingState> get trackingStateStream {
    _trackingStream ??= _eventChannel
        .receiveBroadcastStream()
        .map<ARTrackingState>((dynamic event) {
          final String status = (event as String? ?? '').toLowerCase();
          switch (status) {
            case 'tracking':
              return ARTrackingState.tracking;
            case 'lost':
              return ARTrackingState.lost;
            case 'initializing':
              return ARTrackingState.initializing;
            case 'unsupported':
              return ARTrackingState.unsupported;
            default:
              return ARTrackingState.stopped;
          }
        })
        .handleError((dynamic _) => ARTrackingState.lost);

    return _trackingStream!;
  }

  @override
  Future<void> disposeSession() async {
    try {
      await _methodChannel.invokeMethod<void>('disposeSession');
    } on MissingPluginException {
      // Graceful ignore when running on platforms without native implementation.
    } on PlatformException catch (_) {
      // Graceful ignore
    }
  }
}

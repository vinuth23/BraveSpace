import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A wrapper for Unity integration that falls back to a placeholder when Unity is not available
class UnityWrapper {
  static const MethodChannel _channel =
      MethodChannel('com.unity3d.player/unity');
  static final StreamController<Map<String, dynamic>> _streamController =
      StreamController<Map<String, dynamic>>.broadcast();

  static bool _isUnityAvailable = false;
  static bool _hasCheckedAvailability = false;

  /// Streams messages from Unity
  static Stream<Map<String, dynamic>> get onUnityMessage =>
      _streamController.stream;

  /// Checks if Unity is available
  static Future<bool> isUnityAvailable() async {
    if (!_hasCheckedAvailability) {
      try {
        _isUnityAvailable =
            await _channel.invokeMethod('isUnityAvailable') ?? false;
      } catch (e) {
        _isUnityAvailable = false;
        print('Unity not available: $e');
      }
      _hasCheckedAvailability = true;
    }
    return _isUnityAvailable;
  }

  /// Sends a message to Unity
  static Future<void> sendMessageToUnity(
      String gameObject, String methodName, String message) async {
    if (!await isUnityAvailable()) {
      print(
          'Unity not available, message not sent: $gameObject.$methodName($message)');
      return;
    }

    try {
      await _channel.invokeMethod('sendMessage', {
        'gameObject': gameObject,
        'methodName': methodName,
        'message': message,
      });
    } catch (e) {
      print('Error sending message to Unity: $e');
    }
  }

  /// Initializes Unity
  static Future<void> initialize() async {
    if (!_hasCheckedAvailability) {
      await isUnityAvailable();
    }

    if (!_isUnityAvailable) {
      print('Unity not available, skipping initialization');
      return;
    }

    try {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onUnityMessage') {
          final Map<String, dynamic> message =
              Map<String, dynamic>.from(call.arguments);
          _streamController.add(message);
        }
        return null;
      });
    } catch (e) {
      print('Error initializing Unity: $e');
    }
  }
}

/// A widget that displays Unity content or a fallback widget when Unity is not available
class UnityWidget extends StatefulWidget {
  final Widget? fallback;
  final Color backgroundColor;
  final bool fullscreen;

  const UnityWidget({
    Key? key,
    this.fallback,
    this.backgroundColor = Colors.black,
    this.fullscreen = false,
  }) : super(key: key);

  @override
  UnityWidgetState createState() => UnityWidgetState();
}

class UnityWidgetState extends State<UnityWidget> {
  bool _isUnityAvailable = false;
  bool _isUnityInitialized = false;

  @override
  void initState() {
    super.initState();
    _checkUnityAvailability();
  }

  Future<void> _checkUnityAvailability() async {
    final isAvailable = await UnityWrapper.isUnityAvailable();

    if (mounted) {
      setState(() {
        _isUnityAvailable = isAvailable;
      });
    }

    if (isAvailable && !_isUnityInitialized) {
      await UnityWrapper.initialize();
      if (mounted) {
        setState(() {
          _isUnityInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isUnityAvailable) {
      return widget.fallback ?? _buildDefaultFallback();
    }

    try {
      if (widget.fullscreen) {
        return Container(
          color: widget.backgroundColor,
          child: const AndroidView(
            viewType: 'com.unity3d.player/unityView',
            creationParamsCodec: StandardMessageCodec(),
          ),
        );
      } else {
        return Container(
          color: widget.backgroundColor,
          child: const AndroidView(
            viewType: 'com.unity3d.player/unityView',
            creationParamsCodec: StandardMessageCodec(),
          ),
        );
      }
    } catch (e) {
      print('Error building Unity widget: $e');
      return widget.fallback ?? _buildDefaultFallback();
    }
  }

  Widget _buildDefaultFallback() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videogame_asset_off,
              size: 64,
              color: Colors.white,
            ),
            SizedBox(height: 16),
            Text(
              'Unity content not available',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

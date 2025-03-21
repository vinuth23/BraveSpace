import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A wrapper for Unity integration in Flutter
class UnityWidget extends StatefulWidget {
  final Function(dynamic)? onUnityMessage;
  final Function(SceneLoaded)? onUnitySceneLoaded;
  final Function(UnityWidgetController)? onUnityCreated;
  final bool fullscreen;

  const UnityWidget({
    Key? key,
    this.onUnityMessage,
    this.onUnitySceneLoaded,
    this.onUnityCreated,
    this.fullscreen = false,
  }) : super(key: key);

  @override
  _UnityWidgetState createState() => _UnityWidgetState();
}

class _UnityWidgetState extends State<UnityWidget> {
  static const MethodChannel _channel =
      MethodChannel('com.bravespace.unity/communication');

  final StreamController<dynamic> _onUnityMessageStreamController =
      StreamController<dynamic>.broadcast();

  Stream<dynamic> get onUnityMessage => _onUnityMessageStreamController.stream;
  late UnityWidgetController _controller;

  @override
  void initState() {
    super.initState();
    _setupMethodChannel();
    _createUnityPlayer();

    // Create controller and pass to callback
    _controller = UnityWidgetController(_channel, onUnityMessage);
    if (widget.onUnityCreated != null) {
      widget.onUnityCreated!(_controller);
    }
  }

  void _setupMethodChannel() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onUnityMessage':
          final dynamic message = call.arguments;
          _onUnityMessageStreamController.add(message);
          if (widget.onUnityMessage != null) {
            widget.onUnityMessage!(message);
          }
          break;
        case 'onUnitySceneLoaded':
          if (widget.onUnitySceneLoaded != null) {
            final Map<String, dynamic> arguments =
                Map<String, dynamic>.from(call.arguments);
            final String name = arguments['name'] as String? ?? '';
            final int buildIndex = arguments['buildIndex'] as int? ?? 0;
            final bool isLoaded = arguments['isLoaded'] as bool? ?? false;
            final bool isValid = arguments['isValid'] as bool? ?? false;

            widget.onUnitySceneLoaded!(
              SceneLoaded(
                name: name,
                buildIndex: buildIndex,
                isLoaded: isLoaded,
                isValid: isValid,
              ),
            );
          }
          break;
      }
      return null;
    });
  }

  Future<void> _createUnityPlayer() async {
    try {
      await _channel.invokeMethod('createUnityPlayer');
    } on PlatformException catch (e) {
      debugPrint('Failed to create Unity player: ${e.message}');
    }
  }

  void postMessage(
    String gameObjectName,
    String methodName,
    String message,
  ) {
    try {
      _channel.invokeMethod(
        'sendMessageToUnity',
        <String, dynamic>{
          'gameObject': gameObjectName,
          'methodName': methodName,
          'message': message,
        },
      );
    } on PlatformException catch (e) {
      debugPrint('Failed to send message to Unity: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use AndroidView to display the Unity view
    return Container(
      color: Colors.black,
      child: const Center(
        child: Text('Unity View Placeholder',
            style: TextStyle(color: Colors.white, fontSize: 24)),
      ),
    );
  }

  @override
  void dispose() {
    _onUnityMessageStreamController.close();
    super.dispose();
  }
}

/// Model class for Unity scene loaded event
class SceneLoaded {
  final String name;
  final int buildIndex;
  final bool isLoaded;
  final bool isValid;

  SceneLoaded({
    required this.name,
    required this.buildIndex,
    required this.isLoaded,
    required this.isValid,
  });
}

/// UnityWidgetController to control the Unity widget
class UnityWidgetController {
  final MethodChannel _channel;
  final Stream<dynamic> onUnityMessage;

  UnityWidgetController(this._channel, this.onUnityMessage);

  void postMessage(
    String gameObjectName,
    String methodName,
    String message,
  ) {
    try {
      _channel.invokeMethod(
        'sendMessageToUnity',
        <String, dynamic>{
          'gameObject': gameObjectName,
          'methodName': methodName,
          'message': message,
        },
      );
    } on PlatformException catch (e) {
      debugPrint('Failed to send message to Unity: ${e.message}');
    }
  }

  Future<void> pause() async {
    try {
      await _channel.invokeMethod('pauseUnity');
    } on PlatformException catch (e) {
      debugPrint('Failed to pause Unity: ${e.message}');
    }
  }

  Future<void> resume() async {
    try {
      await _channel.invokeMethod('resumeUnity');
    } on PlatformException catch (e) {
      debugPrint('Failed to resume Unity: ${e.message}');
    }
  }

  void dispose() {
    // No need to dispose anything here as the channel is managed by the plugin
  }
}

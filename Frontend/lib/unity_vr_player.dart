import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'unity_wrapper.dart';

class UnityVRPlayerScreen extends StatefulWidget {
  final String sessionId;
  final VoidCallback onClose;

  const UnityVRPlayerScreen({
    Key? key,
    required this.sessionId,
    required this.onClose,
  }) : super(key: key);

  @override
  State<UnityVRPlayerScreen> createState() => _UnityVRPlayerScreenState();
}

class _UnityVRPlayerScreenState extends State<UnityVRPlayerScreen> {
  StreamSubscription<Map<String, dynamic>>? _unityMessageSubscription;
  bool _isUnityReady = false;
  String _statusMessage = "Initializing Unity...";

  @override
  void initState() {
    super.initState();
    _initializeUnity();
  }

  Future<void> _initializeUnity() async {
    // Check if Unity is available
    final isAvailable = await UnityWrapper.isUnityAvailable();

    if (!isAvailable) {
      if (mounted) {
        setState(() {
          _statusMessage = "Unity is not available on this device";
        });
      }
      return;
    }

    // Initialize Unity
    await UnityWrapper.initialize();

    // Listen to messages from Unity
    _unityMessageSubscription = UnityWrapper.onUnityMessage.listen((message) {
      _handleUnityMessage(message);
    });

    // Let Unity know we're ready
    _sendInitialDataToUnity();
  }

  void _sendInitialDataToUnity() {
    // Send the session ID to Unity
    final initialData = {
      'sessionId': widget.sessionId,
      'command': 'initialize'
    };

    UnityWrapper.sendMessageToUnity(
        "GameManager", "ReceiveDataFromFlutter", jsonEncode(initialData));

    setState(() {
      _statusMessage = "Connecting to VR session...";
    });
  }

  void _handleUnityMessage(Map<String, dynamic> message) {
    final type = message['type'];
    final data = message['data'];

    switch (type) {
      case 'ready':
        setState(() {
          _isUnityReady = true;
          _statusMessage = "";
        });
        break;
      case 'status':
        setState(() {
          _statusMessage = data['message'] ?? "Unknown status";
        });
        break;
      case 'error':
        setState(() {
          _statusMessage = "Error: ${data['message'] ?? 'Unknown error'}";
        });
        break;
      default:
        print("Unknown message type from Unity: $type");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Unity view with fallback
          Positioned.fill(
            child: UnityWidget(
              fullscreen: true,
              backgroundColor: Colors.black,
              fallback: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.videogame_asset,
                      size: 64,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _statusMessage,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Status overlay (only visible when Unity is not ready)
          if (!_isUnityReady && _statusMessage.isNotEmpty)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusMessage,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

          // Close button
          Positioned(
            top: 40,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () {
                  widget.onClose();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _unityMessageSubscription?.cancel();
    super.dispose();
  }
}

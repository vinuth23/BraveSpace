import 'package:flutter/material.dart';
import 'dart:convert';
import 'services/vr_service.dart';
import 'unity_wrapper.dart';

class UnityVRPlayerScreen extends StatefulWidget {
  const UnityVRPlayerScreen({Key? key}) : super(key: key);

  @override
  _UnityVRPlayerScreenState createState() => _UnityVRPlayerScreenState();
}

class _UnityVRPlayerScreenState extends State<UnityVRPlayerScreen> {
  UnityWidgetController? _unityWidgetController;
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _isProcessing = false;
  final VRService _vrService = VRService();

  @override
  void dispose() {
    _unityWidgetController?.dispose();
    super.dispose();
  }

  void _onUnityCreated(UnityWidgetController controller) {
    _unityWidgetController = controller;

    // Set up message handler from Unity
    controller.onUnityMessage.listen((message) {
      print('Message from Unity: ${message.toString()}');
      // Handle messages from Unity (like speech completion or scores)
      if (message.toString().contains("transcript")) {
        // Process speech transcript from Unity
        _handleTranscriptFromUnity(message.toString());
      }
    });
  }

  Future<void> _handleTranscriptFromUnity(String message) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Parse the message and extract transcript
      final Map<String, dynamic> data = jsonDecode(message);
      final String transcript = data['transcript'] ?? '';

      // Show transcript to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Processing speech: ${transcript.substring(0, transcript.length > 50 ? 50 : transcript.length)}...')),
      );

      // Analyze the speech using backend
      final analysis = await _vrService.analyzeVRSpeech(transcript);

      // Save VR session
      await _vrService.saveVRSession(
          transcript, analysis, data['duration'] ?? 0);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speech analyzed and saved successfully!')),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing speech: $e')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _togglePlayState() {
    setState(() {
      _isPlaying = !_isPlaying;

      // Send command to Unity
      if (_isPlaying) {
        _unityWidgetController?.postMessage(
            'UnityFlutterBridge', 'HandleFlutterMessage', 'StartClassroom');
      } else {
        _unityWidgetController?.postMessage(
            'UnityFlutterBridge', 'HandleFlutterMessage', 'StopClassroom');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VR Classroom'),
        backgroundColor: const Color(0xFF48CAE4),
      ),
      body: Stack(
        children: [
          // Unity Widget
          UnityWidget(
            onUnityCreated: _onUnityCreated,
            onUnitySceneLoaded: (SceneLoaded scene) {
              print('Unity scene loaded: ${scene.name}');
              setState(() {
                _isLoading = false;
              });
            },
            fullscreen: true,
          ),

          // Loading indicator
          if (_isLoading || _isProcessing)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: Color(0xFF48CAE4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isLoading
                          ? 'Loading VR environment...'
                          : 'Processing speech...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Controls overlay
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton.extended(
                    onPressed:
                        (_isLoading || _isProcessing) ? null : _togglePlayState,
                    label: Text(_isPlaying ? 'Stop' : 'Start'),
                    icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                    backgroundColor: (_isLoading || _isProcessing)
                        ? Colors.grey
                        : const Color(0xFF48CAE4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

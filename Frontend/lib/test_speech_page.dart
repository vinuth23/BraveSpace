import 'package:flutter/material.dart';
import 'services/speech_session_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:record/record.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TestSpeechPage extends StatefulWidget {
  const TestSpeechPage({super.key});

  @override
  State<TestSpeechPage> createState() => _TestSpeechPageState();
}

class _TestSpeechPageState extends State<TestSpeechPage> {
  final SpeechSessionService _sessionService = SpeechSessionService();
  final _speechController = TextEditingController();
  final _topicController = TextEditingController();
  bool _isAnalyzing = false;
  bool _isRecording = false;
  String? _recordingPath;
  Map<String, dynamic>? _analysisResults;
  final _audioRecorder = AudioRecorder();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission is required')),
      );
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        _recordingPath =
            '${directory.path}/speech_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: _recordingPath!,
        );

        setState(() {
          _isRecording = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting recording: $e')),
      );
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
      });

      if (path != null) {
        _recordingPath = path;
        await _transcribeAudio();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error stopping recording: $e')),
      );
    }
  }

  Future<void> _transcribeAudio() async {
    if (_recordingPath == null) return;

    setState(() {
      _isAnalyzing = true;
      _analysisResults = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final token = await user.getIdToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://172.20.10.7:5000/api/test/speech/upload'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath(
          'audio',
          _recordingPath!,
        ),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      // Log the raw response for debugging
      print('Server Response Status: ${response.statusCode}');
      print('Server Response Headers: ${response.headers}');
      print('Server Response Body: $responseData');

      if (response.statusCode == 200) {
        try {
          final data = json.decode(responseData);
          setState(() {
            _speechController.text = data['data']['transcript'];
            _isAnalyzing = false;
          });

          // Automatically analyze the transcribed speech
          await _analyzeSpeech();
        } catch (e) {
          print('Error parsing JSON response: $e');
          print('Raw response data: $responseData');
          throw Exception('Failed to parse server response');
        }
      } else {
        throw Exception(
            'Server returned status code ${response.statusCode}: $responseData');
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error transcribing audio: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _analyzeSpeech() async {
    if (_speechController.text.isEmpty || _topicController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter both topic and speech text')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisResults = null;
    });

    try {
      // First analyze the speech
      final analysis =
          await _sessionService.analyzeSpeech(_speechController.text);

      // Create and save a new session
      final session = SpeechSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: FirebaseAuth.instance.currentUser?.uid ?? 'test_user',
        timestamp: DateTime.now(),
        topic: _topicController.text,
        speechText: _speechController.text,
        metrics: {
          'overallScore': analysis['metrics']['language'] * 0.4 +
              analysis['metrics']['confidence'] * 0.2 +
              analysis['metrics']['fluency'] * 0.2 +
              analysis['metrics']['pronunciation'] * 0.1 +
              analysis['metrics']['structure'] * 0.1,
          'confidenceScore': analysis['metrics']['confidence'],
          'lengthScore': analysis['metrics']['language'],
          'structureScore': analysis['metrics']['structure'],
        },
        duration: analysis['duration'],
        feedback: analysis['feedback'],
      );

      await _sessionService.saveSession(session);

      setState(() {
        _analysisResults = {
          'duration': session.duration,
          'metrics': session.metrics,
          'feedback': session.feedback,
        };
        _isAnalyzing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Speech analyzed and saved successfully!')),
      );
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Speech Analysis'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _topicController,
              decoration: const InputDecoration(
                labelText: 'Speech Topic',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Recording button
            Center(
              child: ElevatedButton.icon(
                onPressed: _isAnalyzing
                    ? null
                    : (_isRecording ? _stopRecording : _startRecording),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isRecording ? Colors.red : const Color(0xFF48CAE4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                label:
                    Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _speechController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Speech Text',
                hintText: 'Your speech will appear here...',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 16),
            if (_isAnalyzing)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Analyzing your speech...'),
                  ],
                ),
              ),
            if (_analysisResults != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Analysis Results:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Duration: ${_analysisResults!['duration']} seconds'),
                      const Divider(),
                      const Text(
                        'Metrics:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...((_analysisResults!['metrics'] as Map<String, dynamic>)
                          .entries
                          .map((e) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(e.key),
                                    Text('${e.value.toStringAsFixed(1)}%'),
                                  ],
                                ),
                              ))),
                      const Divider(),
                      const Text(
                        'Feedback:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...(_analysisResults!['feedback'] as List<String>)
                          .map((feedback) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle,
                                        color: Colors.green, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(feedback)),
                                  ],
                                ),
                              )),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _speechController.dispose();
    _topicController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'services/speech_session_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  Map<String, dynamic>? _analysisResults;

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
        metrics: Map<String, double>.from(analysis['metrics']),
        duration: analysis['duration'] as int,
        feedback: List<String>.from(analysis['feedback']),
      );

      await _sessionService.saveSession(session);

      setState(() {
        _analysisResults = analysis;
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
            TextField(
              controller: _speechController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Speech Text',
                hintText: 'Enter the speech text here...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isAnalyzing ? null : _analyzeSpeech,
              child: _isAnalyzing
                  ? const CircularProgressIndicator()
                  : const Text('Analyze Speech'),
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
    super.dispose();
  }
}

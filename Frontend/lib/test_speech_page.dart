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

  void _displayAnalysisResults(Map<String, dynamic> results) {
    setState(() {
      _analysisResults = results;
      _isAnalyzing = false;
    });

    // Create the analysis results modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          // Extract data from analysis results
          final transcript = results['transcript'] ?? 'No transcript available';
          final overallScore = results['overallScore'] ?? 0;
          final confidenceScore = results['confidenceScore'] ?? 0;
          final feedback = results['feedback'] ?? 'No feedback available';
          final detailedAnalysis =
              results['detailedAnalysis'] as List<dynamic>? ?? [];

          // New fields from enhanced analysis
          final fillerWords = results['fillerWords'] as List<dynamic>? ?? [];
          final repeatedWords =
              results['repeatedWords'] as List<dynamic>? ?? [];
          final speechStats =
              results['speechStats'] as Map<String, dynamic>? ?? {};

          return Container(
            padding: const EdgeInsets.all(20),
            child: ListView(
              controller: scrollController,
              children: [
                // Header
                const Center(
                  child: Text(
                    'Speech Analysis Results',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Overall Scores Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildScoreIndicator(
                        'Overall', overallScore.toDouble(), Colors.blue),
                    _buildScoreIndicator(
                        'Confidence', confidenceScore.toDouble(), Colors.green),
                  ],
                ),
                const SizedBox(height: 24),

                // Personalized Feedback Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Personalized Feedback',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(feedback),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Filler Words Section
                if (fillerWords.isNotEmpty) ...[
                  const Text(
                    'Filler Words',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: fillerWords.map((filler) {
                      return Chip(
                        backgroundColor: Colors.red.withOpacity(0.1),
                        label: Text('${filler['word']} (${filler['count']})'),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Repeated Words Section
                if (repeatedWords.isNotEmpty) ...[
                  const Text(
                    'Repeated Words',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: repeatedWords.map((repeated) {
                      return Chip(
                        backgroundColor: Colors.amber.withOpacity(0.1),
                        label:
                            Text('${repeated['word']} (${repeated['count']})'),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Speech Statistics
                if (speechStats.isNotEmpty) ...[
                  const Text(
                    'Speech Statistics',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildStatRow(
                      'Word Count', '${speechStats['wordCount'] ?? 0}'),
                  _buildStatRow(
                      'Sentence Count', '${speechStats['sentenceCount'] ?? 0}'),
                  _buildStatRow('Avg. Words per Sentence',
                      '${(speechStats['avgWordsPerSentence'] ?? 0).toStringAsFixed(1)}'),
                  _buildStatRow('Filler Word %',
                      '${(speechStats['fillerWordPercentage'] ?? 0).toStringAsFixed(1)}%'),
                  const SizedBox(height: 16),
                ],

                // Transcript Section
                const Text(
                  'Transcript',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildHighlightedTranscript(transcript, fillerWords),
                const SizedBox(height: 20),

                // Detailed Analysis Section
                const Text(
                  'Detailed Analysis',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                ...detailedAnalysis
                    .map((item) => _buildAnalysisItem(item))
                    .toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildScoreIndicator(String label, double score, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 100,
              width: 100,
              child: CircularProgressIndicator(
                value: score / 100,
                strokeWidth: 10,
                backgroundColor: Colors.grey.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Text(
              '${score.toInt()}',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildHighlightedTranscript(
      String transcript, List<dynamic> fillerWords) {
    // If no filler words, just return the plain transcript
    if (fillerWords.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(transcript),
      );
    }

    // Extract just the words from the filler words list
    final fillerWordsList =
        fillerWords.map((fw) => fw['word'].toString().toLowerCase()).toList();

    // Split the transcript into words while preserving spacing and punctuation
    final pattern = RegExp(r'(\s+|[.,!?;:()-])|(\b\w+\b)');
    final matches = pattern.allMatches(transcript);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black, fontSize: 14),
          children: matches.map((match) {
            final word = match.group(0) ?? '';
            final isFillerWord = fillerWordsList.contains(word.toLowerCase());

            return TextSpan(
              text: word,
              style: isFillerWord
                  ? const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      backgroundColor: Color(0x33FF0000),
                    )
                  : null,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAnalysisItem(Map<String, dynamic> item) {
    final category = item['category'] ?? 'Unknown';
    final score = (item['score'] as num?)?.toDouble() ?? 0.0;
    final feedback = item['feedback'] ?? 'No feedback available';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                '${score.toInt()}/100',
                style: TextStyle(
                  color: _getScoreColor(score),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              color: _getScoreColor(score),
              backgroundColor: Colors.grey.withOpacity(0.2),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            feedback,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.amber;
    if (score >= 40) return Colors.orange;
    return Colors.red;
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

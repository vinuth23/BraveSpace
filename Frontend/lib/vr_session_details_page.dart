import 'package:flutter/material.dart';
import 'notifications_page.dart';
import 'main.dart' show launchUnity;
import 'package:record/record.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/speech_session_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VRSessionDetailsPage extends StatefulWidget {
  const VRSessionDetailsPage({super.key});

  @override
  VRSessionDetailsPageState createState() => VRSessionDetailsPageState();
}

class VRSessionDetailsPageState extends State<VRSessionDetailsPage> {
  String videoUrl =
      "https://your-cloud-storage-link.com/video.mp4"; // Replace with backend URL

  // Speech recording variables
  final _audioRecorder = AudioRecorder();
  final SpeechSessionService _sessionService = SpeechSessionService();
  bool _isRecording = false;
  String? _recordingPath;
  bool _isAnalyzing = false;
  String _transcribedText = '';
  String _sessionTopic = 'Classroom Speech';
  Map<String, dynamic>? _analysisResults;

  @override
  void initState() {
    super.initState();
    _requestRecordingPermission();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _requestRecordingPermission() async {
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Microphone permission is required for speech analysis')),
        );
      }
    }
  }

  Future<void> _playVideo(BuildContext context) async {
    try {
      // First start recording speech
      await _startRecording();

      // Then launch Unity app
      await launchUnity();

      // Show information to the user
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('VR scene launched. Recording speech in background...'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Stop recording if Unity failed to launch
      if (_isRecording) {
        await _stopRecording(showResults: false);
      }

      // Show error message if Unity app couldn't be launched
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Failed to launch Unity: $e'),
              const Text(
                'Make sure the Unity app is installed and correctly configured.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  // Start recording audio
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
      print('Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting recording: $e')),
        );
      }
    }
  }

  // Stop recording and analyze speech
  Future<void> _stopRecording({bool showResults = true}) async {
    try {
      if (!_isRecording) return;

      final path = await _audioRecorder.stop();

      setState(() {
        _isRecording = false;
      });

      if (path != null) {
        _recordingPath = path;
        if (showResults) {
          await _transcribeAudio();
        }
      }
    } catch (e) {
      print('Error stopping recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error stopping recording: $e')),
        );
      }
    }
  }

  // Transcribe the recorded audio
  Future<void> _transcribeAudio() async {
    if (_recordingPath == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final token = await user.getIdToken();

      // Use the test endpoint which handles transcription more reliably
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

      print('Server Response Status: ${response.statusCode}');
      print('Server Response Body: $responseData');

      if (response.statusCode == 200) {
        final data = json.decode(responseData);

        // Check if the text is in a language other than English
        final transcript = data['data']['transcript'] ?? '';

        // More comprehensive check for non-English text or malformed results
        final bool hasNonLatinChars =
            RegExp(r'[^\x00-\x7F]').hasMatch(transcript);
        final bool hasWeirdLineBreaks =
            transcript.contains('\n') && transcript.split('\n').length > 2;
        final bool tooShortTranscript =
            transcript.trim().split(' ').length < 3 && transcript.length > 0;
        final bool potentiallyNonEnglish =
            hasNonLatinChars || hasWeirdLineBreaks || tooShortTranscript;

        if (potentiallyNonEnglish) {
          // Alert the user about potentially incorrect language detection
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Speech detection error: Your speech may have been detected in a different language or was unclear. Please try speaking more clearly in English.'),
                duration: Duration(seconds: 5),
                backgroundColor: Colors.orange,
              ),
            );
          }

          // Still continue with what we have, but clean up the text
          final cleanedTranscript =
              transcript.replaceAll('\n', ' ').replaceAll('  ', ' ').trim();

          setState(() {
            _transcribedText = cleanedTranscript;
            _isAnalyzing = false;
          });
        } else {
          setState(() {
            _transcribedText = transcript;
            _isAnalyzing = false;
          });
        }

        // Process the analysis results even if language might be wrong
        // The user might want to save the session anyway
        if (data['data'] != null) {
          await _processResults(data['data']);
        }
      } else {
        throw Exception(
            'Server returned status code ${response.statusCode}: $responseData');
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error analyzing speech: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Process and save results
  Future<void> _processResults(Map<String, dynamic> results) async {
    setState(() {
      _analysisResults = results;
    });

    try {
      // Save the session to Firestore for the progress page
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Clean the transcript for storage
        final cleanTranscript = (results['transcript'] ?? '')
            .toString()
            .replaceAll('\n', ' ')
            .replaceAll('  ', ' ')
            .trim();

        // Create session data using the session service
        final session = SpeechSession(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: user.uid,
          timestamp: DateTime.now(),
          topic: _sessionTopic,
          speechText: cleanTranscript,
          metrics: {
            'overallScore': results['overallScore'] ?? 0,
            'confidenceScore': results['confidenceScore'] ?? 0,
            'fluencyScore':
                results['speechStats']?['fillerWordPercentage'] != null
                    ? 100 -
                        (results['speechStats']['fillerWordPercentage'] as num)
                            .toDouble()
                    : 70,
            'clarityScore': results['detailedAnalysis']?.firstWhere(
                    (item) =>
                        item['category'] == 'Clarity' ||
                        item['category'] == 'Structure',
                    orElse: () => {'score': 75})['score'] ??
                75,
          },
          duration: results['speechStats']?['wordCount'] != null
              ? ((results['speechStats']['wordCount'] as num).toDouble() / 2.5)
                  .toInt()
              : 60, // Estimate duration based on word count
          feedback: [results['feedback'] ?? 'Speech analyzed successfully'],
        );

        // First try saving with the service which also ensures local storage
        await _sessionService.saveSession(session);

        // Save directly to Firestore with a check to ensure persistence
        final docRef =
            await FirebaseFirestore.instance.collection('speech_sessions').add({
          'userId': user.uid,
          'timestamp': FieldValue.serverTimestamp(),
          'topic': _sessionTopic,
          'speechText': cleanTranscript,
          'metrics': {
            'overallScore': results['overallScore'] ?? 0,
            'confidenceScore': results['confidenceScore'] ?? 0,
            'fluencyScore':
                results['speechStats']?['fillerWordPercentage'] != null
                    ? 100 -
                        (results['speechStats']['fillerWordPercentage'] as num)
                            .toDouble()
                    : 70,
            'clarityScore': results['detailedAnalysis']?.firstWhere(
                    (item) =>
                        item['category'] == 'Clarity' ||
                        item['category'] == 'Structure',
                    orElse: () => {'score': 75})['score'] ??
                75,
          },
          'duration': results['speechStats']?['wordCount'] != null
              ? ((results['speechStats']['wordCount'] as num).toDouble() / 2.5)
                  .toInt()
              : 60,
          'feedback': [results['feedback'] ?? 'Speech analyzed successfully'],
        });

        // Verify the document was saved
        print('Session saved to Firestore with ID: ${docRef.id}');
      }

      // Display the results
      _displayAnalysisResults(results);
    } catch (e) {
      print('Error saving speech session: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving results: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      // Still display the analysis even if saving failed
      _displayAnalysisResults(results);
    }
  }

  // Display analysis results
  void _displayAnalysisResults(Map<String, dynamic> results) {
    // Show the results in a bottom sheet
    if (!mounted) return;

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
          // Extract data from results
          final transcript = results['transcript'] ?? 'No transcript available';
          final overallScore = results['overallScore'] ?? 0;
          final confidenceScore = results['confidenceScore'] ?? 0;
          final feedback = results['feedback'] ?? 'No feedback available';
          final detailedAnalysis =
              results['detailedAnalysis'] as List<dynamic>? ?? [];
          final fillerWords = results['fillerWords'] as List<dynamic>? ?? [];
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
                    'VR Speech Analysis Results',
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

                // Transcript Section
                const Text(
                  'Transcript',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(transcript),
                ),
                const SizedBox(height: 20),

                // Detailed Analysis Section
                if (detailedAnalysis.isNotEmpty) ...[
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

                // Done Button
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Results saved to your progress page')),
                    );
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Done'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'VR sessions',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/images/intermediate.jpeg',
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Beginner',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Classroom Speech',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: _isRecording
                                ? () =>
                                    _stopRecording() // Stop if already recording
                                : () => _playVideo(
                                    context), // Start if not recording
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _isRecording ? Colors.red : Colors.white,
                              foregroundColor:
                                  _isRecording ? Colors.white : Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              side: BorderSide(
                                color: _isRecording ? Colors.red : Colors.grey,
                                width: 1.0,
                              ),
                            ),
                            icon: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _isRecording
                                  ? const Icon(Icons.stop)
                                  : Image.asset(
                                      'assets/icons/vr_headset_icon.png',
                                      width: 20,
                                      height: 20,
                                    ),
                            ),
                            label: Text(_isRecording ? 'Stop' : 'Play'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'In the upcoming VR public speaking session, the student will deliver a 2-minute speech in front of a virtual classroom filled with simulated classmates. The scenario will replicate a real classroom setting with audience reactions, including eye contact from classmates, slight background noise, and occasional distractions (such as students shifting in their seats). The goal will be to simulate a realistic public speaking experience and help the student practice confidence, speech clarity, and audience engagement.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Achievements',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _AchievementCard(
                        icon: 'assets/images/master_presenter.jpg',
                        title: 'Master Presenter',
                        description:
                            'Deliver a speech with minimal hesitation or filler words (e.g., "um," "uh").',
                        points: 50,
                      ),
                      const SizedBox(height: 12),
                      _AchievementCard(
                        icon: 'assets/images/master_presenter.jpg',
                        title: 'Eye Contact Expert',
                        description:
                            'Maintain consistent eye contact with different audience members throughout the presentation.',
                        points: 30,
                      ),
                      const SizedBox(height: 12),
                      _AchievementCard(
                        icon: 'assets/images/master_presenter.jpg',
                        title: 'Composure Champion',
                        description:
                            'Successfully maintain composure and continue presenting despite audience distractions.',
                        points: 40,
                      ),
                      const SizedBox(height: 12),
                      _AchievementCard(
                        icon: 'assets/images/master_presenter.jpg',
                        title: 'Voice Virtuoso',
                        description:
                            'Demonstrate excellent voice modulation and clear pronunciation throughout the speech.',
                        points: 35,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Overlay for analysis
          if (_isAnalyzing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Analyzing your speech...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
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

class _AchievementCard extends StatelessWidget {
  final String icon;
  final String title;
  final String description;
  final int points;

  const _AchievementCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              icon,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '+$points XP',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

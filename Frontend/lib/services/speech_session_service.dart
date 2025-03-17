import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'dart:convert';

class SpeechSession {
  final String id;
  final String userId;
  final DateTime timestamp;
  final String topic;
  final String speechText;
  final Map<String, double> metrics;
  final int duration;
  final List<String> feedback;

  SpeechSession({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.topic,
    required this.speechText,
    required this.metrics,
    required this.duration,
    required this.feedback,
  });

  factory SpeechSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SpeechSession(
      id: doc.id,
      userId: data['userId'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      topic: data['topic'] as String,
      speechText: data['speechText'] as String,
      metrics: Map<String, double>.from(data['metrics'] as Map),
      duration: data['duration'] as int,
      feedback: List<String>.from(data['feedback'] as List),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'timestamp': {
        '_seconds': timestamp.millisecondsSinceEpoch ~/ 1000,
        '_nanoseconds': 0
      },
      'topic': topic,
      'speechText': speechText,
      'metrics': metrics,
      'duration': duration,
      'feedback': feedback,
    };
  }
}

class SpeechSessionService {
  final String baseUrl =
      'http://172.20.10.7:5000'; // Physical device IP address
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> _getAuthToken() async {
    return await _auth.currentUser?.getIdToken();
  }

  // Get current user's sessions
  Stream<List<SpeechSession>> getUserSessions() async* {
    final user = _auth.currentUser;
    if (user == null) {
      yield [];
      return;
    }

    while (true) {
      try {
        final token = await _getAuthToken();
        if (token == null) {
          yield [];
          return;
        }

        final response = await http.get(
          Uri.parse('$baseUrl/speech-sessions'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final sessions = (data['sessions'] as List)
              .map((session) => SpeechSession(
                    id: session['id'],
                    userId: session['userId'],
                    timestamp: session['timestamp'] != null
                        ? (session['timestamp'] is Timestamp
                            ? (session['timestamp'] as Timestamp).toDate()
                            : DateTime.fromMillisecondsSinceEpoch(
                                session['timestamp']['_seconds'] * 1000))
                        : DateTime.now(),
                    topic: session['topic'],
                    speechText: session['speechText'],
                    metrics: Map<String, double>.from(
                      session['metrics'].map((key, value) => MapEntry(
                            key,
                            value is int ? value.toDouble() : value as double,
                          )),
                    ),
                    duration: session['duration'],
                    feedback: List<String>.from(session['feedback']),
                  ))
              .toList();
          yield sessions;
        } else {
          yield [];
        }
      } catch (e) {
        print('Error fetching sessions: $e');
        yield [];
      }

      // Wait for 5 seconds before next update
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  // Save a new session
  Future<void> saveSession(SpeechSession session) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/speech-sessions'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(session.toFirestore()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save session');
    }
  }

  // Get user statistics
  Future<Map<String, dynamic>> getUserStats() async {
    final token = await _getAuthToken();
    if (token == null) return {};

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user-stats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {};
    } catch (e) {
      print('Error fetching user stats: $e');
      return {};
    }
  }

  // Mock speech analysis
  Future<Map<String, dynamic>> analyzeSpeech(String speechText) async {
    // Simulate processing delay
    await Future.delayed(const Duration(seconds: 1));

    // Mock analysis results
    final random = math.Random();

    // Count words
    final wordCount = speechText.split(' ').length;

    // Mock metrics calculation
    final metrics = {
      'language': _calculateLanguageScore(speechText),
      'confidence': 70.0 + random.nextDouble() * 20, // Random between 70-90
      'fluency': _calculateFluencyScore(speechText),
      'pronunciation': 75.0 + random.nextDouble() * 15, // Random between 75-90
      'structure': _calculateStructureScore(speechText),
    };

    // Generate feedback based on metrics
    final feedback = _generateFeedback(metrics, wordCount);

    return {
      'metrics': metrics,
      'feedback': feedback,
      'duration': wordCount * 2, // Rough estimate of duration in seconds
    };
  }

  double _calculateLanguageScore(String text) {
    // Mock language analysis
    final words = text.toLowerCase().split(' ');
    final uniqueWords = words.toSet().length;
    final vocabularyScore = math.min((uniqueWords / words.length) * 100, 100);
    return 75.0 + (vocabularyScore * 0.25); // Base 75% + vocabulary bonus
  }

  double _calculateFluencyScore(String text) {
    // Mock fluency analysis
    final sentences = text.split(RegExp(r'[.!?]'));
    final avgWordsPerSentence =
        text.split(' ').length / math.max(sentences.length, 1);

    // Ideal range: 10-15 words per sentence
    final fluencyScore = 85.0 - (math.pow(avgWordsPerSentence - 12.5, 2) / 2);
    return math.max(70.0, math.min(95.0, fluencyScore));
  }

  double _calculateStructureScore(String text) {
    // Mock structure analysis
    final hasIntro = text.length > 50; // Assume has intro if length > 50
    final hasConclusion = text.toLowerCase().contains('thank you') ||
        text.toLowerCase().contains('in conclusion');
    final paragraphs = text.split('\n\n').length;

    double score = 75.0;
    if (hasIntro) score += 5.0;
    if (hasConclusion) score += 5.0;
    if (paragraphs >= 3) score += 10.0;

    return math.min(95.0, score);
  }

  List<String> _generateFeedback(Map<String, double> metrics, int wordCount) {
    final feedback = <String>[];

    // Word count feedback
    if (wordCount < 50) {
      feedback.add('Try to expand your speech with more details');
    } else if (wordCount > 200) {
      feedback.add('Good detailed explanation');
    }

    // Metrics-based feedback
    if (metrics['language']! > 85) {
      feedback.add('Excellent vocabulary usage');
    }
    if (metrics['confidence']! < 80) {
      feedback.add('Try to speak with more confidence');
    }
    if (metrics['fluency']! > 85) {
      feedback.add('Great speech flow and pacing');
    }
    if (metrics['structure']! > 85) {
      feedback.add('Well-structured presentation');
    }

    // Add general encouragement
    feedback.add('Keep practicing to improve further');

    return feedback;
  }
}

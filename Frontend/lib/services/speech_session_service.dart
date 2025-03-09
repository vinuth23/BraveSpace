import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;

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
      'timestamp': Timestamp.fromDate(timestamp),
      'topic': topic,
      'speechText': speechText,
      'metrics': metrics,
      'duration': duration,
      'feedback': feedback,
    };
  }
}

class SpeechSessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user's sessions
  Stream<List<SpeechSession>> getUserSessions() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('speech_sessions')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SpeechSession.fromFirestore(doc))
            .toList());
  }

  // Save a new session
  Future<void> saveSession(SpeechSession session) async {
    await _firestore.collection('speech_sessions').add(session.toFirestore());
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

  // Get session statistics
  Future<Map<String, dynamic>> getUserStats() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    final sessions = await _firestore
        .collection('speech_sessions')
        .where('userId', isEqualTo: user.uid)
        .get();

    if (sessions.docs.isEmpty) {
      return {
        'totalSessions': 0,
        'totalDuration': 0,
        'averageScore': 0.0,
      };
    }

    int totalDuration = 0;
    double totalScore = 0.0;

    for (var doc in sessions.docs) {
      final session = SpeechSession.fromFirestore(doc);
      totalDuration += session.duration;
      totalScore += session.metrics.values.reduce((a, b) => a + b) /
          session.metrics.length;
    }

    return {
      'totalSessions': sessions.docs.length,
      'totalDuration': totalDuration,
      'averageScore': totalScore / sessions.docs.length,
    };
  }
}

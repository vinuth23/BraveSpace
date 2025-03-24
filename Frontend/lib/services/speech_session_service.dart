import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SpeechSession {
  final String id;
  final String userId;
  final DateTime timestamp;
  final String topic;
  final String speechText;
  final Map<String, dynamic> metrics;
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

  factory SpeechSession.fromJson(Map<String, dynamic> json) {
    return SpeechSession(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      timestamp: json['timestamp'] != null
          ? (json['timestamp'] is DateTime
              ? json['timestamp']
              : DateTime.fromMillisecondsSinceEpoch(json['timestamp']))
          : DateTime.now(),
      topic: json['topic'] ?? '',
      speechText: json['speechText'] ?? '',
      metrics: json['metrics'] ?? {},
      duration: json['duration'] ?? 0,
      feedback: List<String>.from(json['feedback'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'topic': topic,
      'speechText': speechText,
      'metrics': metrics,
      'duration': duration,
      'feedback': feedback,
    };
  }
}

class SpeechSessionService {
  final String _baseUrl = 'http://172.20.10.7:5000';
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Analyze speech using natural language processing
  Future<Map<String, dynamic>> analyzeSpeech(String text) async {
    try {
      // If text is too short, return simple analysis
      if (text.trim().isEmpty || text.trim().length < 10) {
        return {
          'metrics': {
            'language': 40.0,
            'confidence': 50.0,
            'fluency': 60.0,
            'pronunciation': 70.0,
            'structure': 65.0,
          },
          'duration': 30,
          'feedback': [
            'Your speech was too short for detailed analysis',
            'Try speaking more to get better feedback'
          ]
        };
      }

      // Count words
      final wordCount = text.trim().split(RegExp(r'\s+')).length;

      // Count sentences
      final sentenceCount = text
          .split(RegExp(r'[.!?]+'))
          .where((s) => s.trim().isNotEmpty)
          .length;

      // Check for filler words
      final fillerWords = [
        'um',
        'uh',
        'like',
        'you know',
        'basically',
        'actually'
      ];
      final lowerText = text.toLowerCase();
      int fillerCount = 0;

      for (var word in fillerWords) {
        final matches = RegExp('\\b$word\\b').allMatches(lowerText);
        fillerCount += matches.length;
      }

      // Calculate fluency score (penalize for filler words)
      final fluencyScore = 100.0 - (fillerCount / wordCount * 100).clamp(0, 40);

      // Calculate structure score based on sentence count and average length
      final avgWordsPerSentence =
          sentenceCount > 0 ? wordCount / sentenceCount : 0;
      final structureScore =
          avgWordsPerSentence > 5 && avgWordsPerSentence < 20 ? 80.0 : 60.0;

      // Calculate language score based on length
      final languageScore =
          wordCount > 100 ? 85.0 : (wordCount > 50 ? 75.0 : 65.0);

      // Generate feedback
      List<String> feedback = [];

      if (wordCount < 30) {
        feedback.add(
            'Your speech is quite short. Try to elaborate more on your points.');
      } else {
        feedback.add('You made some good points in your speech.');
      }

      if (fillerCount > wordCount * 0.1) {
        feedback.add('Try to reduce filler words like "um", "uh", and "like".');
      } else if (fillerCount == 0) {
        feedback.add('Excellent job avoiding filler words!');
      }

      if (avgWordsPerSentence > 25) {
        feedback.add(
            'Your sentences are quite long. Consider using shorter sentences for clarity.');
      } else if (avgWordsPerSentence < 5 && sentenceCount > 3) {
        feedback.add(
            'Your sentences are very short. Try varying sentence length for better flow.');
      } else {
        feedback.add('Good sentence structure and length!');
      }

      // Estimate duration based on word count (average speaking rate of 150 words per minute)
      final duration = (wordCount / 150 * 60).round();

      return {
        'metrics': {
          'language': languageScore,
          'confidence': 75.0, // This would require audio analysis in reality
          'fluency': fluencyScore,
          'pronunciation': 70.0, // This would require audio analysis in reality
          'structure': structureScore,
        },
        'duration': duration,
        'feedback': feedback
      };
    } catch (e) {
      print('Error analyzing speech: $e');
      return {
        'metrics': {
          'language': 60.0,
          'confidence': 60.0,
          'fluency': 60.0,
          'pronunciation': 60.0,
          'structure': 60.0,
        },
        'duration': 60,
        'feedback': ['Error analyzing speech. Please try again.']
      };
    }
  }

  // Save a session to both local storage and server
  Future<bool> saveSession(SpeechSession session) async {
    try {
      // Save to local storage first
      await _saveLocalSession(session);

      // Try to save to server if user is authenticated
      if (_auth.currentUser != null) {
        try {
          final token = await _auth.currentUser!.getIdToken();
          final response = await http.post(
            Uri.parse('$_baseUrl/speech-sessions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({
              'topic': session.topic,
              'speechText': session.speechText,
              'metrics': session.metrics,
              'duration': session.duration,
              'feedback': session.feedback,
            }),
          );

          if (response.statusCode == 200) {
            print('Speech session saved to server successfully');
          } else {
            print('Failed to save speech session to server: ${response.body}');
          }
        } catch (e) {
          print('Error saving session to server: $e');
          // Continue anyway as we've saved to local storage
        }
      }

      return true;
    } catch (e) {
      print('Error in saveSession: $e');
      return false;
    }
  }

  // Save session to local storage
  Future<void> _saveLocalSession(SpeechSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing sessions
      final sessionsJson = prefs.getStringList('speech_sessions') ?? [];
      final sessions = sessionsJson
          .map((json) => SpeechSession.fromJson(jsonDecode(json)))
          .toList();

      // Add new session
      sessions.add(session);

      // Keep only the most recent 20 sessions
      if (sessions.length > 20) {
        sessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        sessions.removeRange(20, sessions.length);
      }

      // Save back to preferences
      final updatedSessionsJson =
          sessions.map((session) => jsonEncode(session.toJson())).toList();

      await prefs.setStringList('speech_sessions', updatedSessionsJson);
    } catch (e) {
      print('Error saving to local storage: $e');
      throw e;
    }
  }

  // Get all sessions for current user
  Future<List<SpeechSession>> getSessions() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // First try to get from server
      try {
        final token = await _auth.currentUser!.getIdToken();
        final response = await http.get(
          Uri.parse('$_baseUrl/speech-sessions'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final sessions = (data['sessions'] as List)
              .map((sessionJson) => SpeechSession.fromJson(sessionJson))
              .toList();

          return sessions;
        }
      } catch (e) {
        print('Error getting sessions from server: $e');
        // Continue to get from local storage
      }

      // Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = prefs.getStringList('speech_sessions') ?? [];

      return sessionsJson
          .map((json) => SpeechSession.fromJson(jsonDecode(json)))
          .where((session) => session.userId == userId)
          .toList();
    } catch (e) {
      print('Error in getSessions: $e');
      return [];
    }
  }

  // COMPATIBILITY METHODS FOR EXISTING CODE

  // Get current user's sessions as a Stream for real-time updates
  Stream<List<SpeechSession>> getUserSessions() async* {
    try {
      // Initial fetch
      final sessions = await getSessions();
      yield sessions;

      // Periodic updates every 5 seconds to simulate real-time
      while (true) {
        await Future.delayed(const Duration(seconds: 5));
        try {
          final updatedSessions = await getSessions();
          yield updatedSessions;
        } catch (e) {
          print('Error in periodic session update: $e');
          // Continue the loop even if there's an error
        }
      }
    } catch (e) {
      print('Error in getUserSessions stream: $e');
      yield [];
    }
  }

  // Get user statistics
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      // First try to get from the server API
      final token = await _auth.currentUser?.getIdToken();
      if (token != null) {
        try {
          final response = await http.get(
            Uri.parse('$_baseUrl/user-stats'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );

          if (response.statusCode == 200) {
            return json.decode(response.body);
          }
        } catch (e) {
          print('Error fetching stats from server: $e');
          // Continue to calculate locally if server fails
        }
      }

      // If server fails, calculate stats locally
      final sessions = await getSessions();

      if (sessions.isEmpty) {
        return {'totalSessions': 0, 'totalDuration': 0, 'averageScore': 0.0};
      }

      int totalDuration = 0;
      double totalScore = 0;

      for (final session in sessions) {
        totalDuration += session.duration;

        // Calculate average score from metrics
        if (session.metrics.isNotEmpty) {
          final sessionAvg = session.metrics.values
                  .map((value) => value is num ? value.toDouble() : 0.0)
                  .reduce((a, b) => a + b) /
              session.metrics.length;
          totalScore += sessionAvg;
        }
      }

      return {
        'totalSessions': sessions.length,
        'totalDuration': totalDuration ~/ 60, // Convert seconds to minutes
        'averageScore': sessions.isEmpty ? 0.0 : totalScore / sessions.length
      };
    } catch (e) {
      print('Error calculating user stats: $e');
      return {'totalSessions': 0, 'totalDuration': 0, 'averageScore': 0.0};
    }
  }
}

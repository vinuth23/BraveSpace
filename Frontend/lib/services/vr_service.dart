import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

// API URL configuration - should match your backend
const String API_BASE_URL = 'http://172.20.10.7:5000';

class VRService {
  // Get the current user's authentication token
  Future<String?> getAuthToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return null;
    }
    return await user.getIdToken();
  }

  // Save a VR session to the backend
  Future<Map<String, dynamic>> saveVRSession(
      String transcript, Map<String, dynamic> analysis, int duration) async {
    final token = await getAuthToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    final response = await http.post(
      Uri.parse('$API_BASE_URL/api/vr-sessions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'transcript': transcript,
        'analysis': analysis,
        'duration': duration,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to save VR session: ${response.body}');
    }
  }

  // Get VR sessions for a user
  Future<List<dynamic>> getVRSessions() async {
    final token = await getAuthToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception('User ID not available');
    }

    final response = await http.get(
      Uri.parse('$API_BASE_URL/api/vr-sessions/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['sessions'] ?? [];
    } else {
      throw Exception('Failed to get VR sessions: ${response.body}');
    }
  }

  // Analyze VR speech using existing backend speech analysis
  Future<Map<String, dynamic>> analyzeVRSpeech(String transcript) async {
    final token = await getAuthToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    final response = await http.post(
      Uri.parse('$API_BASE_URL/api/analyze-speech'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'transcript': transcript,
        'source': 'vr',
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to analyze speech: ${response.body}');
    }
  }
}

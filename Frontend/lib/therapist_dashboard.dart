import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_page.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;

class TherapistDashboard extends StatefulWidget {
  const TherapistDashboard({super.key});

  @override
  State<TherapistDashboard> createState() => _TherapistDashboardState();
}

class _TherapistDashboardState extends State<TherapistDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _managedChildren = [];
  String? _error;
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadManagedChildren();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadManagedChildren() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      // Get the therapist document to find managed children
      final therapistDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!therapistDoc.exists) {
        setState(() {
          _error = 'Therapist profile not found';
          _isLoading = false;
        });
        return;
      }

      final therapistData = therapistDoc.data();
      final List<dynamic> managedChildrenIds =
          therapistData?['managedChildren'] ?? [];

      if (managedChildrenIds.isEmpty) {
        setState(() {
          _managedChildren = [];
          _isLoading = false;
        });
        return;
      }

      // Fetch details for each child
      final List<Map<String, dynamic>> childrenData = [];
      for (final childId in managedChildrenIds) {
        final childDoc =
            await _firestore.collection('users').doc(childId.toString()).get();

        if (childDoc.exists) {
          final data = childDoc.data() ?? {};
          childrenData.add({
            'id': childDoc.id,
            'firstName': data['firstName'] ?? 'Unknown',
            'lastName': data['lastName'] ?? '',
            'email': data['email'] ?? 'No email',
            'profileImage': data['profileImage'],
          });
        }
      }

      setState(() {
        _managedChildren = childrenData;
        _isLoading = false;
      });
    } catch (error) {
      print('Error loading managed children: $error');
      setState(() {
        _error = 'Failed to load managed children: $error';
        _isLoading = false;
      });
    }
  }

  Future<void> _addChildByEmail(String email) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check if email exists in users collection
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .where('role', isEqualTo: 'child')
          .get();

      if (userQuery.docs.isEmpty) {
        setState(() {
          _error = 'No child account found with this email';
          _isLoading = false;
        });
        return;
      }

      // Get the child user document
      final childDoc = userQuery.docs.first;
      final childId = childDoc.id;
      final childData = childDoc.data();

      // Get current therapist document
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      final therapistDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      // Update therapist's managedChildren list
      final List<dynamic> currentChildren =
          (therapistDoc.data()?['managedChildren'] as List?) ?? [];

      if (currentChildren.contains(childId)) {
        setState(() {
          _error = 'Child is already in your managed list';
          _isLoading = false;
        });
        return;
      }

      // Update therapist document with new managed child
      await _firestore.collection('users').doc(currentUser.uid).update({
        'managedChildren': FieldValue.arrayUnion([childId]),
      });

      // Update child's therapistId field
      await _firestore.collection('users').doc(childId).update({
        'therapistId': currentUser.uid,
      });

      // Add the new child to the local list
      setState(() {
        _managedChildren.add({
          'id': childId,
          'firstName': childData['firstName'] ?? 'Unknown',
          'lastName': childData['lastName'] ?? '',
          'email': childData['email'] ?? 'No email',
          'profileImage': childData['profileImage'],
        });
        _isLoading = false;
      });

      // Clear the email field
      _emailController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Child added successfully')),
      );
    } catch (error) {
      print('Error adding child: $error');
      setState(() {
        _error = 'Failed to add child: $error';
        _isLoading = false;
      });
    }
  }

  void _showAddChildDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Child'),
        content: TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Child Email Address',
            hintText: 'Enter the email of the child',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (_emailController.text.isNotEmpty) {
                _addChildByEmail(_emailController.text.trim());
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddChildDialog,
        backgroundColor: const Color(0xFF48CAE4),
        child: const Icon(Icons.add),
      ),
      body: Stack(
        children: [
          // Curved background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF48CAE4),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Therapist Dashboard',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon:
                                const Icon(Icons.refresh, color: Colors.black),
                            onPressed: _loadManagedChildren,
                          ),
                          IconButton(
                            icon: const Icon(Icons.person, color: Colors.black),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ProfilePage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Main content
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(child: Text(_error!))
                          : _managedChildren.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No children added yet.\nUse the + button to add children.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 16),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _managedChildren.length,
                                  itemBuilder: (context, index) {
                                    final child = _managedChildren[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ChildSessionsPage(
                                                      childId: child['id']),
                                            ),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 30,
                                                backgroundColor:
                                                    Colors.grey.shade200,
                                                backgroundImage: child[
                                                            'profileImage'] !=
                                                        null
                                                    ? NetworkImage(
                                                        child['profileImage'])
                                                    : null,
                                                child: child['profileImage'] ==
                                                        null
                                                    ? const Icon(Icons.person,
                                                        size: 30)
                                                    : null,
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '${child['firstName']} ${child['lastName']}',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 18,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      child['email'],
                                                      style: TextStyle(
                                                        color: Colors
                                                            .grey.shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Icon(Icons.chevron_right),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
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

// Page to display a child's sessions
class ChildSessionsPage extends StatefulWidget {
  final String childId;

  const ChildSessionsPage({super.key, required this.childId});

  @override
  State<ChildSessionsPage> createState() => _ChildSessionsPageState();
}

class _ChildSessionsPageState extends State<ChildSessionsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _sessions = [];
  Map<String, dynamic> _childInfo = {};
  String? _error;
  // Add base URL for API requests
  final String baseUrl = 'http://172.20.10.7:5000';

  @override
  void initState() {
    super.initState();
    _loadChildData();
    _loadSessions();
  }

  Future<void> _loadChildData() async {
    try {
      final childDoc =
          await _firestore.collection('users').doc(widget.childId).get();

      if (childDoc.exists) {
        final data = childDoc.data() ?? {};
        setState(() {
          _childInfo = {
            'firstName': data['firstName'] ?? 'Unknown',
            'lastName': data['lastName'] ?? '',
            'email': data['email'] ?? 'No email',
            'profileImage': data['profileImage'],
          };
        });
      }
    } catch (error) {
      print('Error loading child data: $error');
    }
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // First, let's check if the child document exists
      final userDoc =
          await _firestore.collection('users').doc(widget.childId).get();
      if (!userDoc.exists) {
        setState(() {
          _error = 'Child user document not found';
          _isLoading = false;
        });
        return;
      }

      final List<Map<String, dynamic>> allSessions = [];

      // We need to get the auth token for API requests
      final token = await _auth.currentUser?.getIdToken();
      if (token == null) {
        setState(() {
          _error = 'Authentication error';
          _isLoading = false;
        });
        return;
      }

      // Try to get VR sessions from the API
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/api/therapist/child-progress/${widget.childId}'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          // Process all sessions from the API response
          if (data.containsKey('progress') && data['progress'] is List) {
            final progressData = data['progress'] as List;

            for (final session in progressData) {
              // Check if this is a VR session based on fields
              if (session.containsKey('level') ||
                  session.containsKey('score')) {
                allSessions.add({
                  'id': session['id'] ?? 'unknown',
                  'type': 'VR',
                  'timestamp': session['timestamp'] != null
                      ? DateTime.fromMillisecondsSinceEpoch(
                          session['timestamp']['_seconds'] * 1000)
                      : DateTime.now(),
                  'completed': session['completed'] ?? true,
                  'duration': session['duration'] ?? 0,
                  'score': session['score'] ?? 0,
                  'level': session['level'] ?? 'Unknown',
                });
              }
              // Check if this is a speech session based on fields
              else if (session.containsKey('transcript') ||
                  session.containsKey('analysis')) {
                final metrics = <String, double>{};
                if (session.containsKey('analysis') &&
                    session['analysis'] is Map) {
                  final analysis = session['analysis'] as Map;
                  analysis.forEach((key, value) {
                    if (value is num) {
                      metrics[key] = value.toDouble();
                    }
                  });
                }

                allSessions.add({
                  'id': session['id'] ?? 'unknown',
                  'type': 'Speech',
                  'timestamp': session['timestamp'] != null
                      ? DateTime.fromMillisecondsSinceEpoch(
                          session['timestamp']['_seconds'] * 1000)
                      : DateTime.now(),
                  'topic': session['topic'] ?? 'Speech Session',
                  'duration': session['duration'] ?? 0,
                  'metrics': metrics,
                  'speechText': session['transcript'] ?? '',
                  'feedback': session.containsKey('analysis') &&
                          session['analysis'] is Map &&
                          session['analysis'].containsKey('feedback') &&
                          session['analysis']['feedback'] is List
                      ? List<String>.from(
                          session['analysis']['feedback'] as List)
                      : <String>[],
                });
              }
            }
          }
        }
      } catch (e) {
        print('Error fetching sessions from API: $e');
      }

      // If API call failed or returned no sessions, try direct Firestore approach
      if (allSessions.isEmpty) {
        // Try the speech_analysis collection first - this should always work regardless of relationships
        try {
          final speechAnalysisSnapshot = await _firestore
              .collection('speech_analysis')
              .where('userId', isEqualTo: widget.childId)
              .orderBy('timestamp', descending: true)
              .get();

          for (final doc in speechAnalysisSnapshot.docs) {
            final data = doc.data();

            // Convert timestamp to DateTime
            final timestamp = data['timestamp'] is Timestamp
                ? (data['timestamp'] as Timestamp).toDate()
                : DateTime.now();

            // Create metrics map from analysis data
            final metrics = <String, double>{};
            if (data['analysis'] != null && data['analysis'] is Map) {
              final analysis = data['analysis'] as Map;
              analysis.forEach((key, value) {
                if (value is num && key != 'feedback') {
                  metrics[key] = value.toDouble();
                }
              });
            }

            // Extract feedback from analysis
            List<String> feedback = [];
            if (data['analysis'] != null &&
                data['analysis'] is Map &&
                data['analysis']['feedback'] != null &&
                data['analysis']['feedback'] is List) {
              feedback = List<String>.from(data['analysis']['feedback']);
            }

            allSessions.add({
              'id': doc.id,
              'type': 'Speech',
              'timestamp': timestamp,
              'topic': data['topic'] ?? 'Speech Analysis',
              'duration': data['duration'] ?? 0,
              'metrics': metrics,
              'speechText': data['transcript'] ?? '',
              'feedback': feedback,
            });
          }
        } catch (e) {
          print('ERROR: Failed to query speech_analysis collection: $e');
        }

        // Try other collections as before (VR sessions and speech_sessions)
        // First get VR sessions
        try {
          final vrSessionsSnapshot = await _firestore
              .collection('user_sessions') // Use the correct collection
              .where('userId', isEqualTo: widget.childId)
              .orderBy('timestamp', descending: true)
              .get();

          for (final doc in vrSessionsSnapshot.docs) {
            final data = doc.data();

            final timestamp = data['timestamp'] is Timestamp
                ? (data['timestamp'] as Timestamp).toDate()
                : DateTime.now();

            allSessions.add({
              'id': doc.id,
              'type': 'VR',
              'timestamp': timestamp,
              'completed': data['completed'] ?? true,
              'duration': data['duration'] ?? 0,
              'score': data['score'] ?? 0,
              'level': data['level'] ?? 'Unknown',
            });
          }
        } catch (e) {
          print('ERROR: Fallback Firestore for VR sessions also failed: $e');
        }

        // Now try speech sessions in Firestore as fallback
        try {
          final speechSessionsSnapshot = await _firestore
              .collection('speech_sessions') // Use the correct collection
              .where('userId', isEqualTo: widget.childId)
              .orderBy('timestamp', descending: true)
              .get();

          for (final doc in speechSessionsSnapshot.docs) {
            final data = doc.data();

            final timestamp = data['timestamp'] is Timestamp
                ? (data['timestamp'] as Timestamp).toDate()
                : DateTime.now();

            allSessions.add({
              'id': doc.id,
              'type': 'Speech',
              'timestamp': timestamp,
              'topic': data['topic'] ?? 'Speech Session',
              'duration': data['duration'] ?? 0,
              'metrics': data['metrics'] is Map
                  ? Map<String, double>.from(
                      data['metrics'].map((key, value) => MapEntry(
                            key,
                            value is num ? value.toDouble() : 0.0,
                          )),
                    )
                  : <String, double>{},
              'speechText': data['speechText'] ?? data['transcript'] ?? '',
              'feedback': data['feedback'] is List
                  ? List<String>.from(data['feedback'] as List)
                  : <String>[],
            });
          }
        } catch (e) {
          print(
              'ERROR: Fallback Firestore for speech sessions also failed: $e');
        }
      }

      // Sort all sessions by timestamp (newest first)
      allSessions.sort((a, b) =>
          (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

      setState(() {
        _sessions = allSessions;
        _isLoading = false;
        if (allSessions.isEmpty) {
          _error = 'No sessions found for this child';
        }
      });
    } catch (error) {
      print('ERROR: General error loading sessions: $error');
      setState(() {
        _error = 'Failed to load sessions: $error';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final childName = '${_childInfo['firstName']} ${_childInfo['lastName']}';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: Stack(
        children: [
          // Curved background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF48CAE4),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          childName.trim().isNotEmpty
                              ? childName
                              : 'Child Sessions',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.black),
                        onPressed: _loadSessions,
                      ),
                    ],
                  ),
                ),

                // Child info card
                if (_childInfo.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage:
                                  _childInfo['profileImage'] != null
                                      ? NetworkImage(_childInfo['profileImage'])
                                      : null,
                              child: _childInfo['profileImage'] == null
                                  ? const Icon(Icons.person, size: 30)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    childName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  if (_childInfo['email'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        _childInfo['email'],
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Sessions header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Text(
                        'Sessions (${_sessions.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_sessions.isEmpty)
                        const Text(
                          '(Debugging: No sessions found)',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Sessions list
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(child: Text(_error!))
                          : _sessions.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No sessions found',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _sessions.length,
                                  itemBuilder: (context, index) {
                                    final session = _sessions[index];
                                    final isVr = session['type'] == 'VR';
                                    final formattedDate = _formatDate(
                                        session['timestamp'] as DateTime);

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: InkWell(
                                        onTap: () =>
                                            _showSessionDetails(session),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        isVr
                                                            ? Icons.view_in_ar
                                                            : Icons.mic,
                                                        color: const Color(
                                                            0xFF48CAE4),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        '${session['type']} Session',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Text(
                                                    formattedDate,
                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade600,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              if (isVr)
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                        'Level: ${session['level'] ?? 'Unknown'}'),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                                0xFF48CAE4)
                                                            .withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      child: Text(
                                                        'Score: ${session['score']}',
                                                        style: const TextStyle(
                                                          color:
                                                              Color(0xFF48CAE4),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              else
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                        'Topic: ${session['topic'] ?? 'Unknown'}'),
                                                    const SizedBox(height: 4),
                                                    if (session['speechText'] !=
                                                            null &&
                                                        session['speechText']
                                                            .isNotEmpty) ...[
                                                      Text(
                                                        _truncateText(
                                                            session[
                                                                'speechText'],
                                                            100),
                                                        style: TextStyle(
                                                          color: Colors
                                                              .grey.shade600,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          height: 16),
                                                    ],
                                                    if (session['metrics'] !=
                                                            null &&
                                                        session['metrics']
                                                            .isNotEmpty) ...[
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(top: 8.0),
                                                        child: Row(
                                                          children: [
                                                            Text(
                                                              'Score: ${_getAverageScore(session['metrics']).toStringAsFixed(1)}%',
                                                              style:
                                                                  const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Color(
                                                                    0xFF48CAE4),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  double _getAverageScore(Map<String, dynamic> metrics) {
    if (metrics.isEmpty) return 0;
    double sum = 0;
    int count = 0;

    metrics.forEach((key, value) {
      if (value is num) {
        sum += value.toDouble();
        count++;
      }
    });

    return count > 0 ? sum / count : 0;
  }

  void _showSessionDetails(Map<String, dynamic> session) {
    final isVr = session['type'] == 'VR';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // Session title and date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isVr ? Icons.view_in_ar : Icons.mic,
                        color: const Color(0xFF48CAE4),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${session['type']} Session',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Date and time
              Text(
                'Date: ${DateFormat('MMM d, yyyy - h:mm a').format(session['timestamp'] as DateTime)}',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 16,
                ),
              ),

              const Divider(height: 32),

              // Session details
              if (isVr) ...[
                _buildDetailRow('Level', session['level'] ?? 'Unknown'),
                _buildDetailRow('Duration', '${session['duration']} minutes'),
                _buildDetailRow('Score', '${session['score']}'),
                _buildDetailRow(
                    'Completed', session['completed'] ? 'Yes' : 'No'),
              ] else ...[
                _buildDetailRow('Topic', session['topic'] ?? 'Unknown'),
                _buildDetailRow('Duration', '${session['duration']} seconds'),

                const SizedBox(height: 16),

                // Speech text
                if (session['speechText'] != null &&
                    session['speechText'].isNotEmpty) ...[
                  const Text(
                    'Speech Content:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      session['speechText'],
                      style: TextStyle(
                        height: 1.5,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Metrics
                if (session['metrics'] != null &&
                    session['metrics'].isNotEmpty) ...[
                  const Text(
                    'Performance Metrics:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...(_getMetricsWidgets(session['metrics'])),
                  const SizedBox(height: 16),
                ],

                // Feedback
                if (session['feedback'] != null &&
                    (session['feedback'] as List).isNotEmpty) ...[
                  const Text(
                    'Feedback:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...((session['feedback'] as List)
                      .map((feedback) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF48CAE4),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    feedback,
                                    style: const TextStyle(height: 1.3),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList()),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _getMetricsWidgets(Map<String, dynamic> metrics) {
    final List<Widget> widgets = [];

    metrics.forEach((key, value) {
      double? numValue;
      if (value is int) {
        numValue = value.toDouble();
      } else if (value is double) {
        numValue = value;
      }

      if (numValue != null) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      key.replaceFirst(key[0], key[0].toUpperCase()),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${numValue.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: _getMetricColor(numValue),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: numValue / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getMetricColor(numValue),
                  ),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        );
      }
    });

    return widgets;
  }

  Color _getMetricColor(double value) {
    if (value >= 80) {
      return Colors.green;
    } else if (value >= 60) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
}

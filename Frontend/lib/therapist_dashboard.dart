import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// API URL configuration
const String API_BASE_URL = 'http://172.20.10.7:5000';

class TherapistDashboardPage extends StatefulWidget {
  const TherapistDashboardPage({Key? key}) : super(key: key);

  @override
  State<TherapistDashboardPage> createState() => _TherapistDashboardPageState();
}

class _TherapistDashboardPageState extends State<TherapistDashboardPage> {
  bool _isLoading = true;
  List<dynamic> _children = [];
  String? _selectedChildId;
  Map<String, dynamic>? _selectedChildInfo;
  List<dynamic> _childSessions = [];
  String _errorMessage = '';
  final TextEditingController _childEmailController = TextEditingController();
  String _currentApiUrl = API_BASE_URL;
  bool _isRetrying = false;
  int _retryCount = 0;
  bool _useLocalData = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    await _fetchChildren();
    if (_children.isEmpty) {
      _tryFetchFromFirestore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF48CAE4),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Therapist Dashboard',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty && !_useLocalData
              ? _buildErrorView()
              : _buildDashboardContent(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF48CAE4),
        onPressed: _showAssignChildDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDashboardContent() {
    if (_children.isEmpty) {
      return _buildEmptyState();
    }

    return Row(
      children: [
        // Children list sidebar - takes 40% of the screen on mobile
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.4,
          child: Container(
            color: Colors.cyan.shade50,
            child: _buildChildrenList(),
          ),
        ),

        // Main content area - takes 60% of the screen
        Expanded(
          child: _selectedChildId == null
              ? _buildNoChildSelectedView()
              : _buildChildSessionsView(),
        ),
      ],
    );
  }

  Widget _buildNoChildSelectedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Select a client to view their sessions',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.cyan.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: 80,
                color: Colors.cyan.shade300,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No clients assigned yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Add clients to your dashboard by clicking the button below',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showAssignChildDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('Add New Client'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF48CAE4),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildrenList() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: _children.length,
      itemBuilder: (context, index) {
        final child = _children[index];
        final isSelected = _selectedChildId == child['uid'];

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            onTap: () {
              setState(() {
                _selectedChildId = child['uid'];
                _selectedChildInfo = child;
                _childSessions = []; // Clear sessions while loading
              });
              _fetchChildSessions(child['uid']);
            },
            leading: CircleAvatar(
              radius: 20,
              backgroundColor:
                  isSelected ? const Color(0xFF48CAE4) : Colors.grey.shade200,
              child: Text(
                _getInitials(child),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            title: Text(
              '${child['firstName'] ?? ''} ${child['lastName'] ?? ''}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              child['email'] ?? '',
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            selected: isSelected,
            selectedTileColor: Colors.cyan.shade50,
            trailing: isSelected
                ? const Icon(Icons.check_circle,
                    color: Color(0xFF48CAE4), size: 18)
                : null,
          ),
        );
      },
    );
  }

  String _getInitials(Map<String, dynamic> person) {
    final firstName = person['firstName'] as String? ?? '';
    final lastName = person['lastName'] as String? ?? '';

    String initials = '';
    if (firstName.isNotEmpty) initials += firstName[0];
    if (lastName.isNotEmpty) initials += lastName[0];

    return initials.isNotEmpty ? initials.toUpperCase() : '?';
  }

  Widget _buildChildSessionsView() {
    return Column(
      children: [
        // Child header info
        _buildChildInfoHeader(),

        // Sessions list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _childSessions.isEmpty
                  ? _buildEmptySessionsView()
                  : _buildSessionsList(),
        ),
      ],
    );
  }

  Widget _buildChildInfoHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF48CAE4),
            child: Text(
              _getInitials(_selectedChildInfo ?? {}),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_selectedChildInfo?['firstName'] ?? ''} ${_selectedChildInfo?['lastName'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _selectedChildInfo?['email'] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh sessions',
            onPressed: () {
              if (_selectedChildId != null) {
                _fetchChildSessions(_selectedChildId!);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySessionsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 20),
          Text(
            'No sessions for ${_selectedChildInfo?['firstName'] ?? 'this client'} yet',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Sessions will appear here once the client completes some activities',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsList() {
    return RefreshIndicator(
      onRefresh: () async {
        if (_selectedChildId != null) {
          await _fetchChildSessions(_selectedChildId!);
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _childSessions.length,
        itemBuilder: (context, index) {
          final session = _childSessions[index];
          final analysis = session['analysis'] ?? {};
          final timestamp = _getSessionTimestamp(session);
          final formattedDate =
              DateFormat('MMM d, yyyy - h:mm a').format(timestamp);

          return Card(
            margin: const EdgeInsets.only(bottom: 12, left: 8, right: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Color(0xFF48CAE4),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF48CAE4),
                            ),
                          ),
                        ],
                      ),
                      _buildScoreChip(analysis['overallScore'] ?? 0),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (session['transcript'] != null &&
                      session['transcript'].toString().trim().isNotEmpty)
                    Text(
                      session['transcript'] ?? 'No transcript available',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(height: 1.4),
                    )
                  else
                    Text(
                      'No transcript available',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildMetricColumn(
                            'Confidence', analysis['confidenceScore'] ?? 0),
                        _buildDivider(),
                        _buildMetricColumn(
                            'Grammar', analysis['grammarScore'] ?? 0),
                        _buildDivider(),
                        _buildMetricColumn(
                            'Clarity', analysis['clarityScore'] ?? 0),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey.shade200,
    );
  }

  DateTime _getSessionTimestamp(Map<String, dynamic> session) {
    if (session['timestamp'] != null) {
      if (session['timestamp'] is Map &&
          session['timestamp']['_seconds'] != null) {
        return DateTime.fromMillisecondsSinceEpoch(
            session['timestamp']['_seconds'] * 1000);
      } else if (session['timestamp'] is Timestamp) {
        return (session['timestamp'] as Timestamp).toDate();
      }
    }
    return DateTime.now();
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Icons.cloud_off, size: 64, color: Colors.red.shade300),
            ),
            const SizedBox(height: 24),
            Text(
              'Connection Issue',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage.isEmpty
                  ? 'Unable to connect to the server. Please check your network connection.'
                  : _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _fetchData,
              icon: const Icon(Icons.refresh),
              label: Text(_isRetrying ? 'Trying again...' : 'Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF48CAE4),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _useOfflineMode,
              child: const Text('Continue in Offline Mode'),
            ),
          ],
        ),
      ),
    );
  }

  void _useOfflineMode() {
    setState(() {
      _useLocalData = true;
      _errorMessage = '';
      _isLoading = false;
    });
    _tryFetchFromFirestore();
  }

  Widget _buildScoreChip(int score) {
    final color = score >= 80
        ? Colors.green
        : score >= 60
            ? Colors.orange
            : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        '$score',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildMetricColumn(String label, int value) {
    final color = value >= 80
        ? Colors.green
        : value >= 60
            ? Colors.orange
            : Colors.redAccent;

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showAssignChildDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Add Client'),
        content: TextField(
          controller: _childEmailController,
          decoration: InputDecoration(
            labelText: 'Client Email',
            hintText: 'Enter the email of the client to add',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            prefixIcon: const Icon(Icons.email),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _assignChild();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF48CAE4),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Add Client'),
          ),
        ],
      ),
    );
  }

  Future<void> _tryFetchFromFirestore() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return;
      }

      // Get user document to find their role
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        return;
      }

      List<dynamic> childrenList = [];

      // Handle differently based on role
      final userData = userDoc.data()!;
      if (userData['role'] == 'therapist') {
        // For therapist, get their assigned children
        final assignedChildren = await FirebaseFirestore.instance
            .collection('therapist_children')
            .where('therapistId', isEqualTo: user.uid)
            .get();

        // Get child details
        for (var doc in assignedChildren.docs) {
          final childId = doc.data()['childId'];
          final childDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(childId)
              .get();

          if (childDoc.exists) {
            final childData = childDoc.data()!;
            childData['uid'] = childId;
            childrenList.add(childData);
          }
        }
      } else if (userData['role'] == 'parent') {
        // For parent, get their children
        final children = await FirebaseFirestore.instance
            .collection('users')
            .where('parentId', isEqualTo: user.uid)
            .get();

        for (var doc in children.docs) {
          final childData = doc.data();
          childData['uid'] = doc.id;
          childrenList.add(childData);
        }
      }

      setState(() {
        _children = childrenList;
        _isLoading = false;

        if (_children.isNotEmpty && _selectedChildId == null) {
          _selectedChildId = _children[0]['uid'];
          _selectedChildInfo = _children[0];
          _fetchChildSessionsFromFirestore(_selectedChildId!);
        }
      });
    } catch (e) {
      print('Error fetching from Firestore: $e');
      setState(() {
        _isLoading = false;
        if (_children.isEmpty) {
          // Generate mock data if we couldn't get real data
          _generateMockData();
        }
      });
    }
  }

  Future<void> _fetchChildSessionsFromFirestore(String childId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final sessionsSnapshot = await FirebaseFirestore.instance
          .collection('speech_sessions')
          .where('userId', isEqualTo: childId)
          .orderBy('timestamp', descending: true)
          .get();

      final sessionsList = sessionsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      setState(() {
        _childSessions = sessionsList;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching sessions from Firestore: $e');
      setState(() {
        _isLoading = false;
        // Generate mock sessions for this child
        _generateMockSessions(childId);
      });
    }
  }

  void _generateMockData() {
    setState(() {
      _useLocalData = true;
      _children = [
        {
          'uid': 'mock-child-1',
          'firstName': 'Alex',
          'lastName': 'Johnson',
          'email': 'alex.johnson@example.com',
          'role': 'child'
        },
        {
          'uid': 'mock-child-2',
          'firstName': 'Taylor',
          'lastName': 'Smith',
          'email': 'taylor.smith@example.com',
          'role': 'child'
        },
        {
          'uid': 'mock-child-3',
          'firstName': 'Jamie',
          'lastName': 'Williams',
          'email': 'jamie.williams@example.com',
          'role': 'child'
        }
      ];

      if (_selectedChildId == null && _children.isNotEmpty) {
        _selectedChildId = _children[0]['uid'];
        _selectedChildInfo = _children[0];
        _generateMockSessions(_selectedChildId!);
      }
    });
  }

  void _generateMockSessions(String childId) {
    final now = DateTime.now();

    final mockSessions = [
      {
        'id': 'mock-session-1',
        'userId': childId,
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
        'transcript':
            'This is a practice speech about my favorite book that I read last summer.',
        'analysis': {
          'overallScore': 78,
          'confidenceScore': 82,
          'grammarScore': 75,
          'clarityScore': 80
        }
      },
      {
        'id': 'mock-session-2',
        'userId': childId,
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
        'transcript':
            'Today I want to talk about why recycling is important for our environment.',
        'analysis': {
          'overallScore': 85,
          'confidenceScore': 88,
          'grammarScore': 83,
          'clarityScore': 84
        }
      },
      {
        'id': 'mock-session-3',
        'userId': childId,
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 10))),
        'transcript': 'My presentation is about planets in our solar system.',
        'analysis': {
          'overallScore': 72,
          'confidenceScore': 70,
          'grammarScore': 75,
          'clarityScore': 68
        }
      }
    ];

    setState(() {
      _childSessions = mockSessions;
    });
  }

  Future<void> _fetchChildren() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _isRetrying = _retryCount > 0;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please sign in to continue.';
        });
        return;
      }

      final token = await user.getIdToken();

      final response = await http.get(
        Uri.parse('$_currentApiUrl/api/therapist/children'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timed out. Please check your network.');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _children = data['children'] ?? [];
          _isLoading = false;
          _retryCount = 0;

          if (_children.isNotEmpty && _selectedChildId == null) {
            _selectedChildId = _children[0]['uid'];
            _selectedChildInfo = _children[0];
            _fetchChildSessions(_selectedChildId!);
          }
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Server error: ${response.statusCode}';
          _retryCount++;
        });

        // If we've retried a few times, try Firestore directly
        if (_retryCount >= 2) {
          _tryFetchFromFirestore();
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
        _retryCount++;
      });

      // If we've retried a few times, try Firestore directly
      if (_retryCount >= 2) {
        _tryFetchFromFirestore();
      }
    }
  }

  Future<void> _fetchChildSessions(String childId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User not logged in';
        });
        return;
      }

      final token = await user.getIdToken();
      final response = await http.get(
        Uri.parse('$_currentApiUrl/api/therapist/child-progress/$childId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('Connection timed out while fetching sessions.');
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<dynamic> sessionsData = [];
        if (data['progress'] != null) {
          sessionsData = data['progress'];
        }

        setState(() {
          _childSessions = sessionsData;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load session data: ${response.statusCode}';
        });

        // Fall back to Firestore
        _fetchChildSessionsFromFirestore(childId);
      }
    } catch (e) {
      print('Error loading sessions data: $e');
      setState(() {
        _isLoading = false;
      });

      // Fall back to Firestore
      _fetchChildSessionsFromFirestore(childId);
    }
  }

  Future<void> _assignChild() async {
    if (_childEmailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter client email')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (_useLocalData) {
        // Handle offline mode - add a mock child
        final newChild = {
          'uid': 'mock-child-${DateTime.now().millisecondsSinceEpoch}',
          'firstName': _childEmailController.text.split('@')[0],
          'lastName': 'Added',
          'email': _childEmailController.text.trim(),
          'role': 'child'
        };

        setState(() {
          _children.add(newChild);
          _isLoading = false;
        });

        _childEmailController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Client added in offline mode')),
        );
        return;
      }

      final token = await user.getIdToken();
      final response = await http.post(
        Uri.parse('$_currentApiUrl/api/therapist/assign-child'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'childEmail': _childEmailController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        _childEmailController.clear();
        _fetchChildren();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Client added successfully')),
        );
      } else {
        final error = json.decode(response.body);
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error['error'] ?? 'Failed to add client')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

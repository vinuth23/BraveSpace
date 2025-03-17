import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'profile_page.dart';

// API URL configuration
const String API_BASE_URL =
    'http://172.20.10.7:5000'; // Updated to match Docker backend port

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
  List<dynamic> _childProgressData = [];
  String _errorMessage = '';
  final TextEditingController _childEmailController = TextEditingController();
  final TextEditingController _serverUrlController =
      TextEditingController(text: API_BASE_URL);
  String _currentApiUrl = API_BASE_URL;

  @override
  void initState() {
    super.initState();
    // Simple direct approach - fetch data immediately
    _fetchChildren();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: Stack(
        children: [
          // Background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 350,
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

          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white))
                      : _errorMessage.isNotEmpty
                          ? _buildErrorView()
                          : _buildDashboardContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
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
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.black),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    if (_children.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildClientSelector(),
        Expanded(
          child: _selectedChildId == null
              ? const Center(
                  child: Text('Select a client to view their progress'))
              : _buildChildProgressView(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 80, color: Colors.white),
          const SizedBox(height: 20),
          const Text(
            'No clients assigned yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _showAssignChildDialog,
            icon: const Icon(Icons.person_add),
            label: const Text('Assign New Client'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF48CAE4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientSelector() {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        itemCount: _children.length,
        itemBuilder: (context, index) {
          final child = _children[index];
          final isSelected = _selectedChildId == child['uid'];
          return _buildClientCard(child, isSelected);
        },
      ),
    );
  }

  Widget _buildClientCard(Map<String, dynamic> child, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedChildId = child['uid'];
          _selectedChildInfo = child;
        });
        _fetchChildProgress(child['uid']);
      },
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: isSelected
                  ? const Color(0xFF48CAE4)
                  : Colors.white.withOpacity(0.6),
              child: Text(
                '${child['firstName'][0]}${child['lastName'][0]}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF48CAE4),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              child['firstName'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isSelected ? const Color(0xFF48CAE4) : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildProgressView() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: _childProgressData.isEmpty
          ? _buildEmptyProgressView()
          : _buildProgressContent(),
    );
  }

  Widget _buildEmptyProgressView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.line_axis_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(
            'No progress data for ${_selectedChildInfo?['firstName'] ?? 'this client'} yet',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressContent() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChildInfo(),
          const SizedBox(height: 16),
          _buildProgressCharts(),
          const SizedBox(height: 16),
          Expanded(
            child: _buildSessionList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChildInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF48CAE4).withOpacity(0.2),
            child: Text(
              '${_selectedChildInfo?['firstName'][0]}${_selectedChildInfo?['lastName'][0]}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF48CAE4),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_selectedChildInfo?['firstName']} ${_selectedChildInfo?['lastName']}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  _selectedChildInfo?['email'] ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCharts() {
    if (_childProgressData.length < 2) {
      return Center(
        child: Text(
          'Not enough data to generate progress charts',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return Container(
      height: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildLegendItem('Overall', const Color(0xFF48CAE4)),
              const SizedBox(width: 16),
              _buildLegendItem('Confidence', Colors.green),
              const SizedBox(width: 16),
              _buildLegendItem('Grammar', Colors.orange),
              const SizedBox(width: 16),
              _buildLegendItem('Clarity', Colors.purple),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildProgressChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChart() {
    final progressPoints = _processProgressData();
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withOpacity(0.2),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 &&
                    value.toInt() < progressPoints.length) {
                  final timestamp = progressPoints[value.toInt()]['timestamp'];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('MM/dd').format(timestamp),
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: progressPoints.length.toDouble() - 1,
        minY: 0,
        maxY: 100,
        lineBarsData: [
          _buildLineChartBarData(
              progressPoints, 'overallScore', const Color(0xFF48CAE4)),
          _buildLineChartBarData(
              progressPoints, 'confidenceScore', Colors.green),
          _buildLineChartBarData(progressPoints, 'grammarScore', Colors.orange),
          _buildLineChartBarData(progressPoints, 'clarityScore', Colors.purple),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _processProgressData() {
    if (_childProgressData.isEmpty) {
      return [];
    }

    try {
      return _childProgressData.map<Map<String, dynamic>>((session) {
        // Check if analysis exists, if not use empty map
        final analysis = session['analysis'] ?? {};

        return {
          'timestamp': session['timestamp'] != null
              ? DateTime.fromMillisecondsSinceEpoch(
                  session['timestamp']['_seconds'] * 1000)
              : DateTime.now(),
          'overallScore': analysis['overallScore'] ?? 0,
          'confidenceScore': analysis['confidenceScore'] ?? 0,
          'grammarScore': analysis['grammarScore'] ?? 0,
          'clarityScore': analysis['clarityScore'] ?? 0,
        };
      }).toList()
        ..sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
    } catch (e) {
      print('Error processing progress data: $e');
      return [];
    }
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  LineChartBarData _buildLineChartBarData(
      List<Map<String, dynamic>> data, String metric, Color color) {
    final spots = List.generate(
      data.length,
      (i) => FlSpot(i.toDouble(), data[i][metric].toDouble()),
    );

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(show: true),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.1),
      ),
    );
  }

  Widget _buildSessionList() {
    return ListView.builder(
      itemCount: _childProgressData.length,
      itemBuilder: (context, index) {
        final session = _childProgressData[index];
        return _buildSessionCard(session);
      },
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    // Check if necessary data exists
    final analysis = session['analysis'] ?? {};
    final timestamp = session['timestamp'] != null
        ? DateTime.fromMillisecondsSinceEpoch(
            session['timestamp']['_seconds'] * 1000)
        : DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM d, yyyy - h:mm a').format(timestamp),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                _buildScoreChip(analysis['overallScore'] ?? 0),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              session['transcript'] ?? 'No transcript available',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMetricColumn(
                    'Confidence', analysis['confidenceScore'] ?? 0),
                _buildMetricColumn('Grammar', analysis['grammarScore'] ?? 0),
                _buildMetricColumn('Clarity', analysis['clarityScore'] ?? 0),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreChip(int score) {
    final color = score >= 80
        ? const Color(0xFF48CAE4)
        : score >= 60
            ? Colors.orange
            : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        '$score',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMetricColumn(String label, int value) {
    final color = value >= 80
        ? const Color(0xFF48CAE4)
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 80, color: Colors.white),
          const SizedBox(height: 16),
          Text(
            'Connection Error',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Unable to connect to the server. Please check your network connection.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
            textAlign: TextAlign.center,
          ),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _errorMessage,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Current Server: $_currentApiUrl',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _fetchChildren,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reconnect'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF48CAE4),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _useMockData,
                        icon: const Icon(Icons.desktop_windows),
                        label: const Text('Demo Mode'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[400],
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAssignChildDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign New Client'),
        content: TextField(
          controller: _childEmailController,
          decoration: const InputDecoration(
            labelText: 'Client Email',
            hintText: 'Enter the email of the client to assign',
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
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchChildren() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('Fetching children from: $_currentApiUrl/api/therapist/children');
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
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception(
              'Connection timed out. Please check your network or server URL.');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _children = data['children'] ?? [];
          _isLoading = false;

          if (_children.isNotEmpty && _selectedChildId == null) {
            _selectedChildId = _children[0]['uid'];
            _selectedChildInfo = _children[0];
            _fetchChildProgress(_selectedChildId!);
          }
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _fetchChildProgress(String childId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('Fetching progress for child ID: $childId');
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
      ).timeout(const Duration(seconds: 15));

      print('Child progress response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Response data: $data');

        // Handle data from the child-progress endpoint
        List<dynamic> progressData = [];

        if (data['progress'] != null) {
          print('Found ${data['progress'].length} progress items');
          progressData = data['progress'];
        }

        setState(() {
          _childProgressData = progressData;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load session data: ${response.statusCode}';
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading progress data: $e';
      });
    }
  }

  Future<void> _assignChild() async {
    if (_childEmailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter client email')),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
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
          const SnackBar(content: Text('Client assigned successfully')),
        );
      } else {
        final error = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error['error'] ?? 'Failed to assign client')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Helper method to generate mock data for demonstration purposes
  void _useMockData() {
    print('Using mock data for demonstration');
    final now = DateTime.now();

    // Mock children data
    setState(() {
      _children = [
        {
          'uid': 'mock-child-1',
          'firstName': 'Vinuth',
          'lastName': 'S',
          'email': 'vinuth@example.com'
        },
        {
          'uid': 'mock-child-2',
          'firstName': 'John',
          'lastName': 'Doe',
          'email': 'john@example.com'
        }
      ];

      // Set selected child
      _selectedChildId = 'mock-child-1';
      _selectedChildInfo = _children[0];

      // Generate mock progress data
      _childProgressData = [
        {
          'id': 'mock-session-1',
          'transcript':
              'This is a mock transcript for demonstration. The backend server is currently unavailable.',
          'analysis': {
            'overallScore': 75,
            'confidenceScore': 80,
            'grammarScore': 70,
            'clarityScore': 85
          },
          'timestamp': {
            '_seconds':
                now.subtract(const Duration(days: 1)).millisecondsSinceEpoch ~/
                    1000,
            '_nanoseconds': 0
          }
        },
        {
          'id': 'mock-session-2',
          'transcript':
              'This is another mock transcript with different scores. In a real application, this would contain the actual speech content.',
          'analysis': {
            'overallScore': 82,
            'confidenceScore': 85,
            'grammarScore': 78,
            'clarityScore': 88
          },
          'timestamp': {
            '_seconds':
                now.subtract(const Duration(days: 2)).millisecondsSinceEpoch ~/
                    1000,
            '_nanoseconds': 0
          }
        },
        {
          'id': 'mock-session-3',
          'transcript':
              'Third mock transcript showing progress over time. This demonstrates how the charts would look with real data.',
          'analysis': {
            'overallScore': 90,
            'confidenceScore': 92,
            'grammarScore': 88,
            'clarityScore': 91
          },
          'timestamp': {
            '_seconds':
                now.subtract(const Duration(days: 3)).millisecondsSinceEpoch ~/
                    1000,
            '_nanoseconds': 0
          }
        }
      ];

      _isLoading = false;
      _errorMessage = '';
    });
  }
}

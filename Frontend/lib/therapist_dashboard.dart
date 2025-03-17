import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

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
  bool _isAssigningChild = false;

  @override
  void initState() {
    super.initState();
    _fetchChildren();
  }

  Future<void> _fetchChildren() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
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
        Uri.parse('http://172.20.10.7:5000/api/therapist/children'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _children = data['children'];
          _isLoading = false;

          // Auto-select the first child if available
          if (_children.isNotEmpty && _selectedChildId == null) {
            _selectedChildId = _children[0]['uid'];
            _selectedChildInfo = _children[0];
            _fetchChildProgress(_selectedChildId!);
          }
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load children: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  Future<void> _fetchChildProgress(String childId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
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
        Uri.parse(
            'http://172.20.10.7:5000/api/therapist/child-progress/$childId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _childProgressData = data['progress'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Failed to load child progress: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  Future<void> _assignChild() async {
    if (_childEmailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter child email')),
      );
      return;
    }

    setState(() {
      _isAssigningChild = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isAssigningChild = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
        return;
      }

      final token = await user.getIdToken();
      final response = await http.post(
        Uri.parse('http://172.20.10.7:5000/api/therapist/assign-child'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'childEmail': _childEmailController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        // Reset the form and refresh the children list
        _childEmailController.clear();
        _fetchChildren();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Child assigned successfully')),
        );
      } else {
        final error = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error['error'] ?? 'Failed to assign child')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isAssigningChild = false;
      });
    }
  }

  void _showAssignChildDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Assign New Child'),
          content: TextField(
            controller: _childEmailController,
            decoration: const InputDecoration(
              labelText: 'Child Email',
              hintText: 'Enter the email of the child to assign',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _assignChild();
              },
              child: const Text('Assign'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Therapist Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showAssignChildDialog,
            tooltip: 'Assign New Child',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child:
                      Text(_errorMessage, style: TextStyle(color: Colors.red)))
              : _buildDashboardContent(),
    );
  }

  Widget _buildDashboardContent() {
    if (_children.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No children assigned yet',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _showAssignChildDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('Assign Child'),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        // Left sidebar - Child selection
        Container(
          width: 250,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border(
              right: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My Clients',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _fetchChildren,
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _children.length,
                  itemBuilder: (context, index) {
                    final child = _children[index];
                    final isSelected = _selectedChildId == child['uid'];

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          '${child['firstName'][0]}${child['lastName'][0]}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor:
                            isSelected ? Colors.cyan : Colors.grey.shade300,
                        foregroundColor:
                            isSelected ? Colors.white : Colors.black87,
                      ),
                      title: Text(
                        '${child['firstName']} ${child['lastName']}',
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(child['email']),
                      selected: isSelected,
                      selectedTileColor: Colors.cyan.withOpacity(0.1),
                      onTap: () {
                        setState(() {
                          _selectedChildId = child['uid'];
                          _selectedChildInfo = child;
                        });
                        _fetchChildProgress(child['uid']);
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: _showAssignChildDialog,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Assign New Client'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Main content - Child progress data
        Expanded(
          child: _selectedChildId == null
              ? const Center(
                  child: Text('Select a child to view their progress'))
              : _buildChildProgressView(),
        ),
      ],
    );
  }

  Widget _buildChildProgressView() {
    if (_childProgressData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.line_axis_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            Text(
              'No progress data for ${_selectedChildInfo?['firstName'] ?? 'this child'} yet',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with child name
          Text(
            'Progress Dashboard: ${_selectedChildInfo?['firstName']} ${_selectedChildInfo?['lastName']}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Progress charts
          _buildProgressCharts(),

          const SizedBox(height: 32),

          // Recent sessions
          const Text(
            'Recent Speech Sessions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Session list
          Expanded(
            child: _buildSessionList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCharts() {
    if (_childProgressData.length < 2) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text('Not enough data to generate progress charts'),
        ),
      );
    }

    // Process data for charts
    final progressPoints = _childProgressData.map((session) {
      final analysis = session['analysis'];
      return {
        'timestamp': session['timestamp'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                session['timestamp']['_seconds'] * 1000)
            : DateTime.now(),
        'overallScore': analysis['overallScore'],
        'confidenceScore': analysis['confidenceScore'],
        'grammarScore': analysis['grammarScore'],
        'clarityScore': analysis['clarityScore'],
      };
    }).toList();

    // Sort by date
    progressPoints.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 &&
                      value.toInt() < progressPoints.length) {
                    final timestamp =
                        progressPoints[value.toInt()]['timestamp'];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('MM/dd').format(timestamp),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
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
            _buildLineChartBarData(progressPoints, 'overallScore', Colors.blue),
            _buildLineChartBarData(
                progressPoints, 'confidenceScore', Colors.green),
            _buildLineChartBarData(
                progressPoints, 'grammarScore', Colors.orange),
            _buildLineChartBarData(
                progressPoints, 'clarityScore', Colors.purple),
          ],
        ),
      ),
    );
  }

  LineChartBarData _buildLineChartBarData(
      List<dynamic> data, String metric, Color color) {
    final spots = <FlSpot>[];

    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i][metric].toDouble()));
    }

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
        final analysis = session['analysis'];
        final timestamp = session['timestamp'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                session['timestamp']['_seconds'] * 1000)
            : DateTime.now();
        final formattedDate =
            DateFormat('MMM d, yyyy - h:mm a').format(timestamp);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formattedDate,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    _buildScoreChip(analysis['overallScore']),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  session['transcript'] ?? 'No transcript available',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMetricColumn(
                        'Confidence', analysis['confidenceScore']),
                    _buildMetricColumn('Grammar', analysis['grammarScore']),
                    _buildMetricColumn('Clarity', analysis['clarityScore']),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScoreChip(int score) {
    Color color;
    if (score >= 80) {
      color = Colors.green;
    } else if (score >= 60) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

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
    Color color;
    if (value >= 80) {
      color = Colors.green;
    } else if (value >= 60) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
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
}

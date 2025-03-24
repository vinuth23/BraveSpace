import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class SpeechAnalysisPage extends StatefulWidget {
  const SpeechAnalysisPage({Key? key}) : super(key: key);

  @override
  State<SpeechAnalysisPage> createState() => _SpeechAnalysisPageState();
}

class _SpeechAnalysisPageState extends State<SpeechAnalysisPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _sessions = [];
  List<dynamic> _progressData = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _testBackendConnection();
    _fetchSpeechSessions();
    _fetchProgressData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _testBackendConnection() async {
    try {
      final response = await http.get(
        Uri.parse('http://172.20.10.7:5000'),
      );
      print(
          'Backend connection test: ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('Backend connection test error: $e');
    }
  }

  Future<void> _fetchSpeechSessions() async {
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
        Uri.parse('http://172.20.10.7:5000/api/speech/sessions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _sessions = data['sessions'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load sessions: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  Future<void> _fetchProgressData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final token = await user.getIdToken();
      final response = await http.get(
        Uri.parse('http://172.20.10.7:5000/api/speech/progress'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _progressData = data['progress'];
        });
      }
    } catch (e) {
      print('Error fetching progress data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speech Analysis'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sessions'),
            Tab(text: 'Progress'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSessionsTab(),
          _buildProgressTab(),
        ],
      ),
    );
  }

  Widget _buildSessionsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
          child: Text(_errorMessage, style: TextStyle(color: Colors.red)));
    }

    if (_sessions.isEmpty) {
      return const Center(child: Text('No speech sessions found'));
    }

    return ListView.builder(
      itemCount: _sessions.length,
      itemBuilder: (context, index) {
        final session = _sessions[index];
        final timestamp = session['timestamp'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                session['timestamp']['_seconds'] * 1000)
            : DateTime.now();
        final formattedDate =
            DateFormat('MMM d, yyyy - h:mm a').format(timestamp);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: InkWell(
            onTap: () => _navigateToSessionDetails(session),
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
                      _buildScoreChip(session['analysis']['overallScore']),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _truncateText(session['transcript'], 100),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMetricColumn(
                          'Confidence', session['analysis']['confidenceScore']),
                      _buildMetricColumn(
                          'Grammar', session['analysis']['grammarScore']),
                      _buildMetricColumn(
                          'Clarity', session['analysis']['clarityScore']),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressTab() {
    if (_progressData.isEmpty) {
      return const Center(child: Text('No progress data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Speaking Progress',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildProgressChart(),
          const SizedBox(height: 32),
          _buildRecentMetrics(),
        ],
      ),
    );
  }

  Widget _buildProgressChart() {
    if (_progressData.length < 2) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Not enough data to show progress chart'),
        ),
      );
    }

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
                      value.toInt() < _progressData.length) {
                    final timestamp = DateTime.fromMillisecondsSinceEpoch(
                        _progressData[value.toInt()]['timestamp']['_seconds'] *
                            1000);
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
          maxX: _progressData.length.toDouble() - 1,
          minY: 0,
          maxY: 100,
          lineBarsData: [
            _buildLineChartBarData('overallScore', Colors.blue),
            _buildLineChartBarData('confidenceScore', Colors.green),
            _buildLineChartBarData('grammarScore', Colors.orange),
            _buildLineChartBarData('clarityScore', Colors.purple),
          ],
        ),
      ),
    );
  }

  LineChartBarData _buildLineChartBarData(String metric, Color color) {
    final spots = <FlSpot>[];

    for (int i = 0; i < _progressData.length; i++) {
      spots.add(FlSpot(i.toDouble(), _progressData[i][metric].toDouble()));
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

  Widget _buildRecentMetrics() {
    if (_progressData.isEmpty) return const SizedBox.shrink();

    final latestSession = _progressData.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Latest Performance',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Overall Score',
                latestSession['overallScore'],
                Icons.star,
                Colors.amber,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Speech Rate',
                latestSession['speechRate'],
                Icons.speed,
                Colors.blue,
                suffix: 'WPM',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Confidence',
                latestSession['confidenceScore'],
                Icons.psychology,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Grammar',
                latestSession['grammarScore'],
                Icons.spellcheck,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildMetricCard(
          'Clarity',
          latestSession['clarityScore'],
          Icons.record_voice_over,
          Colors.purple,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
      String title, dynamic value, IconData icon, Color color,
      {String suffix = '', bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value is int
                ? '$value$suffix'
                : '${value.toStringAsFixed(1)}$suffix',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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

  void _navigateToSessionDetails(dynamic session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SpeechSessionDetailsPage(session: session),
      ),
    );
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}

class SpeechSessionDetailsPage extends StatelessWidget {
  final dynamic session;

  const SpeechSessionDetailsPage({Key? key, required this.session})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extract session data safely
    final analysis = session['analysis'] as Map<String, dynamic>? ?? {};
    final analysisResults =
        session['analysisResults'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      // Dramatic full-bleed colored app bar
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        title: const Text('Speech Analysis',
            style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share functionality would go here
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share feature coming soon')));
            },
          ),
        ],
      ),
      body: Container(
        // Gradient background for the entire page
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2C3E50),
              Color(0xFF1A2530),
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Date and time header
            _buildDateBanner(),

            // Large circular score visualization
            _buildScoreOverview(analysis),

            // AI Feedback section with custom design
            _buildAIFeedbackSection(context, analysis, analysisResults),

            // Speech transcript section
            _buildTranscriptSection(),

            // Detailed metrics cards
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'DETAILED METRICS',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            // Grid of metric cards
            _buildMetricsGrid(analysis),

            const SizedBox(height: 40), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildDateBanner() {
    DateTime timestamp;
    try {
      timestamp = session['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              session['timestamp']['_seconds'] * 1000)
          : DateTime.now();
    } catch (e) {
      timestamp = DateTime.now();
    }

    final formattedDate =
        DateFormat('EEE, MMMM d, yyyy • h:mm a').format(timestamp);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_today,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formattedDate,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreOverview(Map<String, dynamic> analysis) {
    final overallScore = analysis['overallScore'] as int? ?? 0;

    // Determine color based on score
    Color scoreColor;
    if (overallScore >= 80) {
      scoreColor = Colors.greenAccent;
    } else if (overallScore >= 60) {
      scoreColor = Colors.amberAccent;
    } else {
      scoreColor = Colors.redAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          // Score circle
          Container(
            height: 140,
            width: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: scoreColor.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1A2530),
                  border: Border.all(
                    color: scoreColor,
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$overallScore',
                    style: TextStyle(
                      color: scoreColor,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'OVERALL SCORE',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getScoreDescription(overallScore),
            style: TextStyle(
              color: scoreColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getScoreDescription(int score) {
    if (score >= 90) return 'EXCELLENT';
    if (score >= 80) return 'VERY GOOD';
    if (score >= 70) return 'GOOD';
    if (score >= 60) return 'FAIR';
    if (score >= 50) return 'NEEDS WORK';
    return 'NEEDS IMPROVEMENT';
  }

  Widget _buildAIFeedbackSection(BuildContext context,
      Map<String, dynamic> analysis, Map<String, dynamic> analysisResults) {
    // Try to get feedback from multiple sources
    String feedback = '';

    // First try the new format (analysisResults)
    if (analysisResults.isNotEmpty && analysisResults['feedback'] != null) {
      feedback = analysisResults['feedback'] as String;
    }
    // Then try the old format (analysis)
    else if (analysis.isNotEmpty && analysis['feedback'] != null) {
      var analysisFeedback = analysis['feedback'];
      if (analysisFeedback is String) {
        feedback = analysisFeedback;
      } else if (analysisFeedback is List && analysisFeedback.isNotEmpty) {
        feedback = '• ' + (analysisFeedback as List).join('\n• ');
      }
    }

    if (feedback.isEmpty) {
      feedback = 'No AI feedback available for this speech session.';
    }

    // Try to extract filler words
    List<dynamic> fillerWords = [];
    if (analysisResults.isNotEmpty && analysisResults['fillerWords'] != null) {
      fillerWords = analysisResults['fillerWords'] as List<dynamic>;
    }

    // Try to extract repeated words
    List<dynamic> repeatedWords = [];
    if (analysisResults.isNotEmpty &&
        analysisResults['repeatedWords'] != null) {
      repeatedWords = analysisResults['repeatedWords'] as List<dynamic>;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.purpleAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'AI Feedback',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Feedback content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Text(
              feedback,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),

          // Filler words section if available
          if (fillerWords.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FILLER WORDS',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: fillerWords.map<Widget>((filler) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.redAccent.withOpacity(0.3)),
                        ),
                        child: Text(
                          '${filler['word']} (${filler['count']})',
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          // Repeated words section if available
          if (repeatedWords.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REPEATED WORDS',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: repeatedWords.map<Widget>((repeated) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amberAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.amberAccent.withOpacity(0.3)),
                        ),
                        child: Text(
                          '${repeated['word']} (${repeated['count']})',
                          style: const TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTranscriptSection() {
    final transcript = session['transcript'] ?? 'No transcript available';

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.subject,
                    color: Colors.blueAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Transcript',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Transcript content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Text(
              transcript,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(Map<String, dynamic> analysis) {
    // Get scores with safe fallbacks
    final confidenceScore = analysis['confidenceScore'] as int? ?? 0;
    final grammarScore = analysis['grammarScore'] as int? ?? 0;
    final clarityScore = analysis['clarityScore'] as int? ?? 0;
    final speechRate = analysis['speechRate'] as int? ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.1,
        children: [
          _buildMetricCard('Confidence', confidenceScore, Icons.psychology,
              Colors.greenAccent),
          _buildMetricCard(
              'Grammar', grammarScore, Icons.spellcheck, Colors.orangeAccent),
          _buildMetricCard('Clarity', clarityScore, Icons.record_voice_over,
              Colors.purpleAccent),
          _buildMetricCard('Speed', speechRate, Icons.speed, Colors.blueAccent,
              suffix: ' WPM'),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, int value, IconData icon, Color color,
      {String suffix = ''}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$value$suffix',
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

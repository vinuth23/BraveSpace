import 'package:flutter/material.dart';
import 'services/speech_session_service.dart';
import 'package:intl/intl.dart';
import 'notifications_page.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage>
    with SingleTickerProviderStateMixin {
  final SpeechSessionService _sessionService = SpeechSessionService();
  bool _isLoading = true;
  Map<String, dynamic> _userStats = {};
  List<SpeechSession> _recentSessions = [];
  StreamSubscription<List<SpeechSession>>? _sessionsSubscription;
  bool _disposed = false;
  String? _error;

  // Speech analysis data
  List<dynamic> _speechSessions = [];
  List<dynamic> _progressData = [];
  String _speechAnalysisError = '';
  bool _speechAnalysisLoading = true;

  // Tab controller
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
    _fetchSpeechSessions();
    _fetchProgressData();
  }

  @override
  void dispose() {
    _disposed = true;
    _sessionsSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await _loadUserStats();
    if (!_disposed) {
      _sessionsSubscription = _sessionService.getUserSessions().listen(
        (sessions) {
          if (!_disposed) {
            setState(() {
              _recentSessions = sessions;
              _error = null;
            });
          }
        },
        onError: (error) {
          if (!_disposed) {
            setState(() {
              _error = 'Unable to load sessions. Please try again later.';
              _isLoading = false;
            });
            print('Error in session stream: $error');
          }
        },
      );
    }
  }

  Future<void> _loadUserStats() async {
    if (_disposed) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stats = await _sessionService.getUserStats();
      if (_disposed) return;

      setState(() {
        _userStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading stats: $e');
      if (_disposed) return;

      setState(() {
        _error = 'Unable to load statistics. Please try again later.';
        _isLoading = false;
      });
    }
  }

  // Speech analysis methods
  Future<void> _fetchSpeechSessions() async {
    setState(() {
      _speechAnalysisLoading = true;
      _speechAnalysisError = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _speechAnalysisLoading = false;
          _speechAnalysisError = 'User not logged in';
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
          _speechSessions = data['sessions'];
          _speechAnalysisLoading = false;
        });
      } else {
        setState(() {
          _speechAnalysisLoading = false;
          _speechAnalysisError =
              'Failed to load sessions: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _speechAnalysisLoading = false;
        _speechAnalysisError = 'Error: $e';
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
        title: const Text('Progress & Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Practice Sessions'),
            Tab(text: 'Speech Analysis'),
            Tab(text: 'Progress Charts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPracticeSessionsTab(),
          _buildSpeechAnalysisTab(),
          _buildProgressChartsTab(),
        ],
      ),
    );
  }

  Widget _buildPracticeSessionsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
          child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsCards(),
          const SizedBox(height: 24),
          _buildRecentSessions(),
        ],
      ),
    );
  }

  Widget _buildSpeechAnalysisTab() {
    if (_speechAnalysisLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_speechAnalysisError.isNotEmpty) {
      return Center(
          child:
              Text(_speechAnalysisError, style: TextStyle(color: Colors.red)));
    }

    if (_speechSessions.isEmpty) {
      return const Center(child: Text('No speech sessions found'));
    }

    return ListView.builder(
      itemCount: _speechSessions.length,
      itemBuilder: (context, index) {
        final session = _speechSessions[index];
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

  Widget _buildProgressChartsTab() {
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

  Widget _buildStatsCards() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total Sessions',
                  _userStats['totalSessions']?.toString() ?? '0',
                  Icons.event_note,
                ),
                _buildStatItem(
                  'Total Duration',
                  '${_userStats['totalDuration']?.toString() ?? '0'} min',
                  Icons.timer,
                ),
                _buildStatItem(
                  'Avg Score',
                  '${(_userStats['averageScore'] ?? 0).toStringAsFixed(1)}%',
                  Icons.star,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF48CAE4), size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSessions() {
    if (_recentSessions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No recent sessions found'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Sessions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _recentSessions.length > 5 ? 5 : _recentSessions.length,
          itemBuilder: (context, index) {
            final session = _recentSessions[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                title: Text(
                  session.topic,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  DateFormat('MMM d, yyyy - h:mm a').format(session.timestamp),
                ),
                trailing: Text(
                  '${_getAverageScore(session.metrics).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                onTap: () => _showSessionDetails(session),
              ),
            );
          },
        ),
      ],
    );
  }

  double _getAverageScore(Map<String, double> metrics) {
    if (metrics.isEmpty) return 0;
    final sum = metrics.values.reduce((a, b) => a + b);
    return sum / metrics.length;
  }

  void _showSessionDetails(SpeechSession session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        session.topic,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Session Date: ${DateFormat('MMM d, y').format(session.timestamp)}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  Text(
                    'Duration: ${session.duration} seconds',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Speech Content',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    session.speechText,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SpeechSessionDetailsPage extends StatelessWidget {
  final dynamic session;

  const SpeechSessionDetailsPage({Key? key, required this.session})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timestamp = session['timestamp'] != null
        ? DateTime.fromMillisecondsSinceEpoch(
            session['timestamp']['_seconds'] * 1000)
        : DateTime.now();
    final formattedDate = DateFormat('MMMM d, yyyy - h:mm a').format(timestamp);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Speech Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formattedDate,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            _buildScoreSection(),
            const SizedBox(height: 24),
            _buildTranscriptSection(),
            const SizedBox(height: 24),
            _buildFeedbackSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreSection() {
    return Container(
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
          const Text(
            'Performance Scores',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildScoreRow('Overall Score', session['analysis']['overallScore']),
          const SizedBox(height: 12),
          _buildScoreRow('Confidence', session['analysis']['confidenceScore']),
          const SizedBox(height: 12),
          _buildScoreRow('Grammar', session['analysis']['grammarScore']),
          const SizedBox(height: 12),
          _buildScoreRow('Clarity', session['analysis']['clarityScore']),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMetricItem(
                  'Speech Rate', '${session['analysis']['speechRate']} WPM'),
              const SizedBox(width: 16),
              _buildMetricItem(
                  'Filler Words', '${session['analysis']['fillerWordCount']}'),
              const SizedBox(width: 16),
              _buildMetricItem(
                  'Pauses', '${session['analysis']['pauseCount']}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String label, int score) {
    Color color;
    if (score >= 80) {
      color = Colors.green;
    } else if (score >= 60) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              '$score',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: score / 100,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptSection() {
    return Container(
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
          const Text(
            'Transcript',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            session['transcript'],
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection() {
    final feedback = session['analysis']['feedback'] as List<dynamic>;

    return Container(
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
          const Text(
            'Feedback',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...feedback.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

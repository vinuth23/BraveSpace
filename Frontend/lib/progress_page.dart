import 'package:flutter/material.dart';
import 'services/speech_session_service.dart';
import 'package:intl/intl.dart';
import 'notifications_page.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

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
  bool _usingMockProgressData = false;

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

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _speechSessions = data['sessions'] ?? [];
          _speechAnalysisLoading = false;

          // Check if we're using mock data
          if (data['mockData'] == true) {
            _speechAnalysisError =
                'Using sample data - database connection unavailable';
          }
        });
      } else if (response.statusCode == 409 &&
          data['error'] == 'Missing Firestore index') {
        // Handle missing index error
        setState(() {
          _speechSessions = data['sessions'] ?? [];
          _speechAnalysisLoading = false;

          if (data['indexUrl'] != null) {
            _speechAnalysisError =
                'Database index missing. Click here to create it: ${data['indexUrl']}';
            // Log the URL for easy access
            print('FIREBASE INDEX URL: ${data['indexUrl']}');
          } else {
            _speechAnalysisError = 'Database index missing. Using sample data.';
          }
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

      final data = json.decode(response.body);

      setState(() {
        _progressData = data['progress'] ?? [];

        // Check if we're using mock data
        if (data['mockData'] == true) {
          _usingMockProgressData = true;

          // Check if there's an index URL
          if (data['indexUrl'] != null) {
            print('FIREBASE PROGRESS INDEX URL: ${data['indexUrl']}');
          }

          // We don't need to show an error for this, just log it
          print('Using mock progress data: ${data['error']}');
        } else {
          _usingMockProgressData = false;
        }
      });
    } catch (e) {
      print('Error fetching progress data: $e');
      setState(() {
        _usingMockProgressData = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              decoration: BoxDecoration(
                color: const Color(0xFF48CAE4),
                borderRadius: const BorderRadius.only(
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
                        'Progress & Analysis',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined,
                            color: Colors.black),
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
                  ),
                ),
                // Tab Bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
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
                  child: TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF48CAE4),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: const Color(0xFF48CAE4),
                    tabs: const [
                      Tab(text: 'Practice Sessions'),
                      Tab(text: 'Speech Analysis'),
                      Tab(text: 'Progress Charts'),
                    ],
                  ),
                ),
                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPracticeSessionsTab(),
                      _buildSpeechAnalysisTab(),
                      _buildProgressChartsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
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

    if (_speechSessions.isEmpty) {
      return const Center(child: Text('No speech sessions found'));
    }

    return Column(
      children: [
        // Show warning banner if using mock data
        if (_speechAnalysisError.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: _speechAnalysisError.contains('http')
                      ? GestureDetector(
                          onTap: () {
                            final urlMatch = RegExp(r'(https?://[^\s]+)')
                                .firstMatch(_speechAnalysisError);
                            if (urlMatch != null) {
                              _launchURL(urlMatch.group(0)!);
                            }
                          },
                          child: Text(
                            _speechAnalysisError,
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        )
                      : Text(
                          _speechAnalysisError,
                          style: TextStyle(color: Colors.amber.shade900),
                        ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _speechSessions.length,
            itemBuilder: (context, index) {
              final session = _speechSessions[index];
              final timestamp = session['timestamp'] != null
                  ? DateTime.fromMillisecondsSinceEpoch(
                      session['timestamp']['_seconds'] * 1000)
                  : DateTime.now();
              final formattedDate =
                  DateFormat('MMM d, yyyy - h:mm a').format(timestamp);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () => _navigateToSessionDetails(session),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
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
                            _buildScoreChip(
                                session['analysis']['overallScore']),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _truncateText(session['transcript'], 100),
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildMetricColumn('Confidence',
                                session['analysis']['confidenceScore']),
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
          ),
        ),
      ],
    );
  }

  Widget _buildProgressChartsTab() {
    if (_progressData.isEmpty) {
      return const Center(child: Text('No progress data available'));
    }

    return Column(
      children: [
        // Show warning banner if using mock data
        if (_usingMockProgressData)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Using sample progress data - database connection unavailable',
                    style: TextStyle(color: Colors.amber.shade900),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
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
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: _buildProgressChart(),
                ),
                const SizedBox(height: 32),
                _buildRecentMetrics(),
              ],
            ),
          ),
        ),
      ],
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
        borderRadius: BorderRadius.circular(20),
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
        builder: (context) => SpeechSessionDetailsPage(
          session: session,
          displayMode: SpeechSessionDisplayMode.fullScreen,
        ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
              Icon(icon, color: const Color(0xFF48CAE4), size: 20),
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
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            'Your Statistics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Sessions',
            style: TextStyle(
              fontSize: 20,
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
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(20),
                  title: Text(
                    session.topic,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    DateFormat('MMM d, yyyy - h:mm a')
                        .format(session.timestamp),
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF48CAE4).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_getAverageScore(session.metrics).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Color(0xFF48CAE4),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  onTap: () => _showSessionDetails(session),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  double _getAverageScore(Map<String, dynamic> metrics) {
    if (metrics.isEmpty) return 0.0;

    double total = 0.0;
    int count = 0;

    metrics.forEach((key, value) {
      if (value is num) {
        total += value.toDouble();
        count++;
      }
    });

    return count > 0 ? total / count : 0.0;
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
        builder: (context, scrollController) => SpeechSessionDetails(
          session: session,
          displayMode: SpeechSessionDisplayMode.bottomSheet,
          scrollController: scrollController,
          onClose: () => Navigator.pop(context),
        ),
      ),
    );
  }

  // Helper method to get color based on metric score
  Color _getMetricColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.amber;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  // Helper method to launch URLs
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await url_launcher.launchUrl(url)) {
      print('Could not launch $url');
    }
  }
}

// Enum to define display modes for the speech session details
enum SpeechSessionDisplayMode {
  fullScreen,
  bottomSheet,
}

// Unified page for displaying speech session details
class SpeechSessionDetailsPage extends StatelessWidget {
  final dynamic session;
  final SpeechSessionDisplayMode displayMode;

  const SpeechSessionDetailsPage({
    Key? key,
    required this.session,
    this.displayMode = SpeechSessionDisplayMode.fullScreen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // For full screen mode, wrap in Scaffold with AppBar
    if (displayMode == SpeechSessionDisplayMode.fullScreen) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Speech Details'),
        ),
        body: SpeechSessionDetails(
          session: session,
          displayMode: displayMode,
        ),
      );
    } else {
      // For other modes, return the details directly
      return SpeechSessionDetails(
        session: session,
        displayMode: displayMode,
      );
    }
  }
}

// Core component that shows the session details content
class SpeechSessionDetails extends StatelessWidget {
  final dynamic session;
  final SpeechSessionDisplayMode displayMode;
  final ScrollController? scrollController;
  final VoidCallback? onClose;

  const SpeechSessionDetails({
    Key? key,
    required this.session,
    this.displayMode = SpeechSessionDisplayMode.fullScreen,
    this.scrollController,
    this.onClose,
  }) : super(key: key);

  // Helper method for color coding metric scores
  Color _getMetricColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.amber;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    // Get formatted date
    DateTime timestamp;
    try {
      if (session is Map) {
        timestamp = session['timestamp'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                session['timestamp']['_seconds'] * 1000)
            : DateTime.now();
      } else {
        // SpeechSession object
        timestamp = (session as SpeechSession).timestamp;
      }
    } catch (e) {
      timestamp = DateTime.now();
    }

    final formattedDate = DateFormat('MMMM d, yyyy - h:mm a').format(timestamp);

    // Extract data differently based on session type
    final analysis = session is Map ? (session['analysisResults'] ?? {}) : null;
    final speechText = session is Map
        ? (session['transcript'] ?? 'No transcript available')
        : (session as SpeechSession).speechText;
    final topicOrTitle =
        session is Map ? 'Speech Session' : (session as SpeechSession).topic;

    final duration = session is Map
        ? (session['duration'] ?? 0)
        : (session as SpeechSession).duration;

    // Prepare the UI based on display mode
    final contentPadding = displayMode == SpeechSessionDisplayMode.fullScreen
        ? const EdgeInsets.all(16)
        : const EdgeInsets.all(24);

    // Build the main content
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Only show close button and header for bottom sheet mode
        if (displayMode == SpeechSessionDisplayMode.bottomSheet)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                topicOrTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClose,
              ),
            ],
          ),

        // Date and duration info
        if (displayMode == SpeechSessionDisplayMode.bottomSheet) ...[
          const SizedBox(height: 16),
          Text(
            'Session Date: ${DateFormat('MMM d, y').format(timestamp)}',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          Text(
            'Duration: $duration seconds',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ] else ...[
          Text(
            formattedDate,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],

        // Different sections based on type of session
        if (session is Map) ...[
          const SizedBox(height: 16),
          _buildScoreSection(analysis),
          const SizedBox(height: 24),
          _buildTranscriptSection(context, analysis),
          const SizedBox(height: 24),
          _buildAIFeedbackSection(analysis),
          if (_hasFillerWords(analysis)) ...[
            const SizedBox(height: 24),
            _buildFillerWordsSection(analysis),
          ],
          if (_hasRepeatedWords(analysis)) ...[
            const SizedBox(height: 24),
            _buildRepeatedWordsSection(analysis),
          ],
          const SizedBox(height: 24),
          _buildDetailedAnalysisSection(analysis),
        ] else ...[
          // SpeechSession object display
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
            speechText,
            style: const TextStyle(fontSize: 16),
          ),

          // AI Feedback Section for SpeechSession object
          const SizedBox(height: 24),
          const Text(
            'AI Feedback',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildAIFeedbackSectionForSpeechSession(session as SpeechSession),
        ],
      ],
    );

    // Wrap the content based on display mode
    if (displayMode == SpeechSessionDisplayMode.bottomSheet) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: contentPadding,
            child: content,
          ),
        ),
      );
    } else {
      return SingleChildScrollView(
        padding: contentPadding,
        child: content,
      );
    }
  }

  // Helper method to build AI feedback section for SpeechSession object
  Widget _buildAIFeedbackSectionForSpeechSession(SpeechSession session) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF48CAE4).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF48CAE4).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display feedback from the session
          if (session.feedback.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: session.feedback.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 16)),
                      Expanded(
                        child: Text(
                          session.feedback[index],
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                );
              },
            )
          else
            const Text(
              'No AI feedback available for this session.',
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),

          // Show metrics section
          const SizedBox(height: 16),
          const Text(
            'Performance Metrics:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: session.metrics.entries.map<Widget>((entry) {
              final color = _getMetricColor(entry.value);
              return Chip(
                backgroundColor: color.withOpacity(0.1),
                side: BorderSide(color: color.withOpacity(0.3)),
                label: Text(
                  '${entry.key}: ${entry.value.toInt()}',
                  style: TextStyle(color: color),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  bool _hasFillerWords(Map<String, dynamic> analysis) {
    final fillerWords = analysis['fillerWords'] as List<dynamic>?;
    return fillerWords != null && fillerWords.isNotEmpty;
  }

  bool _hasRepeatedWords(Map<String, dynamic> analysis) {
    final repeatedWords = analysis['repeatedWords'] as List<dynamic>?;
    return repeatedWords != null && repeatedWords.isNotEmpty;
  }

  Widget _buildScoreSection(Map<String, dynamic> analysis) {
    final overallScore = analysis['overallScore'] ?? 0;
    final confidenceScore = analysis['confidenceScore'] ?? 0;

    // Extract speech stats if available
    final speechStats = analysis['speechStats'] as Map<String, dynamic>? ?? {};
    final wordCount = speechStats['wordCount'] ?? 0;
    final sentenceCount = speechStats['sentenceCount'] ?? 0;
    final avgWordsPerSentence = speechStats['avgWordsPerSentence'] ?? 0.0;
    final fillerWordPercentage = speechStats['fillerWordPercentage'] ?? 0.0;

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
          _buildScoreRow('Overall Score', overallScore),
          const SizedBox(height: 12),
          _buildScoreRow('Confidence', confidenceScore),
          const SizedBox(height: 16),

          // Speech statistics section
          const Text(
            'Speech Statistics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildMetricItem('Word Count', '$wordCount'),
          const SizedBox(height: 8),
          _buildMetricItem('Sentence Count', '$sentenceCount'),
          const SizedBox(height: 8),
          _buildMetricItem('Avg. Words per Sentence',
              '${avgWordsPerSentence.toStringAsFixed(1)}'),
          const SizedBox(height: 8),
          _buildMetricItem(
              'Filler Word %', '${fillerWordPercentage.toStringAsFixed(1)}%'),
        ],
      ),
    );
  }

  Widget _buildTranscriptSection(
      BuildContext context, Map<String, dynamic> analysis) {
    final transcript = analysis['transcript'] ??
        (session is Map ? session['transcript'] : null) ??
        'No transcript available';
    final fillerWords = analysis['fillerWords'] as List<dynamic>? ?? [];

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
          _buildHighlightedTranscript(transcript, fillerWords, context),
        ],
      ),
    );
  }

  Widget _buildHighlightedTranscript(
      String transcript, List<dynamic> fillerWords, BuildContext context) {
    // If no filler words, just return the plain transcript
    if (fillerWords.isEmpty) {
      return Text(
        transcript,
        style: const TextStyle(
          fontSize: 16,
          height: 1.5,
        ),
      );
    }

    // Extract just the words from the filler words list
    final fillerWordsList =
        fillerWords.map((fw) => fw['word'].toString().toLowerCase()).toList();

    // Split the transcript into words while preserving spacing and punctuation
    final pattern = RegExp(r'(\s+|[.,!?;:()-])|(\b\w+\b)');
    final matches = pattern.allMatches(transcript);

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black),
        children: matches.map((match) {
          final word = match.group(0) ?? '';
          final isFillerWord = fillerWordsList.contains(word.toLowerCase());

          return TextSpan(
            text: word,
            style: isFillerWord
                ? const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    backgroundColor: Color(0x33FF0000),
                  )
                : null,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAIFeedbackSection(Map<String, dynamic> analysis) {
    final feedback = analysis['feedback'] ?? 'No feedback available';

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
            'AI Feedback',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            feedback,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFillerWordsSection(Map<String, dynamic> analysis) {
    final fillerWords = analysis['fillerWords'] as List<dynamic>? ?? [];

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
            'Filler Words',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: fillerWords.map<Widget>((filler) {
              return Chip(
                backgroundColor: Colors.red.withOpacity(0.1),
                label: Text('${filler['word']} (${filler['count']})'),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRepeatedWordsSection(Map<String, dynamic> analysis) {
    final repeatedWords = analysis['repeatedWords'] as List<dynamic>? ?? [];

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
            'Repeated Words',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: repeatedWords.map<Widget>((repeated) {
              return Chip(
                backgroundColor: Colors.amber.withOpacity(0.1),
                label: Text('${repeated['word']} (${repeated['count']})'),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedAnalysisSection(Map<String, dynamic> analysis) {
    final detailedAnalysis =
        analysis['detailedAnalysis'] as List<dynamic>? ?? [];

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
            'Detailed Analysis',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...detailedAnalysis.map((item) => _buildAnalysisItem(item)).toList(),
        ],
      ),
    );
  }

  Widget _buildAnalysisItem(Map<String, dynamic> item) {
    final category = item['category'] ?? 'Unknown';
    final score = (item['score'] as num?)?.toDouble() ?? 0.0;
    final feedback = item['feedback'] ?? 'No details available';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
              ),
              Text(
                '${score.toInt()}/100',
                style: TextStyle(
                  color: _getScoreColor(score),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              color: _getScoreColor(score),
              backgroundColor: Colors.grey.withOpacity(0.2),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            feedback,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.amber;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  Widget _buildScoreRow(String label, int score) {
    Color color = _getScoreColor(score.toDouble());

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
          color: color,
          backgroundColor: Colors.grey.withOpacity(0.2),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

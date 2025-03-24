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
  late TabController _tabController;
  bool _isLoading = true;
  bool _speechAnalysisLoading = true;
  String? _error;
  List<Map<String, dynamic>> _speechSessions = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, dynamic> _userStats = {
    'totalSessions': 0,
    'totalDuration': 0,
    'averageScore': 0,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _error = 'User not logged in';
        });
        return;
      }

      await _loadSpeechSessions();
      await _loadUserStats();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _speechAnalysisLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _speechAnalysisLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _loadSpeechSessions() async {
    try {
      final sessions = await _sessionService.getSessions();
      if (mounted) {
        setState(() {
          _speechSessions =
              sessions.map((session) => session.toJson()).toList();
        });
      }
    } catch (e) {
      print('Error getting sessions from server: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load sessions: $e';
        });
      }
    }
  }

  Future<void> _loadUserStats() async {
    try {
      final stats = await _sessionService.getUserStats();
      if (mounted) {
        setState(() {
          _userStats = stats;
        });
      }
    } catch (e) {
      print('Error loading user stats: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                      IconButton(
                        icon: const Icon(Icons.menu, color: Colors.black),
                        onPressed: () {},
                      ),
                      const Text(
                        'Progress',
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
                // Stats Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn(
                          'Sessions', _userStats['totalSessions'].toString()),
                      _buildStatColumn(
                          'Minutes',
                          (_userStats['totalDuration'] / 60)
                              .round()
                              .toString()),
                      _buildStatColumn(
                          'Avg Score', '${_userStats['averageScore'].round()}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Tab Bar and Tab Views
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
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
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            labelColor: const Color(0xFF48CAE4),
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: const Color(0xFF48CAE4),
                            tabs: const [
                              Tab(text: 'Speech Analysis'),
                              Tab(text: 'Progress Charts'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildSpeechAnalysisTab(),
                              _buildProgressChartsTab(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeechAnalysisTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF48CAE4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_speechSessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic_none, size: 80, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'No speech sessions yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete a speech session to see your progress',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to speech test page
                Navigator.of(context).pushNamed('/test_speech');
              },
              icon: const Icon(Icons.mic),
              label: const Text('Try a Speech Session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF48CAE4),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _speechSessions.length,
      itemBuilder: (context, index) {
        final session = _speechSessions[index];

        DateTime timestamp;
        try {
          if (session['timestamp'] is Map) {
            timestamp = DateTime.fromMillisecondsSinceEpoch(
                session['timestamp']['_seconds'] * 1000);
          } else {
            timestamp =
                DateTime.fromMillisecondsSinceEpoch(session['timestamp']);
          }
        } catch (e) {
          timestamp = DateTime.now();
          print('Error parsing timestamp: $e');
        }

        final dateFormatted = DateFormat('MMM d, yyyy').format(timestamp);
        final timeFormatted = DateFormat('h:mm a').format(timestamp);

        final metrics = session['metrics'] ?? {};
        final topic = session['topic'] ?? 'Untitled';
        final speechText = session['speechText'] ?? '';
        final overallScore = metrics['overallScore']?.toInt() ?? 0;

        // Get score color for visual cue
        Color scoreColor;
        if (overallScore >= 80) {
          scoreColor = Colors.green;
        } else if (overallScore >= 60) {
          scoreColor = Colors.amber;
        } else if (overallScore >= 40) {
          scoreColor = Colors.orange;
        } else {
          scoreColor = Colors.red;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with score chip
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topic,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$dateFormatted at $timeFormatted',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: scoreColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: scoreColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$overallScore',
                            style: TextStyle(
                              color: scoreColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.star, color: scoreColor, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Speech preview
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  speechText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
              ),

              // Metrics pills
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Speech Metrics',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: metrics.entries.map<Widget>((entry) {
                        if (entry.key == 'overallScore')
                          return const SizedBox.shrink();

                        final color = _getMetricColor(entry.value is num
                            ? (entry.value as num).toDouble()
                            : 0);
                        final label =
                            '${entry.key.replaceAll('Score', '')}: ${entry.value is num ? entry.value.toInt() : 0}';

                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: color.withOpacity(0.5)),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // View details button
              InkWell(
                onTap: () => _navigateToSessionDetails(session),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF48CAE4).withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'View Details',
                      style: TextStyle(
                        color: Color(0xFF48CAE4),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressChartsTab() {
    if (_speechAnalysisLoading) {
      return const Center(
          child: CircularProgressIndicator(
        color: Color(0xFF48CAE4),
      ));
    }

    if (_speechSessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart,
                size: 80, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'No speech data available yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete speech sessions to see your progress here',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to speech test page
                Navigator.of(context).pushNamed('/test_speech');
              },
              icon: const Icon(Icons.mic),
              label: const Text('Try a Speech Session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF48CAE4),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Process data for charts
    final List<FlSpot> overallScoreSpots = [];
    final List<FlSpot> confidenceSpots = [];
    final List<FlSpot> claritySpots = [];
    final List<String> dates = [];

    // Process real session data
    List<Map<String, dynamic>> chartData = [];

    // Extract and format the data from _speechSessions
    chartData = _speechSessions.map<Map<String, dynamic>>((session) {
      DateTime date;
      try {
        // Try to extract timestamp from the session data
        if (session['timestamp'] is Map) {
          date = DateTime.fromMillisecondsSinceEpoch(
              session['timestamp']['_seconds'] * 1000);
        } else {
          date = DateTime.fromMillisecondsSinceEpoch(session['timestamp']);
        }
      } catch (e) {
        date = DateTime.now();
        print('Error parsing date: $e');
      }

      // Extract metrics from the session
      final metrics = session['metrics'] ?? {};

      return {
        'date': date,
        'overallScore': metrics['overallScore'] ?? 0,
        'confidenceScore': metrics['confidenceScore'] ?? 0,
        'clarityScore': metrics['clarityScore'] ?? 0,
        'fluencyScore': metrics['fluencyScore'] ?? 0,
      };
    }).toList();

    // Sort data by date
    chartData.sort(
        (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    // Process chart data
    for (var i = 0; i < chartData.length; i++) {
      overallScoreSpots.add(FlSpot(
          i.toDouble(), (chartData[i]['overallScore'] as num).toDouble()));
      confidenceSpots.add(FlSpot(
          i.toDouble(), (chartData[i]['confidenceScore'] as num).toDouble()));
      claritySpots.add(FlSpot(
          i.toDouble(), (chartData[i]['clarityScore'] as num).toDouble()));
      dates.add(DateFormat('MM/dd').format(chartData[i]['date'] as DateTime));
    }

    // Calculate improvement metrics
    final startOverallScore = chartData.isNotEmpty
        ? (chartData.first['overallScore'] as num).toDouble()
        : 0;
    final latestOverallScore = chartData.isNotEmpty
        ? (chartData.last['overallScore'] as num).toDouble()
        : 0;
    final improvement = startOverallScore > 0
        ? ((latestOverallScore - startOverallScore) / startOverallScore) * 100
        : 0;

    // Average scores calculation
    final avgOverallScore = chartData.isEmpty
        ? 0.0
        : chartData
                .map((item) => item['overallScore'] as num)
                .reduce((a, b) => a + b) /
            chartData.length;
    final avgConfidence = chartData.isEmpty
        ? 0.0
        : chartData
                .map((item) => item['confidenceScore'] as num)
                .reduce((a, b) => a + b) /
            chartData.length;
    final avgClarity = chartData.isEmpty
        ? 0.0
        : chartData
                .map((item) => item['clarityScore'] as num)
                .reduce((a, b) => a + b) /
            chartData.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Summary Card
          Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Speech Progress Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStyledProgressMetric('Overall',
                        avgOverallScore.round(), Colors.blue, Icons.star),
                    _buildStyledProgressMetric(
                        'Growth',
                        improvement.round(),
                        improvement >= 0 ? Colors.green : Colors.red,
                        improvement >= 0
                            ? Icons.trending_up
                            : Icons.trending_down),
                    _buildStyledProgressMetric('Sessions', chartData.length,
                        const Color(0xFF48CAE4), Icons.mic),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Overall Score Line Chart
          Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timeline, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Overall Speech Score Trend',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        drawHorizontalLine: true,
                        horizontalInterval: 20,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withOpacity(0.2),
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withOpacity(0.2),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 &&
                                  value.toInt() < dates.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    dates[value.toInt()],
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: const Color(0xFFDDDDDD))),
                      minX: 0,
                      maxX: (overallScoreSpots.length - 1).toDouble(),
                      minY: 0,
                      maxY: 100,
                      lineBarsData: [
                        LineChartBarData(
                          spots: overallScoreSpots,
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.blue.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Metrics Comparison Chart
          Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bar_chart,
                        color: Color(0xFF48CAE4), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Speech Metrics Comparison',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        drawHorizontalLine: true,
                        horizontalInterval: 20,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withOpacity(0.2),
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withOpacity(0.2),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 &&
                                  value.toInt() < dates.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    dates[value.toInt()],
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: const Color(0xFFDDDDDD))),
                      minX: 0,
                      maxX: (overallScoreSpots.length - 1).toDouble(),
                      minY: 0,
                      maxY: 100,
                      lineBarsData: [
                        LineChartBarData(
                          spots: confidenceSpots,
                          isCurved: true,
                          color: Colors.green,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: true),
                        ),
                        LineChartBarData(
                          spots: claritySpots,
                          isCurved: true,
                          color: Colors.orange,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Chart Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStyledChartLegend('Confidence', Colors.green),
                    const SizedBox(width: 24),
                    _buildStyledChartLegend('Clarity', Colors.orange),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Detailed Metrics Card
          Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.equalizer, color: Colors.purple, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Average Speech Metrics',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildStyledMetricProgressBar(
                    'Overall Score', avgOverallScore, Colors.blue),
                const SizedBox(height: 16),
                _buildStyledMetricProgressBar(
                    'Confidence', avgConfidence, Colors.green),
                const SizedBox(height: 16),
                _buildStyledMetricProgressBar(
                    'Clarity', avgClarity, Colors.orange),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyledProgressMetric(
      String label, int value, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label == 'Growth' ? '${value > 0 ? '+' : ''}$value%' : '$value',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStyledChartLegend(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              )),
        ],
      ),
    );
  }

  Widget _buildStyledMetricProgressBar(
      String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${value.toInt()}/100',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            Container(
              height: 10,
              width: MediaQuery.of(context).size.width * 0.8 * (value / 100),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ],
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

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF48CAE4),
          ),
        ),
      ],
    );
  }

  Color _getMetricColor(dynamic scoreValue) {
    // Safely convert the input to a double
    double score = 0.0;

    if (scoreValue is num) {
      score = scoreValue.toDouble();
    } else if (scoreValue is String) {
      score = double.tryParse(scoreValue) ?? 0.0;
    } else if (scoreValue is Map) {
      // If a Map was passed instead of a numeric value, use default
      score = 0.0;
      print('Warning: Received Map instead of number for metric color');
    }

    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.amber;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  void _navigateToSessionDetails(dynamic session) {
    // Convert session Map<dynamic, dynamic> to Map<String, dynamic> if needed
    final Map<String, dynamic> processedSession;

    if (session is Map) {
      // Convert the Map<dynamic, dynamic> to Map<String, dynamic>
      processedSession = Map<String, dynamic>.from(session.map(
        (key, value) => MapEntry(key.toString(), value),
      ));
    } else {
      // For SpeechSession objects or other types
      processedSession = session;
    }

    // Extract metrics instead of analysis
    final metrics = processedSession['metrics'] as Map<String, dynamic>? ?? {};
    print('METRICS: $metrics');
    print('METRICS KEYS: ${metrics.keys.toList()}');
    print('OVERALL SCORE: ${metrics['overallScore']}');
    print('CONFIDENCE SCORE: ${metrics['confidenceScore']}');

    final speechText =
        processedSession['speechText'] as String? ?? 'No speech text available';
    final topic = processedSession['topic'] as String? ?? 'Untitled Speech';
    final duration = processedSession['duration'] as int? ?? 0;
    final feedback = processedSession['feedback'] ?? [];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SpeechSessionDetailsPage(
          session: processedSession,
          displayMode: SpeechSessionDisplayMode.fullScreen,
        ),
      ),
    );
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

  // Helper method for color coding metric scores
  Color _getMetricColor(dynamic scoreValue) {
    // Safely convert the input to a double
    double score = 0.0;

    if (scoreValue is num) {
      score = scoreValue.toDouble();
    } else if (scoreValue is String) {
      score = double.tryParse(scoreValue) ?? 0.0;
    } else if (scoreValue is Map) {
      // If a Map was passed instead of a numeric value, use default
      score = 0.0;
      print('Warning: Received Map instead of number for metric color');
    }

    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.amber;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    // Process session if it's a Map to ensure correct types
    Map<String, dynamic> processedSession;
    if (session is Map) {
      // Convert any Map<dynamic, dynamic> to Map<String, dynamic>
      processedSession = _convertToStringMap(session as Map);
      // Add debug logging
      print('SESSION DATA (Map): ${json.encode(processedSession)}');
    } else {
      // If it's a SpeechSession, convert it to a Map<String, dynamic>
      processedSession = (session as SpeechSession).toJson();
      // Add debug logging
      print('SESSION DATA (SpeechSession): ${json.encode(processedSession)}');
    }

    // Parse timestamp
    DateTime sessionDate;
    try {
      if (processedSession.containsKey('timestamp')) {
        var timestamp = processedSession['timestamp'];
        if (timestamp is Map) {
          // Handle case where timestamp is a Firebase Timestamp
          if (timestamp.containsKey('seconds')) {
            int seconds = (timestamp['seconds'] as num).toInt();
            sessionDate = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
          } else {
            sessionDate = DateTime.now();
          }
        } else if (timestamp is String) {
          sessionDate = DateTime.parse(timestamp);
        } else {
          sessionDate = DateTime.now();
        }
      } else {
        sessionDate = DateTime.now();
      }
    } catch (e) {
      print('Error parsing timestamp: $e');
      sessionDate = DateTime.now();
    }

    // Extract metrics instead of analysis
    final metrics = processedSession['metrics'] as Map<String, dynamic>? ?? {};
    print('METRICS: $metrics');
    print('METRICS KEYS: ${metrics.keys.toList()}');
    print('OVERALL SCORE: ${metrics['overallScore']}');
    print('CONFIDENCE SCORE: ${metrics['confidenceScore']}');

    final speechText =
        processedSession['speechText'] as String? ?? 'No speech text available';
    final topic = processedSession['topic'] as String? ?? 'Untitled Speech';
    final duration = processedSession['duration'] as int? ?? 0;
    final feedback = processedSession['feedback'] ?? [];

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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      const Text(
                        'Session Details',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.share_outlined,
                            color: Colors.black),
                        onPressed: () {
                          // Share functionality could be added here
                        },
                      ),
                    ],
                  ),
                ),
                // Session Header Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                topic,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getMetricColor(metrics['overallScore'])
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color:
                                      _getMetricColor(metrics['overallScore'])
                                          .withOpacity(0.5),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${metrics['overallScore'] ?? 0}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _getMetricColor(
                                          metrics['overallScore']),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.star,
                                    size: 16,
                                    color: _getMetricColor(
                                        metrics['overallScore']),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('MMM d, yyyy • h:mm a')
                                  .format(sessionDate),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.timer,
                                size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              'Duration: ${(duration / 60).floor()}:${(duration % 60).toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Score section
                        _buildScoreSection(metrics),
                        const SizedBox(height: 16),

                        // AI Feedback section
                        _buildAIFeedbackSection(feedback),
                        const SizedBox(height: 16),

                        // Transcript section
                        _buildTranscriptSection(context, speechText, []),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreSection(Map<String, dynamic> metrics) {
    final overallScore = metrics['overallScore'] ?? 0;
    final confidenceScore = metrics['confidenceScore'] ?? 0;
    final fluencyScore = metrics['fluencyScore'] ?? 0;
    final clarityScore = metrics['clarityScore'] ?? 0;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.grey[800], size: 20),
              const SizedBox(width: 8),
              Text(
                'Performance Scores',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildScoreRow('Overall Score', overallScore, Colors.blue),
          const SizedBox(height: 12),
          _buildScoreRow('Confidence', confidenceScore, Colors.green),
          const SizedBox(height: 12),
          _buildScoreRow('Fluency', fluencyScore, Colors.purple),
          const SizedBox(height: 12),
          _buildScoreRow('Clarity', clarityScore, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildTranscriptSection(
      BuildContext context, String transcript, List<dynamic> fillerWords) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.text_fields, color: Colors.grey[800], size: 20),
              const SizedBox(width: 8),
              Text(
                'Transcript',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
            ),
            child: Text(
              transcript,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIFeedbackSection(dynamic feedback) {
    String feedbackText = '';

    if (feedback is List) {
      feedbackText = (feedback as List).join('\n\n');
    } else if (feedback is String) {
      feedbackText = feedback;
    } else {
      feedbackText = 'No feedback available';
    }

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.grey[800], size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Feedback',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF48CAE4).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF48CAE4).withOpacity(0.2),
              ),
            ),
            child: Column(
              children: feedbackText.split('\n\n').map((feedback) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Icon(
                          Icons.check_circle,
                          size: 16,
                          color: const Color(0xFF48CAE4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feedback,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String label, dynamic scoreValue, Color baseColor) {
    // More robust conversion of dynamic score to double
    double score = 0.0;

    // Handle different types that might come from the server
    if (scoreValue is num) {
      score = scoreValue.toDouble();
    } else if (scoreValue is String) {
      score = double.tryParse(scoreValue) ?? 0.0;
    } else if (scoreValue is Map) {
      // If a Map was passed instead of a numeric value, use default
      score = 0.0;
      print('Warning: Received Map instead of number for $label score');
    }

    final scoreInt = score.toInt();
    Color color = _getMetricColor(score);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: baseColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$scoreInt/100',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: baseColor,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            Container(
              height: 10,
              width: (score / 100) *
                  100 *
                  3, // Adjust width based on available space
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper to convert any Map<dynamic, dynamic> to Map<String, dynamic>
  Map<String, dynamic> _convertToStringMap(Map map) {
    return map.map((key, value) {
      // Convert nested maps recursively
      if (value is Map) {
        return MapEntry(key.toString(), _convertToStringMap(value));
      }
      // Convert lists of maps
      else if (value is List) {
        return MapEntry(key.toString(), _convertListItems(value));
      }
      // Regular values
      else {
        return MapEntry(key.toString(), value);
      }
    });
  }

  // Helper to convert list items that might contain maps
  List _convertListItems(List items) {
    return items.map((item) {
      if (item is Map) {
        return _convertToStringMap(item);
      }
      return item;
    }).toList();
  }
}

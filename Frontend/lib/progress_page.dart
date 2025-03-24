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
    _tabController = TabController(length: 2, vsync: this);
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

      // Debug output
      print('Response data: $data');

      if (data['sessions'] != null && data['sessions'] is List) {
        print('Number of sessions: ${data['sessions'].length}');

        // Debug each session's structure
        for (var i = 0; i < data['sessions'].length; i++) {
          final session = data['sessions'][i];
          print('Session $i: ${session.runtimeType}');

          if (session['analysis'] != null) {
            final analysis = session['analysis'];
            print('  Analysis type: ${analysis.runtimeType}');

            // Check score types
            if (analysis['overallScore'] != null) {
              print(
                  '  overallScore: ${analysis['overallScore']} (${analysis['overallScore'].runtimeType})');
            }

            if (analysis['confidenceScore'] != null) {
              print(
                  '  confidenceScore: ${analysis['confidenceScore']} (${analysis['confidenceScore'].runtimeType})');
            }

            if (analysis['grammarScore'] != null) {
              print(
                  '  grammarScore: ${analysis['grammarScore']} (${analysis['grammarScore'].runtimeType})');
            }

            if (analysis['clarityScore'] != null) {
              print(
                  '  clarityScore: ${analysis['clarityScore']} (${analysis['clarityScore'].runtimeType})');
            }

            // Check speechStats
            if (analysis['speechStats'] != null) {
              print(
                  '  speechStats type: ${analysis['speechStats'].runtimeType}');

              final speechStats = analysis['speechStats'];
              if (speechStats['wordCount'] != null) {
                print(
                    '    wordCount: ${speechStats['wordCount']} (${speechStats['wordCount'].runtimeType})');
              }
            }
          }
        }
      }

      if (response.statusCode == 200) {
        try {
          // Process sessions to ensure proper type handling
          final sessions =
              (data['sessions'] as List<dynamic>? ?? []).map((session) {
            // Ensure proper type for nested metrics
            if (session != null &&
                session is Map &&
                session['analysis'] is Map) {
              final analysis = session['analysis'] as Map<String, dynamic>;

              // Safely convert all score values to integers
              if (analysis.containsKey('overallScore') &&
                  !(analysis['overallScore'] is num)) {
                print(
                    'Converting overallScore from ${analysis['overallScore'].runtimeType} to int');
                analysis['overallScore'] = 0;
              }
              if (analysis.containsKey('confidenceScore') &&
                  !(analysis['confidenceScore'] is num)) {
                print(
                    'Converting confidenceScore from ${analysis['confidenceScore'].runtimeType} to int');
                analysis['confidenceScore'] = 0;
              }
              if (analysis.containsKey('grammarScore') &&
                  !(analysis['grammarScore'] is num)) {
                print(
                    'Converting grammarScore from ${analysis['grammarScore'].runtimeType} to int');
                analysis['grammarScore'] = 0;
              }
              if (analysis.containsKey('clarityScore') &&
                  !(analysis['clarityScore'] is num)) {
                print(
                    'Converting clarityScore from ${analysis['clarityScore'].runtimeType} to int');
                analysis['clarityScore'] = 0;
              }

              // Handle speech stats if they exist
              if (analysis.containsKey('speechStats') &&
                  analysis['speechStats'] is Map) {
                final speechStats =
                    analysis['speechStats'] as Map<String, dynamic>;

                // Ensure word count is an integer
                if (speechStats.containsKey('wordCount') &&
                    !(speechStats['wordCount'] is num)) {
                  print(
                      'Converting wordCount from ${speechStats['wordCount'].runtimeType} to int');
                  speechStats['wordCount'] = 0;
                }

                // Ensure sentence count is an integer
                if (speechStats.containsKey('sentenceCount') &&
                    !(speechStats['sentenceCount'] is num)) {
                  print(
                      'Converting sentenceCount from ${speechStats['sentenceCount'].runtimeType} to int');
                  speechStats['sentenceCount'] = 0;
                }
              }
            }
            return session;
          }).toList();

          setState(() {
            _speechSessions = sessions;
            _speechAnalysisLoading = false;

            // Check if we're using mock data
            if (data['mockData'] == true) {
              _speechAnalysisError =
                  'Using sample data - database connection unavailable';
            }
          });
        } catch (e) {
          print('Error processing speech sessions: $e');
          setState(() {
            _speechAnalysisLoading = false;
            _speechAnalysisError = 'Error processing speech data: $e';
          });
        }
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

      print('Progress data response: $data');

      List<dynamic> processedProgressData = [];
      if (data['progress'] != null && data['progress'] is List) {
        print('Number of progress entries: ${data['progress'].length}');

        try {
          // Process the progress data to ensure proper types
          processedProgressData = data['progress'].map((entry) {
            // Debug each entry
            print('Processing progress entry: $entry');

            if (entry is Map<String, dynamic>) {
              // Sanitize numeric fields to ensure they're all properly typed
              final sanitizedEntry = Map<String, dynamic>.from(entry);

              // Make sure all score fields are numeric
              _ensureNumericField(sanitizedEntry, 'overallScore');
              _ensureNumericField(sanitizedEntry, 'confidenceScore');
              _ensureNumericField(sanitizedEntry, 'grammarScore');
              _ensureNumericField(sanitizedEntry, 'clarityScore');
              _ensureNumericField(sanitizedEntry, 'speechRate');

              return sanitizedEntry;
            }
            return entry;
          }).toList();
        } catch (e) {
          print('Error processing progress data: $e');
          // Use empty list if processing fails
          processedProgressData = [];
        }
      }

      setState(() {
        _progressData = processedProgressData;

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

  // Helper method to ensure a field in a map is numeric
  void _ensureNumericField(Map<String, dynamic> map, String key) {
    if (!map.containsKey(key)) {
      map[key] = 0;
      return;
    }

    final value = map[key];
    if (value is num) {
      // Already numeric, no change needed
      return;
    }

    if (value is String) {
      // Try to convert string to number
      final numericValue = double.tryParse(value);
      map[key] = numericValue ?? 0;
      return;
    }

    if (value is Map) {
      print('Warning: Found Map where a number was expected for $key: $value');
      map[key] = 0;
      return;
    }

    // For any other type, set to 0
    print('Warning: Unexpected type ${value.runtimeType} for $key');
    map[key] = 0;
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

  Widget _buildSpeechAnalysisTab() {
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

  Widget _buildProgressChartsTab() {
    if (_speechAnalysisLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Create a user-friendly message if no data is available
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
        date = session['timestamp'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                session['timestamp']['_seconds'] * 1000)
            : DateTime.now();
      } catch (e) {
        date = DateTime.now();
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
                    _buildProgressMetric(
                        'Overall Score', avgOverallScore.round(), Colors.blue),
                    _buildProgressMetric('Improvement', improvement.round(),
                        improvement >= 0 ? Colors.green : Colors.red),
                    _buildProgressMetric(
                        'Sessions', chartData.length, Colors.purple),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

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
                Text(
                  'Overall Speech Score Trend',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(fontSize: 10),
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
                                    style: const TextStyle(fontSize: 10),
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

          const SizedBox(height: 24),

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
                Text(
                  'Speech Metrics Comparison',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(fontSize: 10),
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
                                    style: const TextStyle(fontSize: 10),
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
                    _buildChartLegend('Confidence', Colors.green),
                    const SizedBox(width: 24),
                    _buildChartLegend('Clarity', Colors.orange),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

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
                Text(
                  'Average Speech Metrics',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                _buildMetricProgressBar(
                    'Overall Score', avgOverallScore, Colors.blue),
                const SizedBox(height: 12),
                _buildMetricProgressBar(
                    'Confidence', avgConfidence, Colors.green),
                const SizedBox(height: 12),
                _buildMetricProgressBar('Clarity', avgClarity, Colors.orange),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressMetric(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label == 'Improvement' ? '${value > 0 ? '+' : ''}$value%' : '$value',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildChartLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
      ],
    );
  }

  Widget _buildMetricProgressBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey[700]),
            ),
            Text(
              '${value.toInt()}/100',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value / 100,
            backgroundColor: Colors.grey.withOpacity(0.2),
            color: color,
            minHeight: 10,
          ),
        ),
      ],
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

  // Helper method to launch URLs
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await url_launcher.launchUrl(url)) {
      print('Could not launch $url');
    }
  }

  // Helper method to safely extract score values
  int _getScoreValueSafely(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;

    // Handle Map case that's causing the error
    if (value is Map) {
      print('Warning: Received Map instead of int for score: $value');
      return 0;
    }

    print('Warning: Unknown type for score: ${value.runtimeType}');
    return 0;
  }

  // Helper method to display an error card when a session can't be rendered
  Widget _buildErrorSessionCard(String errorMessage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Text(
        errorMessage,
        style: const TextStyle(color: Colors.red),
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
              final color = _getMetricColor(
                  entry.value is num ? entry.value.toDouble() : 0.0);
              return Chip(
                backgroundColor: color.withOpacity(0.1),
                side: BorderSide(color: color.withOpacity(0.3)),
                label: Text(
                  '${entry.key}: ${entry.value is num ? (entry.value is int ? entry.value : entry.value.toInt()) : 0}',
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

  Widget _buildScoreRow(String label, dynamic scoreValue) {
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
    Color color = _getScoreColor(score);

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
              '$scoreInt',
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

import 'package:flutter/material.dart';
import 'notifications_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _userName = '';
  List<Challenge> _challenges = [];
  List<Session> _upcomingSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    try {
      setState(() => _isLoading = true);

      // Get user data
      final user = _auth.currentUser;
      print('👤 Current user: ${user?.uid}');

      if (user != null) {
        // Add a small delay to ensure Firestore writes are complete
        await Future.delayed(const Duration(seconds: 1));

        final userData =
            await _firestore.collection('users').doc(user.uid).get();
        print('📝 User data: ${userData.data()}');
        final firstName = userData.data()?['firstName'] ?? '';

        // Get challenges without date filter
        print('🎯 Fetching challenges...');
        final challengesSnapshot = await _firestore
            .collection('challenges')
            .where('userId', isEqualTo: user.uid)
            .get();

        print('📊 Found ${challengesSnapshot.docs.length} challenges');
        if (challengesSnapshot.docs.isEmpty) {
          print('❌ No challenges found for user');
        } else {
          for (var doc in challengesSnapshot.docs) {
            print('📋 Challenge data: ${doc.data()}');
          }
        }

        // Get upcoming sessions
        print('📅 Fetching sessions...');
        final sessionsSnapshot = await _firestore
            .collection('sessions')
            .where('userId', isEqualTo: user.uid)
            .get(); // Remove time filter temporarily

        print('🗓 Found ${sessionsSnapshot.docs.length} sessions');
        if (sessionsSnapshot.docs.isEmpty) {
          print('❌ No sessions found for user');
        } else {
          for (var doc in sessionsSnapshot.docs) {
            print('📋 Session data: ${doc.data()}');
          }
        }

        final challenges = challengesSnapshot.docs
            .map((doc) => Challenge.fromFirestore(doc))
            .toList();

        final sessions = sessionsSnapshot.docs
            .map((doc) => Session.fromFirestore(doc))
            .toList();

        if (mounted) {
          setState(() {
            _userName = firstName;
            _challenges = challenges;
            _upcomingSessions = sessions;
            _isLoading = false;
          });
        }
        print('✅ Data loaded successfully');
        print('📊 Loaded ${_challenges.length} challenges');
        print('📅 Loaded ${_upcomingSessions.length} sessions');
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: Stack(
        children: [
          // Curved background - increased height
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 350, // Increased from 200 to 350 to extend further down
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
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: RefreshIndicator(
                onRefresh: loadUserData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 40,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with greeting
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, $_userName 👋',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const NotificationsPage()),
                                );
                              },
                              icon: const Icon(Icons.notifications_outlined),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.all(12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Search Bar
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Search',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),

                        // Daily Challenges Section
                        Text(
                          'Daily Challenges',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: _challenges.map((challenge) {
                            return Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: _ChallengeCard(
                                  title: challenge.title,
                                  subtitle:
                                      '${challenge.current} of ${challenge.target}',
                                  onTap: () {},
                                  color: challenge.type == 'VR_SESSIONS'
                                      ? Colors.black
                                      : Colors.white,
                                  textColor: challenge.type == 'VR_SESSIONS'
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        // Upcoming Sessions Section
                        const SizedBox(height: 25),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Upcoming Sessions',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            TextButton(
                              onPressed: () {
                                final mainNavigator =
                                    context.findAncestorStateOfType<
                                        MainNavigatorState>();
                                if (mainNavigator != null) {
                                  mainNavigator.onItemTapped(2);
                                }
                              },
                              child: const Row(
                                children: [
                                  Text('See all'),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_ios, size: 14),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        ..._upcomingSessions
                            .map((session) => Padding(
                                  padding: const EdgeInsets.only(bottom: 15),
                                  child: _SessionCard(
                                    title: session.title,
                                    duration: session.duration,
                                    time: session.formattedTime,
                                    onTap: () {},
                                    color: const Color(0xFF48CAE4),
                                  ),
                                ))
                            ,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;
  final Color? textColor;

  const _ChallengeCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color = Colors.black,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  subtitle,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                  ),
                ),
                Icon(
                  Icons.play_circle_fill,
                  color: textColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final String title;
  final String duration;
  final String time;
  final VoidCallback onTap;
  final Color? color;

  const _SessionCard({
    required this.title,
    required this.duration,
    required this.time,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(duration),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(time),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.play_circle_fill,
              color: Colors.black,
              size: 40,
            ),
          ],
        ),
      ),
    );
  }
}

class Challenge {
  final String id;
  final String type;
  final String title;
  final int current;
  final int target;

  Challenge({
    required this.id,
    required this.type,
    required this.title,
    required this.current,
    required this.target,
  });

  factory Challenge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Challenge(
      id: doc.id,
      type: data['type'] ?? '',
      title: data['title'] ?? '',
      current: data['current'] ?? 0,
      target: data['target'] ?? 0,
    );
  }
}

class Session {
  final String id;
  final String title;
  final String duration;
  final DateTime startTime;

  Session({
    required this.id,
    required this.title,
    required this.duration,
    required this.startTime,
  });

  String get formattedTime {
    final hour = startTime.hour;
    final period = hour < 12 ? 'am' : 'pm';
    final adjustedHour = hour > 12 ? hour - 12 : hour;
    return '$adjustedHour$period';
  }

  factory Session.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Session(
      id: doc.id,
      title: data['title'] ?? '',
      duration: data['duration'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
    );
  }
}

extension DateTimeExtension on DateTime {
  DateTime get startOfDay => DateTime(year, month, day);
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);
}

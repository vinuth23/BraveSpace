import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _loadLeaderboardData();
  }

  Future<void> _loadLeaderboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user ID
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        _currentUserId = currentUser.uid;
      }

      // Fetch all users with child role - using get() without where clause to get all users
      final usersSnapshot = await _firestore.collection('users').get();

      // Transform to list and add score and ranks
      final List<Map<String, dynamic>> usersList = [];

      for (var doc in usersSnapshot.docs) {
        final userData = doc.data();
        final userRole = userData['role'] ?? 'child';

        // Only include users with child role
        if (userRole == 'child') {
          // Calculate score based on completed sessions and achievements
          int score = 0;

          // Get completed VR sessions (if available)
          try {
            final sessionsSnapshot = await _firestore
                .collection('users')
                .doc(doc.id)
                .collection('vrSessions')
                .where('completed', isEqualTo: true)
                .get();

            score += sessionsSnapshot.docs.length *
                10; // 10 points per completed session
          } catch (e) {
            // Ignore errors if VR sessions collection doesn't exist
            print('Error getting VR sessions: $e');
          }

          // Get achievements (if available)
          try {
            final achievementsSnapshot = await _firestore
                .collection('users')
                .doc(doc.id)
                .collection('achievements')
                .get();

            score += achievementsSnapshot.docs.length *
                20; // 20 points per achievement
          } catch (e) {
            // Ignore errors if achievements collection doesn't exist
            print('Error getting achievements: $e');
          }

          // Get speech sessions (if available)
          try {
            final speechSessionsSnapshot = await _firestore
                .collection('users')
                .doc(doc.id)
                .collection('speechSessions')
                .get();

            score += speechSessionsSnapshot.docs.length *
                15; // 15 points per speech session
          } catch (e) {
            // Ignore errors if speech sessions collection doesn't exist
            print('Error getting speech sessions: $e');
          }

          // Use base score if nothing found
          if (score == 0) {
            score = userData['score'] ?? 0;
          }

          usersList.add({
            'id': doc.id,
            'firstName': userData['firstName'] ?? 'User',
            'lastName': userData['lastName'] ?? '',
            'profileImage': userData['profileImage'],
            'score': score,
            'isCurrentUser': doc.id == _currentUserId,
          });
        }
      }

      print('Found ${usersList.length} child users');

      // Sort by score (highest first)
      usersList
          .sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

      // Add rank
      for (int i = 0; i < usersList.length; i++) {
        usersList[i]['rank'] = i + 1;
      }

      setState(() {
        _users = usersList;
        _isLoading = false;
      });
    } catch (error) {
      print('Error loading leaderboard: $error');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error loading leaderboard: ${error.toString()}')),
      );
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
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Leaderboard',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.black),
                        onPressed: _loadLeaderboardData,
                      ),
                    ],
                  ),
                ),

                // The rest of the content
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _users.isEmpty
                          ? const Center(
                              child: Text(
                                'No users found',
                                style: TextStyle(fontSize: 18),
                              ),
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  // Top performers section
                                  if (_users.isNotEmpty)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.shade200,
                                            blurRadius: 10,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          const Text(
                                            'Top Performers',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 24),

                                          // Top 3 users
                                          _users.length >= 3
                                              ? Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceEvenly,
                                                  children: [
                                                    // 2nd place
                                                    _users.length > 1
                                                        ? _buildTopUserWidget(
                                                            _users[1], 2)
                                                        : const SizedBox(),

                                                    // 1st place (bigger)
                                                    _buildTopUserWidget(
                                                        _users[0], 1,
                                                        isBigger: true),

                                                    // 3rd place
                                                    _users.length > 2
                                                        ? _buildTopUserWidget(
                                                            _users[2], 3)
                                                        : const SizedBox(),
                                                  ],
                                                )
                                              : _buildTopUserWidget(
                                                  _users[0], 1,
                                                  isBigger: true),
                                        ],
                                      ),
                                    ),

                                  const SizedBox(height: 24),

                                  // Rankings section
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.shade200,
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'All Rankings',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 16),

                                        // Rankings list
                                        ListView.separated(
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          shrinkWrap: true,
                                          itemCount: _users.length,
                                          separatorBuilder: (context, index) =>
                                              const Divider(height: 1),
                                          itemBuilder: (context, index) {
                                            final user = _users[index];
                                            return _buildUserListItem(user);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
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

  Widget _buildTopUserWidget(Map<String, dynamic> user, int position,
      {bool isBigger = false}) {
    final double size = isBigger ? 100 : 80;
    final Color backgroundColor = position == 1
        ? const Color(0xFFFFD700) // Gold
        : position == 2
            ? const Color(0xFFC0C0C0) // Silver
            : const Color(0xFFCD7F32); // Bronze

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: backgroundColor.withOpacity(0.3),
                shape: BoxShape.circle,
                border: Border.all(
                  color: backgroundColor,
                  width: 3,
                ),
              ),
            ),
            CircleAvatar(
              radius: size * 0.4,
              backgroundColor: Colors.cyan.shade200,
              child: Text(
                user['firstName'].isNotEmpty ? user['firstName'][0] : 'U',
                style: TextStyle(
                  fontSize: isBigger ? 28 : 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: isBigger ? 20 : 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          user['firstName'],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isBigger ? 16 : 14,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: backgroundColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${user['score']} pts',
            style: TextStyle(
              color: position == 1
                  ? Colors.orange.shade800
                  : position == 2
                      ? Colors.blueGrey.shade700
                      : Colors.brown.shade700,
              fontWeight: FontWeight.bold,
              fontSize: isBigger ? 14 : 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserListItem(Map<String, dynamic> user) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: user['isCurrentUser'] ? Colors.cyan.shade50 : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Rank circle
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _getRankColor(user['rank']).withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: _getRankColor(user['rank']),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                '${user['rank']}',
                style: TextStyle(
                  color: _getRankColor(user['rank']),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // User avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.cyan.shade200,
            child: Text(
              user['firstName'].isNotEmpty ? user['firstName'][0] : 'U',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // User details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user['firstName']} ${user['lastName'].isNotEmpty ? user['lastName'][0] + '.' : ''}',
                  style: TextStyle(
                    fontWeight: user['isCurrentUser']
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 16,
                  ),
                ),
                if (user['isCurrentUser'])
                  const Text(
                    'You',
                    style: TextStyle(
                      color: Colors.cyan,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),

          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _getRankColor(user['rank']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${user['score']}',
              style: TextStyle(
                color: _getRankColor(user['rank']),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700); // Gold
    if (rank == 2) return const Color(0xFFC0C0C0); // Silver
    if (rank == 3) return const Color(0xFFCD7F32); // Bronze
    return Colors.cyan; // Default
  }
}

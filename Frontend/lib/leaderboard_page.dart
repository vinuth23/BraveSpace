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

      // Fetch all users with child role
      final usersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'child')
          .get();

      // Transform to list and add score and ranks
      final List<Map<String, dynamic>> usersList = [];

      for (var doc in usersSnapshot.docs) {
        final userData = doc.data();

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
      backgroundColor: Colors.cyan.shade50,
      appBar: AppBar(
        backgroundColor: Colors.cyan.shade100,
        elevation: 0,
        title: const Text(
          'Leaderboard',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(
                  child: Text(
                    'No users found',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      color: Colors.cyan.shade100,
                      child: Column(
                        children: [
                          const Text(
                            'Top Performers',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Top 3 users
                          _users.length >= 3
                              ? Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    // 2nd place
                                    _users.length > 1
                                        ? _buildTopUserWidget(_users[1], 2)
                                        : const SizedBox(),

                                    // 1st place (bigger)
                                    _buildTopUserWidget(_users[0], 1,
                                        isBigger: true),

                                    // 3rd place
                                    _users.length > 2
                                        ? _buildTopUserWidget(_users[2], 3)
                                        : const SizedBox(),
                                  ],
                                )
                              : _buildTopUserWidget(_users[0], 1,
                                  isBigger: true),
                        ],
                      ),
                    ),

                    // Rest of the users
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 12),
                        itemCount: _users.length > 3 ? _users.length - 3 : 0,
                        itemBuilder: (context, index) {
                          final user = _users[index + 3];
                          return _buildUserListItem(user);
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.cyan,
        child: const Icon(Icons.refresh),
        onPressed: _loadLeaderboardData,
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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events,
                  color: backgroundColor,
                  size: isBigger ? 40 : 30,
                ),
                Text(
                  '${user['score']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isBigger ? 18 : 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            user['firstName'],
            style: TextStyle(
              fontWeight:
                  user['isCurrentUser'] ? FontWeight.bold : FontWeight.normal,
              color:
                  user['isCurrentUser'] ? Colors.cyan.shade700 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserListItem(Map<String, dynamic> user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: user['isCurrentUser'] ? Colors.cyan.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.cyan.shade50,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${user['rank']}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          '${user['firstName']} ${user['lastName'].isNotEmpty ? user['lastName'][0] + '.' : ''}',
          style: TextStyle(
            fontWeight:
                user['isCurrentUser'] ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 20),
            const SizedBox(width: 4),
            Text(
              '${user['score']}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

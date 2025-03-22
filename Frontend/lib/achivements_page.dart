import 'package:flutter/material.dart';

class AchivementsPage extends StatelessWidget {
  const AchivementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'SF Pro Display',
      ),
      home: const AchievementsScreen(),
    );
  }
}

class Achievement {
  final String title;
  final String description;
  final int points;
  final IconData icon;
  final bool isUnlocked;

  Achievement({
    required this.title,
    required this.description,
    required this.points,
    required this.icon,
    required this.isUnlocked,
  });
}

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  int totalPoints = 250;
  bool hasNotifications = true;
  
  // List of achievements
  final List<Achievement> achievements = [
    // Unlocked achievements
    Achievement(
      title: 'First Social Step',
      description: 'Complete your first social scenario',
      points: 50,
      icon: Icons.check_circle,
      isUnlocked: true,
    ),
    Achievement(
      title: 'Unlock Champion',
      description: 'Successfully participate in classroom scenario',
      points: 100,
      icon: Icons.emoji_events,
      isUnlocked: true,
    ),
    Achievement(
      title: 'Master Presenter',
      description: 'Deliver a speech with minimal hesitation or filler words (e.g., "um," "uh")',
      points: 100,
      icon: Icons.emoji_events,
      isUnlocked: true,
    ),

     // Locked achievements
    Achievement(
      title: 'Playground Pro',
      description: 'Complete playground interaction scenario',
      points: 150,
      icon: Icons.lock,
      isUnlocked: false,
    ),
    Achievement(
      title: 'Lunch Buddy',
      description: 'Navigate a school canteen social interaction',
      points: 175,
      icon: Icons.lock,
      isUnlocked: false,
    ),
    Achievement(
      title: 'Lunch Buddy',
      description: 'Navigate a school canteen social interaction',
      points: 175,
      icon: Icons.lock,
      isUnlocked: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Filter achievements by unlocked status
    final unlockedAchievements = achievements.where((a) => a.isUnlocked).toList();
    final lockedAchievements = achievements.where((a) => !a.isUnlocked).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Status bar area
          Container(
            padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 8),
          ),

           // App header with back button and title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 24),
                  onPressed: () {
                    // Handle back button press
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Back button pressed'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const Text(
                  'Achievements',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Unlocked achievements section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Unlocked Achievements',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFA07A), // Light salmon color
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Total Points: $totalPoints',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Unlocked achievement cards
                  ...unlockedAchievements.map((achievement) => 
                    _buildAchievementCard(achievement)
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Locked achievements section
                  const Text(
                    'Locked Achievements',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Locked achievement cards
                  ...lockedAchievements.map((achievement) => 
                    _buildAchievementCard(achievement)
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

           // Bottom navigation bar
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.home_outlined),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Home button pressed'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notifications button pressed'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.camera_alt,
                      color: Colors.black,
                      size: 28,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Camera button pressed'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Timer button pressed'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.person_outline),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile button pressed'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF90CAF9).withOpacity(0.5), // Light blue color
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              achievement.icon,
              size: 28,
              color: achievement.isUnlocked ? Colors.black : Colors.black54,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: achievement.isUnlocked ? Colors.black : Colors.black54,
                    ),
                  ),
                  Text(
                    achievement.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: achievement.isUnlocked ? Colors.black87 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: achievement.isUnlocked 
                    ? const Color(0xFFFF7F50) // Coral color for unlocked
                    : const Color(0xFFFF7F50).withOpacity(0.7), // Faded coral for locked
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${achievement.points} pts',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: achievement.isUnlocked ? Colors.black : Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}








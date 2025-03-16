import 'package:flutter/material.dart';

class AchivementsPage extends StatelessWidget {
  const AchivementsPage({Key? key}) : super(key: key);

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
  const AchievementsScreen({Key? key}) : super(key: key);

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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '10:48',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.signal_cellular_alt, size: 16),
                    const SizedBox(width: 4),
                    const Icon(Icons.wifi, size: 16),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '31',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
                  ).toList(),
                  
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
                  ).toList(),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),







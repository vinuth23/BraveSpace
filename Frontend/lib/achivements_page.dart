import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';

class AchivementsPage extends StatelessWidget {
  const AchivementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AchievementsScreen();
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
      description:
          'Deliver a speech with minimal hesitation or filler words (e.g., "um," "uh")',
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
    final unlockedAchievements =
        achievements.where((a) => a.isUnlocked).toList();
    final lockedAchievements =
        achievements.where((a) => !a.isUnlocked).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: Column(
        children: [
          // Status bar area
          Container(
            color: const Color(0xFF5ECCE9),
            padding:
                const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 8),
          ),

          // App header with back button and title
          Container(
            color: const Color(0xFF5ECCE9),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  'Achievements',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    // Navigate to notifications
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),

          // Curved header
          Container(
            height: 50,
            decoration: const BoxDecoration(
              color: Color(0xFF5ECCE9),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),

          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5ECCE9), // Match app color
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
                  ...unlockedAchievements
                      .map((achievement) => _buildAchievementCard(achievement)),

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
                  ...lockedAchievements
                      .map((achievement) => _buildAchievementCard(achievement)),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(Icons.home_outlined, 0),
            _buildNavItem(Icons.notifications_outlined, 1),
            _buildCenterVRButton(),
            _buildNavItem(Icons.schedule_outlined, 3),
            _buildNavItem(Icons.person_outline, 4),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF5ECCE9).withOpacity(0.2), // Match app color
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
                      color: achievement.isUnlocked
                          ? Colors.black
                          : Colors.black54,
                    ),
                  ),
                  Text(
                    achievement.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: achievement.isUnlocked
                          ? Colors.black87
                          : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: achievement.isUnlocked
                    ? const Color(0xFF5ECCE9) // Match app color
                    : const Color(0xFF5ECCE9)
                        .withOpacity(0.5), // Faded for locked
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

  // Helper methods for bottom navigation bar
  Widget _buildNavItem(IconData icon, int index) {
    return IconButton(
      icon: Icon(
        icon,
        color: Colors.grey,
        size: 24,
      ),
      onPressed: () {
        // Pop back to the main navigator
        Navigator.pop(context);
      },
    );
  }

  Widget _buildCenterVRButton() {
    return GestureDetector(
      onTap: () {
        // Pop back to the main navigator
        Navigator.pop(context);
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Image.asset(
            'assets/icons/vr_headset_icon.png',
            width: 20,
            height: 20,
          ),
        ),
      ),
    );
  }
}

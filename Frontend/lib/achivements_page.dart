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

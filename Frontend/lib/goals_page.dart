import 'package:flutter/material.dart';

void main() {
  runApp(BraveSpaceGoalsPage());
}

class BraveSpaceGoalsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GoalsPage(),
    );
  }
}
class Goal {
  String title;
  String description;
  int progress;
  int total;
  IconData icon;
  Color iconColor;

  Goal({
    required this.title,
    required this.description,
    required this.progress,
    required this.total,
    required this.icon,
    required this.iconColor,
  });
}

class GoalsPage extends StatefulWidget {
  @override
  _GoalsPageState createState() => _GoalsPageState();
}
class _GoalsPageState extends State<GoalsPage> {
  List<Goal> goals = [
    Goal(
      title: "Weekly Social Challenge",
      description: "Complete 2 different social interaction scenarios",
      progress: 1,
      total: 2,
      icon: Icons.track_changes,
      iconColor: Colors.blue,
    ),
    Goal(
      title: "Emotional Explorer",
      description: "Correctly identify emotions in 2 scenarios",
      progress: 1,
      total: 2,
      icon: Icons.star,
      iconColor: Colors.purple,
    ),
    Goal(
      title: "Conversation Confidence",
      description: "Practice conversations in 3 different scenarios",
      progress: 2,
      total: 3,
      icon: Icons.chat_bubble_outline,
      iconColor: Colors.green,
    ),
  ];
    void _updateGoal(int index) {
    setState(() {
      goals[index].progress = (goals[index].progress + 1).clamp(0, goals[index].total);
    });
  }

  void _deleteGoal(int index) {
    setState(() {
      goals.removeAt(index);
    });
  }

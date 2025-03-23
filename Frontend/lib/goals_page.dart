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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'My Goals',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: goals.length,
                itemBuilder: (context, index) {
                  Goal goal = goals[index];
                  return _buildGoalCard(index, goal);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildGoalCard(int index, Goal goal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: goal.iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(goal.icon, color: goal.iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      goal.description,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
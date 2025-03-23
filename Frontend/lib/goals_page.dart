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

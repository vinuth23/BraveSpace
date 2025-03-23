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

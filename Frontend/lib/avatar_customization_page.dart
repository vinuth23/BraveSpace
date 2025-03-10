import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const AvatarApp());
}

class AvatarApp extends StatelessWidget {
  const AvatarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AvatarCustomizationScreen(),
    );
  }
}

class AvatarCustomizationScreen extends StatefulWidget {
  @override
  _AvatarCustomizationScreenState createState() => _AvatarCustomizationScreenState();
}

class _AvatarCustomizationScreenState extends State<AvatarCustomizationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Color selectedSkinTone = Colors.bisque;
  String selectedHair = "assets/hair1.png";
  String selectedOutfit = "assets/outfit1.png";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAvatarPreferences();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

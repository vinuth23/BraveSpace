import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'SF Pro Display',
      ),
      home: const AvatarCreatorScreen(),
    );
  }
}

class AvatarCreatorScreen extends StatefulWidget {
  const AvatarCreatorScreen({Key? key}) : super(key: key);

  @override
  State<AvatarCreatorScreen> createState() => _AvatarCreatorScreenState();
}

class _AvatarCreatorScreenState extends State<AvatarCreatorScreen> {
  // Selected category
  String selectedCategory = 'Basic';
  
  // Avatar properties
  Color selectedSkinTone = const Color(0xFFEAC393); // Default middle skin tone
  int selectedFaceIndex = 0;
  
  // Original values for reset functionality
  late Color originalSkinTone;
  late int originalFaceIndex;
  
  // List of categories
  final List<Map<String, dynamic>> categories = [
    {'name': 'Basic', 'icon': Icons.person},
    {'name': 'Hair', 'icon': Icons.face},
    {'name': 'Outfit', 'icon': Icons.checkroom},
    {'name': 'Extras', 'icon': Icons.auto_awesome},
  ];

  // Skin tone options
  final List<Color> skinTones = [
    const Color(0xFFF8E5C9), // Lightest
    const Color(0xFFFFDCB5), // Light
    const Color(0xFFEAC393), // Medium
    const Color(0xFFBF8A63), // Dark
    const Color(0xFF7D5339), // Darkest
  ];
  
  // Face expressions
  final List<String> faceExpressions = [
    '( ͡° ͜ʖ ͡°)', // Normal
    '(≧▽≦)', // Smiling
    '(♥ω♥ )', // Love eyes
    '(¬_¬)', // Side-eye
  ];

  @override
  void initState() {
    super.initState();
    // Initialize original values
    originalSkinTone = selectedSkinTone;
    originalFaceIndex = selectedFaceIndex;
  }

  void resetChanges() {
    setState(() {
      selectedSkinTone = originalSkinTone;
      selectedFaceIndex = originalFaceIndex;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Changes reset!')),
    );
  }

  void saveAvatar() {
    // Save current values as original
    originalSkinTone = selectedSkinTone;
    originalFaceIndex = selectedFaceIndex;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Avatar saved successfully!')),
    );
  }
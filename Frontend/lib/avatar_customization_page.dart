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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Status bar area
          Container(
            color: const Color(0xFF5ECCE9),
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

          // App header with menu and back button
          Container(
            color: const Color(0xFF5ECCE9),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {},
                ),
                const Text(
                  'Create Your Avatar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () {},
                ),
              ],
            ),
          ),
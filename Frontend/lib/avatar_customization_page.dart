import 'package:flutter/material.dart';

class AvatarCustomizationPage extends StatelessWidget {
  const AvatarCustomizationPage({super.key});

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
  const AvatarCreatorScreen({super.key});

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

          // Avatar preview area
          Container(
            height: 200,
            decoration: const BoxDecoration(
              color: Color(0xFF5ECCE9),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(200),
                bottomRight: Radius.circular(200),
              ),
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Avatar face background
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: selectedSkinTone,
                      shape: BoxShape.circle,
                    ),
                  ),
                  
                  // Hair (simplified)
                  Positioned(
                    top: 0,
                    child: Container(
                      width: 120,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(60),
                          topRight: Radius.circular(60),
                        ),
                      ),
                    ),
                  ),
                  
                  // Face expression
                  Text(
                    faceExpressions[selectedFaceIndex],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Category tabs
          SizedBox(
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: categories.map((category) {
                bool isSelected = selectedCategory == category['name'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = category['name'];
                    });
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        category['icon'],
                        color: isSelected ? Colors.black : Colors.grey,
                        size: 28,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category['name'],
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.grey,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (isSelected)
                        Container(
                          height: 2,
                          width: 40,
                          color: Colors.black,
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Customization options based on selected category
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (selectedCategory == 'Basic') ...[
                    // Skin tone section
                    const Text(
                      'Skin Tone',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: skinTones.map((color) {
                        bool isSelected = selectedSkinTone == color;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedSkinTone = color;
                            });
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: Colors.blue, width: 3)
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 24),

                    // Face expressions section
                    const Text(
                      'Face',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        faceExpressions.length,
                        (index) {
                          bool isSelected = selectedFaceIndex == index;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedFaceIndex = index;
                              });
                            },
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                border: isSelected
                                    ? Border.all(color: Colors.blue, width: 2)
                                    : Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  faceExpressions[index],
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  
                  if (selectedCategory == 'Hair') ...[
                    const Center(
                      child: Text(
                        'Hair styles coming soon!',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                  
                  if (selectedCategory == 'Outfit') ...[
                    const Center(
                      child: Text(
                        'Outfit options coming soon!',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                  
                  if (selectedCategory == 'Extras') ...[
                    const Center(
                      child: Text(
                        'Extra accessories coming soon!',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: saveAvatar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5ECCE9),
                          foregroundColor: Colors.black,
                          minimumSize: const Size(150, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'Save Avatar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: resetChanges,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          minimumSize: const Size(150, 50),
                          side: const BorderSide(color: Colors.black),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'Reset Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom navigation bar
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Icon(Icons.home_outlined),
                const Icon(Icons.notifications_outlined),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.black,
                    size: 28,
                  ),
                ),
                const Icon(Icons.access_time),
                const Icon(Icons.person_outline),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
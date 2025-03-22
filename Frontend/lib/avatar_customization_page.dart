import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import 'notifications_page.dart';

class AvatarCustomizationPage extends StatelessWidget {
  const AvatarCustomizationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AvatarCreatorScreen();
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
  Color selectedSkinTone =
      const Color(0xFFEAC393); // Default to Medium skin tone
  int selectedFaceIndex = 0;
  int selectedHeadIndex = 0; // Default to Head 1

  // Original values for reset functionality
  late Color originalSkinTone;
  late int originalFaceIndex;
  late int originalHeadIndex;

  // List of categories
  final List<Map<String, dynamic>> categories = [
    {'name': 'Basic', 'icon': Icons.person},
    {'name': 'Hair', 'icon': Icons.face},
    {'name': 'Outfit', 'icon': Icons.checkroom},
    {'name': 'Extras', 'icon': Icons.auto_awesome},
  ];

  // Skin tone options
  final List<Color> skinTones = [
    const Color(0xFFFFDCB5), // Light
    const Color(0xFFEAC393), // Medium
    const Color(0xFFBF8A63), // Dark
    const Color(0xFF7D5339), // Darkest
  ];

  // Face expressions
  final List<String> faceExpressions = [
    'assets/images/normal.png', // Normal
    'assets/images/smiling.png', // Smiling
    'assets/images/love_eyes.png', // Love eyes
    'assets/images/close_eye.png', // Close-eye
  ];

  // Head preview images
  final List<String> headPreviews = [
    'assets/images/head1.png',
    'assets/images/head2.png',
    'assets/images/head3.png',
    'assets/images/head4.png',
  ];

  // Mapping for head images with corresponding skin tone versions
  final Map<int, Map<Color, String>> headImagesBySkinTone = {
    0: {
      const Color(0xFFFFDCB5): 'assets/images/head1_light.png',
      const Color(0xFFEAC393): 'assets/images/head1_medium.png',
      const Color(0xFFBF8A63): 'assets/images/head1_dark.png',
      const Color(0xFF7D5339): 'assets/images/head1_darkest.png',
    },
    1: {
      const Color(0xFFFFDCB5): 'assets/images/head2_light.png',
      const Color(0xFFEAC393): 'assets/images/head2_medium.png',
      const Color(0xFFBF8A63): 'assets/images/head2_dark.png',
      const Color(0xFF7D5339): 'assets/images/head2_darkest.png',
    },
    2: {
      const Color(0xFFFFDCB5): 'assets/images/head3_light.png',
      const Color(0xFFEAC393): 'assets/images/head3_medium.png',
      const Color(0xFFBF8A63): 'assets/images/head3_dark.png',
      const Color(0xFF7D5339): 'assets/images/head3_darkest.png',
    },
    3: {
      const Color(0xFFFFDCB5): 'assets/images/head4_light.png',
      const Color(0xFFEAC393): 'assets/images/head4_medium.png',
      const Color(0xFFBF8A63): 'assets/images/head4_dark.png',
      const Color(0xFF7D5339): 'assets/images/head4_darkest.png',
    },
  };

  @override
  void initState() {
    super.initState();
    // Initialize original values
    originalSkinTone = selectedSkinTone; // Default to Medium skin tone
    originalFaceIndex = selectedFaceIndex;
    originalHeadIndex = selectedHeadIndex; // Default to Head 1
  }

  void resetChanges() {
    setState(() {
      selectedSkinTone = originalSkinTone;
      selectedFaceIndex = originalFaceIndex;
      selectedHeadIndex = originalHeadIndex;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Changes reset!')),
    );
  }

  void saveAvatar() {
    // Save current values as original
    originalSkinTone = selectedSkinTone;
    originalFaceIndex = selectedFaceIndex;
    originalHeadIndex = selectedHeadIndex;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Avatar saved successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
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

          // App header with back button and notification button
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
                  'Create Your Avatar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsPage(),
                      ),
                    );
                  },
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
                  // Head preview based on selected skin tone and head index
                  Image.asset(
                    headImagesBySkinTone[selectedHeadIndex]
                            ?[selectedSkinTone] ??
                        'assets/images/head_default.png', // Fallback image
                    width: 120,
                    height: 120,
                  ),

                  // Face expression
                  Positioned(
                    top:
                        40, // Adjust this value to move the face expression down
                    child: Image.asset(
                      faceExpressions[selectedFaceIndex],
                      width: 60,
                      height: 60,
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
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
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
                                child: Image.asset(
                                  faceExpressions[index],
                                  width: 40,
                                  height: 40,
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

                  const SizedBox(height: 1),

                  // Add the TextButton here for navigation
                  TextButton(
                    onPressed: () {
                      final mainNavigator =
                          context.findAncestorStateOfType<MainNavigatorState>();
                      if (mainNavigator != null) {
                        mainNavigator.onItemTapped(2);
                        Navigator.pop(context);
                      }
                    },
                    child: const Row(
                      children: [
                        Text('See all'),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios, size: 14),
                      ],
                    ),
                  ),

                  // Head section
                  const Text(
                    'Head',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: headPreviews.length,
                      itemBuilder: (context, index) {
                        bool isSelected = selectedHeadIndex == index;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedHeadIndex = index;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              border: isSelected
                                  ? Border.all(color: Colors.blue, width: 3)
                                  : Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Image.asset(
                              headPreviews[index],
                              width: 80,
                              height: 80,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

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

  // Helper methods for bottom navigation bar
  Widget _buildNavItem(IconData icon, int index) {
    return IconButton(
      icon: Icon(
        icon,
        color: Colors.grey,
        size: 24,
      ),
      onPressed: () {
        Navigator.pop(context);
        Future.delayed(const Duration(milliseconds: 100), () {
          final mainNavigator =
              context.findAncestorStateOfType<MainNavigatorState>();
          if (mainNavigator != null) {
            mainNavigator.onItemTapped(index);
          }
        });
      },
    );
  }

  Widget _buildCenterVRButton() {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        Future.delayed(const Duration(milliseconds: 100), () {
          final mainNavigator =
              context.findAncestorStateOfType<MainNavigatorState>();
          if (mainNavigator != null) {
            mainNavigator.onItemTapped(2);
          }
        });
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

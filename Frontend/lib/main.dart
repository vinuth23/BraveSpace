import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home_page.dart';
import 'notifications_page.dart';
import 'vr_sessions_page.dart';
import 'profile_page.dart';
import 'login_page.dart';
import 'forgot_password_page.dart';
import 'progress_page.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'test_speech_page.dart';
import 'speech_analysis_page.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'dart:io' show Platform;
import 'therapist_dashboard.dart';

export 'main.dart' show MainNavigatorState;

// Function to launch Unity application
Future<void> launchUnity() async {
  // On Android, we have multiple approaches to try
  if (Platform.isAndroid) {
    // First try using android_intent_plus for direct launch
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.MAIN',
        package: 'com.DefaultCompany.classroomtest',
        componentName: 'com.unity3d.player.UnityPlayerActivity',
      );
      await intent.launch();
      return; // Successfully launched
    } catch (e) {
      print('Error launching Unity with AndroidIntent: $e');
      // Fall through to try other methods
    }

    // Try with full activity path
    try {
      final bool launched = await launchUrl(
        Uri.parse(
            "android-app://com.DefaultCompany.classroomtest/com.unity3d.player.UnityPlayerActivity"),
        mode: LaunchMode.externalApplication,
      );
      if (launched) {
        return; // Successfully launched
      }
    } catch (e) {
      print('Error launching Unity by activity: $e');
      // Fall through to try other methods
    }

    // Try with package name directly
    try {
      final bool launched = await launchUrl(
        Uri.parse("android-app://com.DefaultCompany.classroomtest"),
        mode: LaunchMode.externalApplication,
      );
      if (launched) {
        return; // Successfully launched
      }
    } catch (e) {
      print('Error launching Unity by package name: $e');
      // Fall through to try other methods
    }

    // Try with standard deep link
    try {
      final bool launched = await launchUrl(
        Uri.parse("unityapp://open"),
        mode: LaunchMode.externalApplication,
      );
      if (launched) {
        return; // Successfully launched
      }
    } catch (e) {
      print('Error launching Unity with deep link: $e');
      // Fall through to try other methods
    }

    // Try with alternative deep link scheme
    try {
      final bool launched = await launchUrl(
        Uri.parse("bravespace://vr/launch"),
        mode: LaunchMode.externalApplication,
      );
      if (launched) {
        return; // Successfully launched
      }
    } catch (e) {
      print('Error launching Unity with alternative deep link: $e');
      // Fall through to try other methods
    }
  } else {
    // For iOS or other platforms, just try the deep link
    try {
      final bool launched = await launchUrl(
        Uri.parse("unityapp://open"),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw Exception('Failed to launch Unity app');
      }
    } catch (e) {
      print('Error launching Unity: $e');
      rethrow;
    }
  }

  // If all else fails, throw an exception
  throw Exception(
      'Could not launch Unity app. Make sure it is installed and correctly configured.');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase before running the app.

  // Initialize the app
  runApp(const MyApp());
}

// commit check

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes if needed
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BraveSpace',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.cyan.shade50,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            // User is logged in, check their role
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(snapshot.data!.uid)
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (userSnapshot.hasData && userSnapshot.data != null) {
                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>?;
                  final userRole = userData?['role'] as String? ?? 'child';

                  // Navigate based on user role
                  if (userRole == 'therapist' || userRole == 'parent') {
                    return const TherapistDashboardPage();
                  } else {
                    // Default to child role
                    return const MainNavigator();
                  }
                } else {
                  // If we can't get user data, default to main navigator
                  return const MainNavigator();
                }
              },
            );
          } else {
            // User is not logged in, navigate to login page
            return const LoginPage();
          }
        } else {
          // Show loading screen while determining auth state
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => MainNavigatorState();
}

class MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const NotificationsPage(),
    const VRSessionsPage(),
    const ProgressPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _pages[_currentIndex],
      extendBody: true,
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

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _currentIndex == index;
    return IconButton(
      icon: Icon(
        icon,
        color: isSelected ? const Color(0xFF48CAE4) : Colors.grey,
        size: 24,
      ),
      onPressed: () => onItemTapped(index),
    );
  }

  Widget _buildCenterVRButton() {
    final isSelected = _currentIndex == 2;
    return GestureDetector(
      onTap: () => onItemTapped(2),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF48CAE4) : Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Image.asset(
            'assets/icons/vr_headset_icon.png', // Update this path to your PNG file
            width: 20,
            height: 20,
            // No need for colorFilter since it's a PNG
          ),
        ),
      ),
    );
  }

  void onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}

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

  Future<void> _saveAvatarPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('skinTone', selectedSkinTone.value);
    await prefs.setString('hair', selectedHair);
    await prefs.setString('outfit', selectedOutfit);
  }

  Future<void> _loadAvatarPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedSkinTone = Color(prefs.getInt('skinTone') ?? Colors.bisque.value);
      selectedHair = prefs.getString('hair') ?? "assets/hair1.png";
      selectedOutfit = prefs.getString('outfit') ?? "assets/outfit1.png";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Your Avatar"),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () {}),
        actions: [IconButton(icon: const Icon(Icons.menu), onPressed: () {})],
      ),
      body: Column(
        children: [
          _buildAvatarPreview(),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.person), text: "Basic"),
              Tab(icon: Icon(Icons.brush), text: "Hair"),
              Tab(icon: Icon(Icons.checkroom), text: "Outfit"),
              Tab(icon: Icon(Icons.star), text: "Extras"),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSkinToneOptions(),
                _buildHairOptions(),
                _buildOutfitOptions(),
                const Center(child: Text("Extras Coming Soon!")),
              ],
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }


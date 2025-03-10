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

  Widget _buildAvatarPreview() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.lightBlueAccent,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(radius: 70, backgroundColor: selectedSkinTone),
            Image.asset(selectedHair, width: 120),
            Image.asset(selectedOutfit, width: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSkinToneOptions() {
    List<Color> skinTones = [Colors.bisque, Colors.peachpuff, Colors.saddlebrown, Colors.brown, Colors.black];
    return ListView(
      scrollDirection: Axis.horizontal,
      children: skinTones.map((color) {
        return GestureDetector(
          onTap: () {
            setState(() => selectedSkinTone = color);
          },
          child: Container(
            width: 50,
            height: 50,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: selectedSkinTone == color ? Colors.blue : Colors.black, width: 3),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHairOptions() {
    List<String> hairStyles = ["assets/hair1.png", "assets/hair2.png"];
    return ListView(
      scrollDirection: Axis.horizontal,
      children: hairStyles.map((imagePath) {
        return GestureDetector(
          onTap: () {
            setState(() => selectedHair = imagePath);
          },
          child: Image.asset(imagePath, width: 80, height: 80),
        );
      }).toList(),
    );
  }

  Widget _buildOutfitOptions() {
    List<String> outfits = ["assets/outfit1.png", "assets/outfit2.png"];
    return ListView(
      scrollDirection: Axis.horizontal,
      children: outfits.map((imagePath) {
        return GestureDetector(
          onTap: () {
            setState(() => selectedOutfit = imagePath);
          },
          child: Image.asset(imagePath, width: 80, height: 80),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(onPressed: _saveAvatarPreferences, child: const Text("Save Avatar")),
          OutlinedButton(
            onPressed: () {
              setState(() {
                selectedSkinTone = Colors.bisque;
                selectedHair = "assets/hair1.png";
                selectedOutfit = "assets/outfit1.png";
              });
            },
            child: const Text("Reset Changes"),
          ),
        ],
      ),
    );
  }
}


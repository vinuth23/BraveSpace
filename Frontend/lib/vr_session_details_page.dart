import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'notifications_page.dart';

class VRSessionDetailsPage extends StatefulWidget {
  const VRSessionDetailsPage({super.key});

  @override
  VRSessionDetailsPageState createState() => VRSessionDetailsPageState();
}

class VRSessionDetailsPageState extends State<VRSessionDetailsPage> {
  String videoUrl =
      "https://your-cloud-storage-link.com/video.mp4"; // Replace with backend URL

  void _playVideo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(videoUrl: videoUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'VR sessions',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/images/intermediate.jpeg',
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Beginner',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Classroom Speech',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _playVideo(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          side: const BorderSide(
                            color: Colors.grey,
                            width: 1.0,
                          ),
                        ),
                        icon: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Image.asset(
                            'assets/icons/vr_headset_icon.png',
                            width: 20,
                            height: 20,
                          ),
                        ),
                        label: const Text('Play'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'In the upcoming VR public speaking session, the student will deliver a 2-minute speech in front of a virtual classroom filled with simulated classmates. The scenario will replicate a real classroom setting with audience reactions, including eye contact from classmates, slight background noise, and occasional distractions (such as students shifting in their seats). The goal will be to simulate a realistic public speaking experience and help the student practice confidence, speech clarity, and audience engagement.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Achievements',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _AchievementCard(
                    icon: 'assets/images/master_presenter.jpg',
                    title: 'Master Presenter',
                    description:
                        'Deliver a speech with minimal hesitation or filler words (e.g., "um," "uh").',
                    points: 50,
                  ),
                  const SizedBox(height: 12),
                  _AchievementCard(
                    icon: 'assets/images/master_presenter.jpg',
                    title: 'Eye Contact Expert',
                    description:
                        'Maintain consistent eye contact with different audience members throughout the presentation.',
                    points: 30,
                  ),
                  const SizedBox(height: 12),
                  _AchievementCard(
                    icon: 'assets/images/master_presenter.jpg',
                    title: 'Composure Champion',
                    description:
                        'Successfully maintain composure and continue presenting despite audience distractions.',
                    points: 40,
                  ),
                  const SizedBox(height: 12),
                  _AchievementCard(
                    icon: 'assets/images/master_presenter.jpg',
                    title: 'Voice Virtuoso',
                    description:
                        'Demonstrate excellent voice modulation and clear pronunciation throughout the speech.',
                    points: 35,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerScreen({super.key, required this.videoUrl});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("VR Video")),
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final String icon;
  final String title;
  final String description;
  final int points;

  const _AchievementCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              icon,
              width: 48,
              height: 48,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${points}pts',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

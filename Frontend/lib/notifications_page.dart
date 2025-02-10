import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: Stack(
        children: [
          // Curved background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.cyan.shade200,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: true,
                        onSelected: (bool selected) {},
                        backgroundColor: Colors.cyan.shade100,
                        selectedColor: Colors.cyan.shade200,
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Row(
                          children: [
                            Icon(Icons.vrpano,
                                size: 16, color: Colors.grey.shade700),
                            const SizedBox(width: 4),
                            const Text('Sessions'),
                          ],
                        ),
                        selected: false,
                        onSelected: (bool selected) {},
                        backgroundColor: Colors.grey.shade200,
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Row(
                          children: [
                            Icon(Icons.track_changes,
                                size: 16, color: Colors.grey.shade700),
                            const SizedBox(width: 4),
                            const Text('Goals'),
                          ],
                        ),
                        selected: false,
                        onSelected: (bool selected) {},
                        backgroundColor: Colors.grey.shade200,
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Row(
                          children: [
                            Icon(Icons.description,
                                size: 16, color: Colors.grey.shade700),
                            const SizedBox(width: 4),
                            const Text('Report'),
                          ],
                        ),
                        selected: false,
                        onSelected: (bool selected) {},
                        backgroundColor: Colors.grey.shade200,
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Notification list
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _NotificationItem(
                        icon: Icons.vrpano,
                        title: 'Upcoming session in 30 mins',
                        time: '10 mins ago',
                      ),
                      _NotificationItem(
                        icon: Icons.track_changes,
                        title: 'Daily Challenge - 20 Points collected',
                        time: '12 mins ago',
                      ),
                      _NotificationItem(
                        icon: Icons.vrpano,
                        title: 'Upcoming session in 4 hours',
                        time: '20 mins ago',
                      ),
                      _NotificationItem(
                        icon: Icons.description,
                        title: 'Your weekly report received',
                        time: '2 hrs ago',
                      ),
                      _NotificationItem(
                        icon: Icons.update,
                        title: 'Daily Tasks - Activity updated',
                        time: '3 hrs ago',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String time;

  const _NotificationItem({
    required this.icon,
    required this.title,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.cyan.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.cyan.shade400),
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/colors.dart';
import '../../widgets/bottom_nav.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  void _onBottomNavTap(int index) {
    debugPrint('[Notifications] Bottom nav tapped: index=$index');
    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else if (index == 1) {
      Navigator.pushNamedAndRemoveUntil(context, '/search', (route) => false);
    } else if (index == 2) {
      Navigator.pushNamedAndRemoveUntil(context, '/add_item', (route) => false);
    } else if (index == 4) {
      Navigator.pushNamedAndRemoveUntil(context, '/profile', (route) => false);
    }
    // index 3 is notifications - we're already here
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          backgroundColor: AppColors.primary,
        ),
        body: const Center(child: Text('Please login to view notifications')),
        bottomNavigationBar: BottomNav(currentIndex: 3, onTap: _onBottomNavTap),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          debugPrint(
            '[Notifications] Stream state: ${snapshot.connectionState}',
          );

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            debugPrint('[Notifications] Error: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No notifications yet',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }

          final notifications = snapshot.data!.docs;
          debugPrint(
            '[Notifications] Found ${notifications.length} notifications',
          );

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notifData =
                  notifications[index].data() as Map<String, dynamic>;
              final notifId = notifications[index].id;

              return NotificationCard(
                notificationData: notifData,
                notificationId: notifId,
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNav(currentIndex: 3, onTap: _onBottomNavTap),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notificationData;
  final String notificationId;

  const NotificationCard({
    super.key,
    required this.notificationData,
    required this.notificationId,
  });

  @override
  Widget build(BuildContext context) {
    final type =
        notificationData['type'] ?? 'unknown'; // 'new_item' atau 'item_claimed'
    final title = notificationData['title'] ?? 'New Notification';
    final description = notificationData['description'] ?? '';
    final itemId = notificationData['itemId'];
    final createdAt = notificationData['createdAt'] as Timestamp?;
    final isRead = notificationData['isRead'] ?? false;

    String timeAgo = 'Just now';
    if (createdAt != null) {
      final diff = DateTime.now().difference(createdAt.toDate());
      if (diff.inHours > 0) {
        timeAgo = '${diff.inHours}h ago';
      } else if (diff.inMinutes > 0) {
        timeAgo = '${diff.inMinutes}m ago';
      }
    }

    IconData icon;
    Color iconColor;

    if (type == 'new_item') {
      icon = Icons.add_circle;
      iconColor = Colors.green;
    } else if (type == 'item_claimed') {
      icon = Icons.check_circle;
      iconColor = Colors.blue;
    } else {
      icon = Icons.notifications;
      iconColor = AppColors.primary;
    }

    return GestureDetector(
      onTap: () {
        debugPrint('[Notification] Tapped: $notificationId - Item: $itemId');
        if (itemId != null) {
          Navigator.pushNamed(context, '/item-detail', arguments: itemId);
          // Mark as read
          FirebaseFirestore.instance
              .collection('notifications')
              .doc(notificationId)
              .update({'isRead': true});
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isRead
              ? Colors.white
              : AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead ? Colors.grey[300]! : AppColors.primary,
            width: isRead ? 1 : 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeAgo,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (!isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

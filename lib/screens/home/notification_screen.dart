import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/colors.dart';
import '../../widgets/bottom_nav.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  void _onBottomNavTap(int index) {
    debugPrint('[Notification] Bottom nav tapped: index=$index');
    if (index == 0) {
      Navigator.pushNamed(context, '/home');
    } else if (index == 1) {
      Navigator.pushNamed(context, '/search');
    } else if (index == 2) {
      Navigator.pushNamed(context, '/add-item');
    } else if (index == 4) {
      Navigator.pushNamed(context, '/profile');
    }
    // index 3 is notification - we're already here
  }

  /// Get icon berdasarkan notification type
  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'item_claimed':
        return Icons.check_circle;
      case 'new_item':
        return Icons.notifications;
      default:
        return Icons.info;
    }
  }

  /// Get color berdasarkan notification type
  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'item_claimed':
        return Colors.green;
      case 'new_item':
        return AppColors.primary;
      default:
        return AppColors.textLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Please login to view notifications')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: currentUser.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          debugPrint(
            '📊 Activity: QuerySnapshot state = ${snapshot.connectionState}',
          );

          if (snapshot.hasError) {
            debugPrint('❌ Error fetching notifications: ${snapshot.error}');
            return Center(child: Text('❌ Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data?.docs ?? [];
          debugPrint('📊 Found ${notifications.length} notifications');

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No notifications',
                    style: TextStyle(fontSize: 16, color: AppColors.textLight),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final data = notification.data() as Map<String, dynamic>;
              return _buildNotificationCard(data, notification.id);
            },
          );
        },
      ),
      bottomNavigationBar: BottomNav(currentIndex: 3, onTap: _onBottomNavTap),
    );
  }

  Widget _buildNotificationCard(
    Map<String, dynamic> data,
    String notificationId,
  ) {
    final type = data['type'] as String?;
    final title = data['title'] as String? ?? 'Notification';
    final description = data['description'] as String? ?? '';
    final timestamp = data['createdAt'] as Timestamp?;
    final isRead = data['isRead'] as bool? ?? false;

    final icon = _getNotificationIcon(type);
    final color = _getNotificationColor(type);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isRead ? Colors.white : AppColors.primary.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
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
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (timestamp != null)
                    Text(
                      _formatTime(timestamp.toDate()),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textLight,
                      ),
                    ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'mark_read') {
                  _markAsRead(notificationId, isRead);
                } else if (value == 'delete') {
                  _deleteNotification(notificationId);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'mark_read',
                  child: Text(isRead ? 'Mark as unread' : 'Mark as read'),
                ),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
              icon: const Icon(Icons.more_vert, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAsRead(String notificationId, bool currentIsRead) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': !currentIsRead});
    } catch (e) {
      debugPrint('❌ Error marking notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not authenticated')),
          );
        }
        return;
      }

      // Get the notification to verify ownership before deleting
      final notificationDoc = await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .get();

      if (!notificationDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notification not found')),
          );
        }
        return;
      }

      final notificationData = notificationDoc.data();
      final notificationUserId = notificationData?['userId'];

      // Only allow deletion if the notification belongs to the current user
      if (notificationUserId != currentUser.uid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can only delete your own notifications'),
            ),
          );
        }
        return;
      }

      // Delete the notification
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ Notification deleted')));
      }
      debugPrint('✅ Notification deleted successfully');
    } catch (e) {
      debugPrint('❌ Error deleting notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

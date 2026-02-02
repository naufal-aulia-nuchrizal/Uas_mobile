import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../../config/colors.dart';
import '../../models/item_model.dart';
import '../../widgets/bottom_nav.dart';

class ItemDetailScreen extends StatefulWidget {
  final String itemId;
  const ItemDetailScreen({super.key, required this.itemId});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  void _onBottomNavTap(int index) {
    debugPrint('[ItemDetail] Bottom nav tapped: index=$index');
    if (index == 0) {
      Navigator.pushNamed(context, '/home');
    } else if (index == 1) {
      Navigator.pushNamed(context, '/search');
    } else if (index == 2) {
      Navigator.pushNamed(context, '/add-item');
    } else if (index == 3) {
      Navigator.pushNamed(context, '/notifications');
    } else if (index == 4) {
      Navigator.pushNamed(context, '/profile');
    }
  }

  bool _isClaimingItem = false;

  // Helper method to build image widget from base64 or URL
  Widget _buildImageWidget(String imageData) {
    try {
      if (imageData.isEmpty) {
        return const Center(
          child: Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
        );
      }

      if (imageData.startsWith('data:image')) {
        // Base64 encoded image
        final parts = imageData.split(',');
        if (parts.length < 2) {
          debugPrint('❌ [ItemDetail] Invalid data URL format');
          return const Center(child: Icon(Icons.image_not_supported, size: 64));
        }

        final base64String = parts[1];
        try {
          final bytes = base64Decode(base64String);
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              debugPrint('❌ [ItemDetail] Error displaying base64 image');
              return const Center(
                child: Icon(Icons.image_not_supported, size: 64),
              );
            },
          );
        } catch (decodeError) {
          debugPrint('❌ [ItemDetail] Base64 decode error: $decodeError');
          return const Center(child: Icon(Icons.image_not_supported, size: 64));
        }
      } else if (imageData.startsWith('http')) {
        // URL
        return Image.network(
          imageData,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            debugPrint('❌ [ItemDetail] Error loading network image');
            return const Center(
              child: Icon(Icons.image_not_supported, size: 64),
            );
          },
        );
      } else {
        debugPrint('❌ [ItemDetail] Unknown image format');
        return const Center(child: Icon(Icons.image_not_supported, size: 64));
      }
    } catch (e) {
      debugPrint('❌ [ItemDetail] Error loading image: $e');
      return const Center(child: Icon(Icons.image_not_supported, size: 64));
    }
  }

  Future<void> _claimItem(ItemModel item) async {
    debugPrint('Claiming item: ${item.id}');
    setState(() => _isClaimingItem = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw '❌ User not authenticated';

      await FirebaseFirestore.instance.collection('items').doc(item.id).update({
        'status': 'Claimed',
        'claimedBy': currentUser.uid,
        'claimedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✓ Item claimed successfully: ${item.id}');

      // Create notification for item owner
      debugPrint('📢 Creating claim notification...');
      try {
        // ✅ Standardized notification structure (matching add_item_screen)
        await FirebaseFirestore.instance.collection('notifications').add({
          'type': 'item_claimed',
          'title': 'Item Claimed: ${item.name}',
          'description': '${currentUser.email} claimed your ${item.name}',
          'itemId': item.id,
          'userId': item.userId, // Notify item owner
          'claimedBy': currentUser.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
        debugPrint('✓ Claim notification created!');
      } catch (notifError) {
        debugPrint('❌ Notification creation error: $notifError');
        // Don't fail the entire claim if notification fails
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item claimed successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('❌ Error claiming item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Anda tidak bisa claim item ini - hanya pemilik yang dapat mengklaim',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isClaimingItem = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('items')
            .doc(widget.itemId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Item not found'));
          }

          final item = ItemModel.fromFirestore(
            snapshot.data!.data() as Map<String, dynamic>,
            widget.itemId,
          );

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: item.image.isNotEmpty
                      ? _buildImageWidget(item.image)
                      : const Center(
                          child: Icon(Icons.image_not_supported, size: 64),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: item.status == 'Claimed'
                                  ? Colors.redAccent
                                  : Colors.greenAccent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              item.status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        icon: Icons.category,
                        label: 'Type',
                        value: item.type,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        icon: Icons.location_on,
                        label: 'Location',
                        value: item.location,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        icon: Icons.calendar_today,
                        label: 'Date Found',
                        value: item.date,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item.description,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (item.status != 'Claimed')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isClaimingItem
                                ? null
                                : () => _claimItem(item),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isClaimingItem
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Claim This Item',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'Item Already Claimed',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textLight,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNav(
        currentIndex:
            0, // Not really on any specific tab - can be adjusted if needed
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: AppColors.textLight, fontSize: 12),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

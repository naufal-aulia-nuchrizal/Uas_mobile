import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/colors.dart';
import '../../utils/image_helper.dart';
import '../../models/item_model.dart';
import '../../widgets/bottom_nav.dart';
import 'edit_profile_screen.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _showLogoutDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    void onBottomNavTap(int index) {
      debugPrint('[Profile] Bottom nav tapped: index=$index');
      // Navigation logic - we're already on profile (index 4), so only navigate for other tabs
      if (index == 0) {
        Navigator.pushNamed(context, '/home');
      } else if (index == 1) {
        Navigator.pushNamed(context, '/search');
      } else if (index == 2) {
        Navigator.pushNamed(context, '/add-item');
      } else if (index == 3) {
        Navigator.pushNamed(context, '/notifications');
      }
      // index 4 is profile - we're already here
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            debugPrint('[Profile] Loading user data...');
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            debugPrint('[Profile] Error: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            debugPrint('[Profile] No user data found');
            return const Center(child: Text('No user data'));
          }

          final data = snapshot.data!.data();
          debugPrint('[Profile] User data loaded: ${data != null}');

          // Handle null data
          if (data == null) {
            // Show debug info
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text('User data not found in Firestore'),
                  const SizedBox(height: 8),
                  Text(
                    'UID: ${FirebaseAuth.instance.currentUser?.uid ?? "Unknown"}',
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    ),
                    child: const Text('Create Profile'),
                  ),
                ],
              ),
            );
          }

          final userData = data as Map<String, dynamic>;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile Header Section
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Profile Photo
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 3,
                          ),
                          color: Colors.grey[200],
                        ),
                        child: ClipOval(
                          child:
                              userData['photo'] != null &&
                                  userData['photo'].toString().isNotEmpty
                              ? ImageHelper.buildImage(
                                  userData['photo'],
                                  fit: BoxFit.cover,
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: AppColors.primary,
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Name
                      Text(
                        userData['name'] ?? 'User',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // NIM
                      Text(
                        'NIM: ${userData['nim'] ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Edit Profile Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EditProfileScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Edit Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // My Recent Post Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'My Recent Post',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              debugPrint('[Profile] See all items');
                            },
                            child: Text(
                              'See all',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // User Items Stream
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('items')
                            .where('userId', isEqualTo: uid)
                            .orderBy('createdAt', descending: true)
                            .limit(6)
                            .snapshots(),
                        builder: (context, snapshot) {
                          debugPrint(
                            '[Profile] Items stream state: ${snapshot.connectionState}',
                          );
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            debugPrint(
                              '[Profile] Items error: ${snapshot.error}',
                            );
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 32,
                                ),
                                child: Text(
                                  'No items posted yet',
                                  style: TextStyle(
                                    color: AppColors.textLight,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            );
                          }

                          final items = snapshot.data!.docs;
                          debugPrint('[Profile] Found ${items.length} items');

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1,
                                ),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final itemData =
                                  items[index].data() as Map<String, dynamic>;
                              final itemId = items[index].id;
                              final item = ItemModel.fromFirestore(
                                itemData,
                                itemId,
                              );

                              return GestureDetector(
                                onTap: () {
                                  debugPrint('[Profile] Tapped item: $itemId');
                                  Navigator.pushNamed(
                                    context,
                                    '/item-detail',
                                    arguments: itemId,
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Item Image
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(12),
                                                ),
                                            color: Colors.grey[200],
                                          ),
                                          child: ImageHelper.buildImage(
                                            item.image,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      // Item Info
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textDark,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              item.type,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textLight,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: item.status == 'Lost'
                                                    ? Colors.red[100]
                                                    : Colors.green[100],
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                item.status,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: item.status == 'Lost'
                                                      ? Colors.red
                                                      : Colors.green,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // About Section Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/about'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.info_outline,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'About This App',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Learn about our app and creators',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textDark.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: AppColors.primary.withValues(alpha: 0.6),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // User Account Info Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Information',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Email: ${userData['email'] ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Phone: ${userData['phone'] ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'NIM: ${userData['nim'] ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showLogoutDialog,
                            icon: const Icon(Icons.logout),
                            label: const Text('Logout'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNav(currentIndex: 4, onTap: onBottomNavTap),
    );
  }
}

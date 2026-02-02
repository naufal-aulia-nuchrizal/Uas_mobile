import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/colors.dart';
import '../../models/item_model.dart';
import '../../widgets/item_card.dart';
import '../../widgets/bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Lost & Found'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: _selectedIndex == 0 ? _buildHomeTab() : _buildOtherTab(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add-item'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNav(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          _handleNavigation(index);
        },
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search for lost items...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                // Handle search
              },
            ),
            const SizedBox(height: 24),
            // Recent Finds Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Finds',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/search'),
                  child: Text(
                    'See all',
                    style: TextStyle(color: AppColors.primary, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Items list
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('items')
                  .where('status', isEqualTo: 'Found')
                  .orderBy('createdAt', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                debugPrint(
                  '📊 Home: QuerySnapshot state = ${snapshot.connectionState}',
                );
                if (snapshot.hasData) {
                  debugPrint(
                    '📊 Home: Found ${snapshot.data!.docs.length} items',
                  );
                }
                if (snapshot.hasError) {
                  debugPrint('❌ Home: Query error = ${snapshot.error}');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'Tidak ada item yang ditemukan',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final item = ItemModel.fromFirestore(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    );
                    return ItemCard(
                      title: item.name,
                      description: item.description,
                      imageUrl: item.image.isNotEmpty ? item.image : null,

                      status: item.status,
                      location: item.location,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/item-detail',
                        arguments: item.id,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            // Latest Activity Section
            const Text(
              'Latest Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            // Activity list
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('items')
                  .orderBy('createdAt', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                debugPrint(
                  '📊 Activity: QuerySnapshot state = ${snapshot.connectionState}',
                );
                if (snapshot.hasError) {
                  debugPrint('❌ Activity: Query error = ${snapshot.error}');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'Tidak ada aktivitas',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final item = ItemModel.fromFirestore(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    );
                    return ItemCard(
                      title: item.name,
                      description: item.description,
                      imageUrl: item.image.isNotEmpty ? item.image : null,
                      status: item.status,
                      location: item.location,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/item-detail',
                        arguments: item.id,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherTab() {
    return Center(
      child: Text(
        _selectedIndex == 1
            ? 'Search Tab'
            : _selectedIndex == 3
            ? 'Notifications'
            : 'Profile',
        style: const TextStyle(fontSize: 18),
      ),
    );
  }

  void _handleNavigation(int index) {
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushNamed(context, '/search');
        break;
      case 2:
        Navigator.pushNamed(context, '/add-item');
        break;
      case 3:
        Navigator.pushNamed(context, '/notifications');
        break;
      case 4:
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }
}

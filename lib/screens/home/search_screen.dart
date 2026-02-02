import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/colors.dart';
import '../../models/item_model.dart';
import '../../widgets/bottom_nav.dart';
import '../item/item_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String query = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onBottomNavTap(int index) {
    debugPrint('[Search] Bottom nav tapped: index=$index');
    if (index == 0) {
      Navigator.pushNamed(context, '/home');
    } else if (index == 2) {
      Navigator.pushNamed(context, '/add-item');
    } else if (index == 3) {
      Navigator.pushNamed(context, '/notifications');
    } else if (index == 4) {
      Navigator.pushNamed(context, '/profile');
    }
    // index 1 is search - we're already here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Items'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary.withValues(alpha: 0.1),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => query = val),
              decoration: InputDecoration(
                hintText: 'Search items...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textLight,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('items')
                  .orderBy('date', descending: true)
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
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textDark),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 64,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          query.isEmpty
                              ? 'No items found'
                              : 'No results for "$query"',
                          style: const TextStyle(
                            color: AppColors.textLight,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final allItems = snapshot.data!.docs.map((doc) {
                  return ItemModel.fromFirestore(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  );
                }).toList();

                final results = allItems
                    .where(
                      (item) =>
                          item.name.toLowerCase().contains(
                            query.toLowerCase(),
                          ) ||
                          item.location.toLowerCase().contains(
                            query.toLowerCase(),
                          ) ||
                          item.type.toLowerCase().contains(query.toLowerCase()),
                    )
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final item = results[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ItemDetailScreen(itemId: item.id),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        child: ListTile(
                          title: Text(
                            item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                item.location,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: item.status == 'Lost'
                                      ? Colors.red.withValues(alpha: 0.2)
                                      : Colors.green.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
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
                          trailing: const Icon(
                            Icons.arrow_forward,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNav(currentIndex: 1, onTap: _onBottomNavTap),
    );
  }
}

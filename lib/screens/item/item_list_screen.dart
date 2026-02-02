import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/colors.dart';
import '../../models/item_model.dart';
import '../../widgets/bottom_nav.dart';
import '../../utils/image_helper.dart';
import 'item_detail_screen.dart';

class ItemListScreen extends StatefulWidget {
  const ItemListScreen({super.key});

  @override
  State<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  bool _isGridView = true;
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> _filterOptions = ['All', 'Lost', 'Found'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onBottomNavTap(int index) {
    debugPrint('[ItemList] Bottom nav tapped: index=$index');
    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else if (index == 2) {
      Navigator.pushNamedAndRemoveUntil(context, '/add_item', (route) => false);
    } else if (index == 3) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/notifications',
        (route) => false,
      );
    } else if (index == 4) {
      Navigator.pushNamedAndRemoveUntil(context, '/profile', (route) => false);
    }
    // index 1 is search - we're already here
  }

  Query _buildQuery() {
    Query query = _firestore.collection('items');

    // Filter by status if not 'All'
    if (_selectedFilter != 'All') {
      query = query.where('status', isEqualTo: _selectedFilter);
    }

    // Order by creation date (newest first)
    query = query.orderBy('createdAt', descending: true);

    return query;
  }

  bool _matchesSearch(ItemModel item) {
    if (_searchQuery.isEmpty) return true;

    final query = _searchQuery.toLowerCase();
    return item.name.toLowerCase().contains(query) ||
        item.type.toLowerCase().contains(query) ||
        item.location.toLowerCase().contains(query) ||
        item.description.toLowerCase().contains(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Search Items'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: IconButton(
                icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
                onPressed: () {
                  setState(() => _isGridView = !_isGridView);
                  debugPrint(
                    '[ItemList] Toggled view: ${_isGridView ? "Grid" : "List"}',
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _searchQuery = value);
                debugPrint('[ItemList] Search query: $value');
              },
              decoration: InputDecoration(
                hintText: 'Search items...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          // Filter buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: _filterOptions.map((filter) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(filter),
                      selected: _selectedFilter == filter,
                      onSelected: (selected) {
                        setState(() => _selectedFilter = filter);
                        debugPrint('[ItemList] Filter: $filter');
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _selectedFilter == filter
                            ? Colors.white
                            : AppColors.textDark,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Items grid/list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildQuery().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  debugPrint('[ItemList] Loading items...');
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (snapshot.hasError) {
                  debugPrint('[ItemList] Error: ${snapshot.error}');
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
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  debugPrint('[ItemList] No items found');
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No items found'),
                      ],
                    ),
                  );
                }

                // Filter items based on search query
                final allItems = snapshot.data!.docs
                    .map(
                      (doc) => ItemModel.fromFirestore(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      ),
                    )
                    .toList();

                final filteredItems = allItems
                    .where((item) => _matchesSearch(item))
                    .toList();

                if (filteredItems.isEmpty && _searchQuery.isNotEmpty) {
                  debugPrint('[ItemList] No search results for: $_searchQuery');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text('No results for "$_searchQuery"'),
                      ],
                    ),
                  );
                }

                debugPrint(
                  '[ItemList] Showing ${filteredItems.length} items (view: ${_isGridView ? "Grid" : "List"})',
                );

                if (_isGridView) {
                  // Grid view
                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return GestureDetector(
                        onTap: () {
                          debugPrint('[ItemList] Tapped item: ${item.id}');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ItemDetailScreen(itemId: item.id),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    ),
                                  ),
                                  child: ImageHelper.buildImage(
                                    item.image,
                                    width: double.infinity,
                                    height: double.infinity,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
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
                                      const SizedBox(height: 4),
                                      Text(
                                        item.location,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: item.status == 'Lost'
                                              ? Colors.red.withValues(
                                                  alpha: 0.2,
                                                )
                                              : Colors.green.withValues(
                                                  alpha: 0.2,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          item.status,
                                          style: TextStyle(
                                            fontSize: 9,
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
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  // List view
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return GestureDetector(
                        onTap: () {
                          debugPrint('[ItemList] Tapped item: ${item.id}');
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
                            leading: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ImageHelper.buildImage(
                                item.image,
                                width: 60,
                                height: 60,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
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
                }
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNav(currentIndex: 1, onTap: _onBottomNavTap),
    );
  }
}

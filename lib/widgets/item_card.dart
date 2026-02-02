import 'package:flutter/material.dart';
import '../utils/image_helper.dart';

class ItemCard extends StatelessWidget {
  final String title;
  final String description;
  final String? imageUrl;
  final String status;
  final String? location;
  final VoidCallback? onTap;

  const ItemCard({
    super.key,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.status,
    this.location,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Item image
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ImageHelper.buildImage(
                  imageUrl,
                  width: 100,
                  height: 100,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              // Item details
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: status == 'lost'
                                ? Colors.red[100]
                                : Colors.green[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: status == 'lost'
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                        ),
                        if (location != null) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.location_on, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

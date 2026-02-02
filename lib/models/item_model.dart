class ItemModel {
  final String id;
  final String name;
  final String type;
  final String location;
  final String date;
  final String description;
  final String status;
  final String image;
  final String userId;

  ItemModel({
    required this.id,
    required this.name,
    required this.type,
    required this.location,
    required this.date,
    required this.description,
    required this.status,
    required this.image,
    required this.userId,
  });

  factory ItemModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ItemModel(
      id: id,
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      location: data['location'] ?? '',
      date: data['date'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'lost',
      image: data['image'] ?? '',
      userId: data['userId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'location': location,
      'date': date,
      'description': description,
      'status': status,
      'image': image,
      'userId': userId,
    };
  }
}

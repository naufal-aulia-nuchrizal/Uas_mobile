class UserModel {
  final String id;
  final String email;
  final String name;
  final String? nim;
  final String? photo;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.nim,
    this.photo,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      nim: data['nim'],
      photo: data['photo'],
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'nim': nim,
      'photo': photo,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

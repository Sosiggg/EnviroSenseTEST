class User {
  final int id;
  final String username;
  final String email;
  final bool isActive;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.isActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle the case where id might be a string or an int
    int userId;
    if (json['id'] is String) {
      userId = int.tryParse(json['id']) ?? 0;
    } else {
      userId = json['id'] ?? 0;
    }

    return User(
      id: userId,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'is_active': isActive,
    };
  }

  User copyWith({int? id, String? username, String? email, bool? isActive}) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
    );
  }
}

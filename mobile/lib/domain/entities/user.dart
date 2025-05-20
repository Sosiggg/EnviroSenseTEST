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
    // Handle the case where id might be a string, an int, or missing
    int userId = 0;

    if (json.containsKey('id')) {
      if (json['id'] is String) {
        // Try to parse the string as an integer
        userId = int.tryParse(json['id']) ?? 0;
      } else if (json['id'] is int) {
        // Use the integer directly
        userId = json['id'];
      }
    }

    // Handle is_active which might be a string 'true'/'false' or a boolean
    bool isActive = true;
    if (json.containsKey('is_active')) {
      if (json['is_active'] is String) {
        isActive = json['is_active'].toLowerCase() == 'true';
      } else if (json['is_active'] is bool) {
        isActive = json['is_active'];
      }
    }

    return User(
      id: userId,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      isActive: isActive,
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

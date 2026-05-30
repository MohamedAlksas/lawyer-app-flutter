import 'dart:convert';

class User {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final bool isActive;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.isActive = true,
    this.createdAt,
  });

  bool get isAdmin => role == 'ADMIN';

  Map<String, dynamic> toMap() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'role': role,
        'isActive': isActive,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory User.fromMap(Map<String, dynamic> map) => User(
        id: map['id'] ?? '',
        fullName: map['fullName'] ?? '',
        email: map['email'] ?? '',
        role: map['role'] ?? 'LAWYER',
        isActive: map['isActive'] ?? true,
        createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) : null,
      );

  String toJson() => jsonEncode(toMap());
  factory User.fromJson(String source) => User.fromMap(jsonDecode(source));

  User copyWith({String? fullName, String? email, String? role, bool? isActive}) => User(
        id: id,
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
        role: role ?? this.role,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
      );
}

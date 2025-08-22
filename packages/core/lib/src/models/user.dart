import 'package:meta/meta.dart';

@immutable
class User {
  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
    this.preferences = const {},
  });

  final String id;
  final String username;
  final String email;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> preferences;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'preferences_json': preferences,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      email: map['email'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      preferences: Map<String, dynamic>.from(map['preferences_json'] ?? {}),
    );
  }

  User copyWith({
    String? username,
    String? email,
    DateTime? updatedAt,
    Map<String, dynamic>? preferences,
  }) {
    return User(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      preferences: preferences ?? this.preferences,
    );
  }
}

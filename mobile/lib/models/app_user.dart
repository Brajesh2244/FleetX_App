import '../core/format.dart';

class AppUser {
  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.active = true,
  });

  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final bool active;

  bool get isAdmin => role.toUpperCase() == 'ADMIN';

  /// First letter, for the profile avatar.
  String get initial => name.isEmpty ? '?' : name[0].toUpperCase();

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: asInt(json['id'] ?? json['userId']),
        name: asText(json['name']),
        email: asText(json['email']),
        phone: json['phone'] as String?,
        role: asText(json['role'], 'DRIVER'),
        active: json['active'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'active': active,
      };
}

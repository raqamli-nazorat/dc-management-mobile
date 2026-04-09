class AuthUser {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? avatarUrl;

  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.avatarUrl,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

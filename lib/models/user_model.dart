class UserModel {
  final int id;
  final String username;
  final String phoneNumber;
  final int region;
  final int direction;
  final String passportSeries;
  final String? passportImage;
  final String role;
  final String fixedSalary;
  final String balance;
  final String? avatar;
  final String? dateJoined;
  final bool? changePassword;
  final bool? isActive;

  const UserModel({
    required this.id,
    required this.username,
    required this.phoneNumber,
    required this.region,
    required this.direction,
    required this.passportSeries,
    this.passportImage,
    required this.role,
    required this.fixedSalary,
    required this.balance,
    this.avatar,
    this.dateJoined,
    this.changePassword,
    this.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: _parseInt(json['id']),
        username: _str(json['username']),
        phoneNumber: _str(json['phone_number']),
        region: _parseInt(json['region']),
        direction: _parseInt(json['direction']),
        passportSeries: _str(json['passport_series']),
        passportImage: json['passport_image'] as String?,
        role: _str(json['role']),
        fixedSalary: _str(json['fixed_salary'], '0'),
        balance: _str(json['balance'], '0'),
        avatar: json['avatar'] as String?,
        dateJoined: json['date_joined'] as String?,
        changePassword: json['change_password'] as bool?,
        isActive: json['is_active'] as bool?,
      );

  // Safe parsers — handle null, int, double, and string values from the API
  static int _parseInt(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  static String _str(dynamic v, [String fallback = '']) {
    if (v == null) return fallback;
    return v.toString();
  }

  String get initials {
    final cleaned = username.trim();
    if (cleaned.isEmpty) return '?';
    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return cleaned[0].toUpperCase();
  }

  String get roleLabel {
    switch (role.toLowerCase()) {
      case 'superadmin':
        return 'Super Admin';
      case 'admin':
        return 'Admin';
      case 'manager':
        return 'Menejer';
      case 'worker':
        return 'Xodim';
      default:
        return role.isNotEmpty
            ? role[0].toUpperCase() + role.substring(1)
            : "Noma'lum";
    }
  }
}

import 'package:dcmanagement/services/storage_service.dart';
import 'package:flutter/foundation.dart';

class RoleService extends ChangeNotifier {
  static final RoleService instance = RoleService._();
  RoleService._();

  static const _key = 'selected_role';

  String? _role;
  String? get role => _role;
  bool get hasRole => _role != null && _role!.isNotEmpty;

  Future<String?> load() async {
    final stored = await StorageService().getString(_key);
    if (stored == _role) return _role;
    _role = stored;
    notifyListeners();
    return _role;
  }

  Future<void> setRole(String role) async {
    _role = role;
    await StorageService().saveString(_key, role);
    notifyListeners();
  }

  void clearCache() {
    _role = null;
    notifyListeners();
  }

  /// 'admin' | 'manager' | 'employee'
  String get group {
    switch (_role?.toLowerCase()) {
      case 'superadmin':
      case 'admin':
        return 'admin';
      case 'manager':
        return 'manager';
      default:
        return 'employee';
    }
  }

  /// First tab route after login
  String get homeRoute {
    switch (group) {
      case 'admin':
        return '/users';
      case 'manager':
        return '/projects';
      default:
        return '/finance';
    }
  }
}

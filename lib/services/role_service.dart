import 'package:dcmanagement/services/storage_service.dart';
import 'package:flutter/foundation.dart';

class RoleService extends ChangeNotifier {
  static final RoleService instance = RoleService._();
  RoleService._();

  static const _key = 'main_role';

  String? _role;
  String? get role => _role;
  bool get hasRole => _role != null && _role!.isNotEmpty;

  /// admin / superadmin
  bool get isAdmin {
    final r = _role?.toLowerCase();
    return r == 'admin' || r == 'superadmin';
  }

  /// manager / accountant / observer  (admin emas)
  bool get isManager {
    final r = _role?.toLowerCase();
    return r == 'manager' || r == 'accountant' || r == 'observer';
  }

  /// employee
  bool get isWorker => _role?.toLowerCase() == 'employee';

  Future<String?> load() async {
    final storage = StorageService();
    String? stored = await storage.getString(_key);
    if (stored == null) {
      final legacy = await storage.getString('selected_role');
      if (legacy != null) {
        await storage.saveString(_key, legacy);
        await storage.remove('selected_role');
        stored = legacy;
      }
    }
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

  String _getRoleLabel(String r) {
    switch (r.toLowerCase()) {
      case 'superadmin':
        return 'Super Admin';
      case 'admin':
        return 'Admin';
      case 'manager':
        return 'Menejer';
      case 'accountant':
        return 'Hisobchi';
      case 'observer':
        return 'Nazoratchi';
      case 'employee':
        return 'Xodim';
      default:
        return r[0].toUpperCase() + r.substring(1);
    }
  }

  String get roleLabel => _role != null ? _getRoleLabel(_role!) : "Noma'lum";
}

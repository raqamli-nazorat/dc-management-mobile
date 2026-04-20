import 'package:dcmanagement/api/api.dart';
import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/models/user_model.dart';
import 'package:dcmanagement/screens/user_filter_screen.dart';
import 'package:dcmanagement/services/auth_service.dart';
import 'package:dcmanagement/widgets/worker_card.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _auth = AuthService();
  final _api = ApiService();

  List<UserModel> _all = [];
  List<UserModel> _filtered = [];
  bool _searching = false;
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  bool _ownOnly = false;

  UserFilter _filter = const UserFilter();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _ownOnly = false;
    });
    try {
      final token = await _auth.getToken();
      if (token == null) throw Exception('Token topilmadi');

      List<UserModel> users;
      try {
        users = await _api.getUsers(token);
      } on ApiException catch (e) {
        if (e.statusCode == 403) {
          final me = await _api.getMe(token);
          users = [me];
          _ownOnly = true;
        } else {
          rethrow;
        }
      }

      setState(() {
        _all = users;
        _applyFilters();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _applyFilters() {
    List<UserModel> result = List.of(_all);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((u) {
        return u.username.toLowerCase().contains(q) ||
            u.role.toLowerCase().contains(q) ||
            u.phoneNumber.contains(q);
      }).toList();
    }

    if (_filter.role != null) {
      result = result.where((u) => u.role == _filter.role).toList();
    }

    switch (_filter.sortMode) {
      case UserSortMode.az:
        result.sort((a, b) => a.username.compareTo(b.username));
      case UserSortMode.za:
        result.sort((a, b) => b.username.compareTo(a.username));
      case UserSortMode.salaryAsc:
        result.sort((a, b) {
          final sa = double.tryParse(a.fixedSalary) ?? 0;
          final sb = double.tryParse(b.fixedSalary) ?? 0;
          return sa.compareTo(sb);
        });
      case UserSortMode.salaryDesc:
        result.sort((a, b) {
          final sa = double.tryParse(a.fixedSalary) ?? 0;
          final sb = double.tryParse(b.fixedSalary) ?? 0;
          return sb.compareTo(sa);
        });
      case UserSortMode.none:
        break;
    }

    _filtered = result;
  }

  void _onSearch(String q) {
    setState(() {
      _searchQuery = q;
      _applyFilters();
    });
  }

  List<String> get _uniqueRoles {
    final roles = _all.map((u) => u.role).toSet().toList();
    roles.sort();
    return roles;
  }

  Future<void> _openFilterScreen() async {
    final result = await context.push<UserFilter>(
      '/users/filter',
      extra: {
        'filter': _filter,
        'roles': _uniqueRoles,
      },
    );
    if (result != null) {
      setState(() {
        _filter = result;
        _applyFilters();
      });
    }
  }

  String _activeFilterLabel() {
    final parts = <String>[];
    if (_filter.role != null) parts.add(_filter.role!);
    switch (_filter.sortMode) {
      case UserSortMode.az:
        parts.add('A → Z');
      case UserSortMode.za:
        parts.add('Z → A');
      case UserSortMode.salaryAsc:
        parts.add("Oylik o'sish");
      case UserSortMode.salaryDesc:
        parts.add('Oylik kamayish');
      case UserSortMode.none:
        break;
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.backgroundBase,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Foydalanuvchilar',
                    style: TextStyle(
                      fontSize: 17,
                      fontFamily: "Manrope",
                      fontWeight: FontWeight.w800,
                      color: colors.textStrong,
                    ),
                  ),
                  const Spacer(),
                  if (!_ownOnly) ...[
                    GestureDetector(
                      onTap: () => setState(() => _searching = !_searching),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: colors.backgroundElevation1,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: colors.strokeSub),
                        ),
                        child: Icon(
                          Icons.search,
                          size: 18,
                          color: colors.iconSub,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _openFilterScreen,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _filter.hasActive
                              ? colors.accentSub
                              : colors.backgroundElevation1,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _filter.hasActive
                                ? colors.accentSub
                                : colors.strokeSub,
                          ),
                        ),
                        child: Icon(
                          LucideIcons.filter,
                          size: 18,
                          color: _filter.hasActive
                              ? Colors.white
                              : colors.iconSub,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Search field
            if (_searching && !_ownOnly)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: TextField(
                  autofocus: true,
                  onChanged: _onSearch,
                  style: TextStyle(color: colors.textStrong),
                  decoration: InputDecoration(
                    hintText: 'Ism yoki rol boyicha qidirish...',
                    hintStyle: TextStyle(color: colors.textSoft),
                    filled: true,
                    fillColor: colors.backgroundElevation1,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.strokeSub),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.strokeSub),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                ),
              ),

            // Active filter indicator
            if (_filter.hasActive && !_ownOnly)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Row(
                  children: [
                    Icon(Icons.filter_list, size: 14, color: colors.accentSub),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _activeFilterLabel(),
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.accentSub,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {
                        _filter = const UserFilter();
                        _applyFilters();
                      }),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: colors.textSoft,
                      ),
                    ),
                  ],
                ),
              ),

            // Permission banner
            if (_ownOnly && !_loading)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colors.backgroundElevation1,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.strokeSub),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: colors.textSoft,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Siz faqat o'z profilingizni ko'rishingiz mumkin",
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSoft,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            Expanded(child: _buildBody(colors)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppColors colors) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: colors.accentSub));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: colors.errorSub),
              const SizedBox(height: 12),
              Text(
                "Ma'lumot yuklanmadi",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colors.textStrong,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: colors.textSub),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Qayta urinish'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentSub,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filtered.isEmpty) {
      return Center(
        child: Text(
          'Foydalanuvchi topilmadi',
          style: TextStyle(color: colors.textSoft),
        ),
      );
    }

    return ListView.builder(
      itemCount: _filtered.length,
      itemBuilder: (_, i) => UserCard(
        user: _filtered[i],
        onTap: () => context.push('/users/${_filtered[i].id}'),
      ),
    );
  }
}

import 'package:dcmanagement/api/api.dart';
import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/models/user_model.dart';
import 'package:dcmanagement/services/auth_service.dart';
import 'package:dcmanagement/widgets/worker_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum _SortMode { none, alphabetical, salaryAsc, salaryDesc }

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

  /// True when the user only has permission to see their own profile.
  bool _ownOnly = false;

  _SortMode _sortMode = _SortMode.none;
  String? _roleFilter; // null = all roles

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
        print('✅ Users (${users.length}):');
        for (final u in users) {
          print(
            ' ${users}',
          );
        }
      } on ApiException catch (e) {
        if (e.statusCode == 403) {
          // Regular user — show only their own profile
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

    // 1. Search filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((u) {
        return u.username.toLowerCase().contains(q) ||
            u.role.toLowerCase().contains(q) ||
            u.phoneNumber.contains(q);
      }).toList();
    }

    // 2. Role filter
    if (_roleFilter != null) {
      result = result.where((u) => u.role == _roleFilter).toList();
    }

    // 3. Sort
    switch (_sortMode) {
      case _SortMode.alphabetical:
        result.sort((a, b) => a.username.compareTo(b.username));
        break;
      case _SortMode.salaryAsc:
        result.sort((a, b) {
          final sa = double.tryParse(a.fixedSalary) ?? 0;
          final sb = double.tryParse(b.fixedSalary) ?? 0;
          return sa.compareTo(sb);
        });
        break;
      case _SortMode.salaryDesc:
        result.sort((a, b) {
          final sa = double.tryParse(a.fixedSalary) ?? 0;
          final sb = double.tryParse(b.fixedSalary) ?? 0;
          return sb.compareTo(sa);
        });
        break;
      case _SortMode.none:
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

  bool get _hasActiveFilter =>
      _sortMode != _SortMode.none || _roleFilter != null;

  void _showFilterSheet() {
    final colors = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.backgroundElevation1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: colors.strokeSub,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Title row
                  Row(
                    children: [
                      Text(
                        'Filter',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colors.textStrong,
                        ),
                      ),
                      const Spacer(),
                      if (_sortMode != _SortMode.none || _roleFilter != null)
                        GestureDetector(
                          onTap: () {
                            setSheetState(() {});
                            setState(() {
                              _sortMode = _SortMode.none;
                              _roleFilter = null;
                              _applyFilters();
                            });
                          },
                          child: Text(
                            'Tozalash',
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.accentSub,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- Alifbo ---
                  Text(
                    'Alifbo bo\'yicha',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textSub,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _FilterChipRow(
                    colors: colors,
                    options: const ['A → Z'],
                    selected: _sortMode == _SortMode.alphabetical
                        ? 'A → Z'
                        : null,
                    onSelect: (val) {
                      setSheetState(() {});
                      setState(() {
                        _sortMode = _sortMode == _SortMode.alphabetical
                            ? _SortMode.none
                            : _SortMode.alphabetical;
                        _applyFilters();
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- Oylik ---
                  Text(
                    'Oylik bo\'yicha',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textSub,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _FilterChipRow(
                    colors: colors,
                    options: const ['O\'sish', 'Kamayish'],
                    selected: _sortMode == _SortMode.salaryAsc
                        ? 'O\'sish'
                        : _sortMode == _SortMode.salaryDesc
                        ? 'Kamayish'
                        : null,
                    onSelect: (val) {
                      setSheetState(() {});
                      setState(() {
                        if (val == 'O\'sish') {
                          _sortMode = _sortMode == _SortMode.salaryAsc
                              ? _SortMode.none
                              : _SortMode.salaryAsc;
                        } else {
                          _sortMode = _sortMode == _SortMode.salaryDesc
                              ? _SortMode.none
                              : _SortMode.salaryDesc;
                        }
                        _applyFilters();
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- Lavozim ---
                  Text(
                    'Lavozim bo\'yicha',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textSub,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _uniqueRoles.map((role) {
                      final selected = _roleFilter == role;
                      return GestureDetector(
                        onTap: () {
                          setSheetState(() {});
                          setState(() {
                            _roleFilter = selected ? null : role;
                            _applyFilters();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? colors.accentSub
                                : colors.backgroundBase,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? colors.accentSub
                                  : colors.strokeSub,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: colors.textStrong,
                    ),
                  ),
                  const Spacer(),
                  if (!_ownOnly) ...[
                    // Filter button
                    GestureDetector(
                      onTap: _showFilterSheet,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _hasActiveFilter
                              ? colors.accentSub
                              : colors.backgroundElevation1,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _hasActiveFilter
                                ? colors.accentSub
                                : colors.strokeSub,
                          ),
                        ),
                        child: Icon(
                          Icons.tune,
                          size: 18,
                          color: _hasActiveFilter
                              ? Colors.white
                              : colors.iconSub,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Search button
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

            // Active filter chips
            if (_hasActiveFilter && !_ownOnly)
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
                        _sortMode = _SortMode.none;
                        _roleFilter = null;
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

            // Body
            Expanded(child: _buildBody(colors)),
          ],
        ),
      ),
    );
  }

  String _activeFilterLabel() {
    final parts = <String>[];

    switch (_sortMode) {
      case _SortMode.alphabetical:
        parts.add('A → Z');
        break;
      case _SortMode.salaryAsc:
        parts.add('Oylik o\'sish');
        break;
      case _SortMode.salaryDesc:
        parts.add('Oylik kamayish');
        break;
      case _SortMode.none:
        break;
    }
    return parts.join(' · ');
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

// ---------------------------------------------------------------------------
// Helper: filter chip row
// ---------------------------------------------------------------------------
class _FilterChipRow extends StatelessWidget {
  const _FilterChipRow({
    required this.colors,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final AppColors colors;
  final List<String> options;
  final String? selected;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: options.map((opt) {
        final isSelected = selected == opt;
        return GestureDetector(
          onTap: () => onSelect(opt),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? colors.accentSub : colors.backgroundBase,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? colors.accentSub : colors.strokeSub,
              ),
            ),
            child: Text(
              opt,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : colors.textStrong,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

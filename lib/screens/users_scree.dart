import 'package:dcmanagement/api/api.dart';
import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/models/user_model.dart';
import 'package:dcmanagement/services/auth_service.dart';
import 'package:dcmanagement/widgets/worker_card.dart';
import 'package:flutter/material.dart';
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

  /// True when the user only has permission to see their own profile.
  bool _ownOnly = false;

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
        _filtered = users;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onSearch(String q) {
    final query = q.toLowerCase();
    setState(() {
      _filtered = _all.where((u) {
        return u.username.toLowerCase().contains(query) ||
            u.role.toLowerCase().contains(query) ||
            u.phoneNumber.contains(query);
      }).toList();
    });
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
                  if (!_ownOnly)
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
                        child:
                            Icon(Icons.search, size: 18, color: colors.iconSub),
                      ),
                    ),
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
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14),
                  ),
                ),
              ),

            // Permission banner
            if (_ownOnly && !_loading)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: colors.backgroundElevation1,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.strokeSub),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: colors.textSoft),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Siz faqat o'z profilingizni ko'rishingiz mumkin",
                          style: TextStyle(
                              fontSize: 12, color: colors.textSoft),
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

  Widget _buildBody(AppColors colors) {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: colors.accentSub),
      );
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
                    fontWeight: FontWeight.w600, color: colors.textStrong),
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

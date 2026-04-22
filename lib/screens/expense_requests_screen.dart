import 'dart:async';

import 'package:dcmanagement/api/api.dart';
import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/models/expense_filter.dart';
import 'package:dcmanagement/screens/expense_detail_screen.dart';
import 'package:dcmanagement/screens/expense_filter_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:dcmanagement/services/auth_service.dart';
import 'package:dcmanagement/widgets/app_state_widgets.dart';
import 'package:dcmanagement/widgets/info_row.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ExpenseRequestsScreen extends StatefulWidget {
  const ExpenseRequestsScreen({super.key});

  @override
  State<ExpenseRequestsScreen> createState() => _ExpenseRequestsScreenState();
}

class _ExpenseRequestsScreenState extends State<ExpenseRequestsScreen> {
  final _api = ApiService();
  final _auth = AuthService();

  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String? _error;
  bool _searching = false;
  final _searchCtrl = TextEditingController();

  int? _throttleSeconds;
  Timer? _throttleTimer;

  ExpenseFilter _filter = const ExpenseFilter();

  @override
  void initState() {
    super.initState();
    _initFilter();
  }

  Future<void> _initFilter() async {
    _filter = await ExpenseFilter.loadSaved();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _throttleTimer?.cancel();
    super.dispose();
  }

  void _startThrottleCountdown(int seconds) {
    _throttleTimer?.cancel();
    setState(() => _throttleSeconds = seconds);
    _throttleTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _throttleSeconds = (_throttleSeconds ?? 1) - 1;
      });
      if ((_throttleSeconds ?? 0) <= 0) {
        t.cancel();
        setState(() => _throttleSeconds = null);
      }
    });
  }

  int? _parseThrottleSeconds(String msg) {
    final match = RegExp(r'(\d+)\s+second').firstMatch(msg);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  Future<void> _load() async {
    _throttleTimer?.cancel();
    setState(() {
      _loading = true;
      _error = null;
      _throttleSeconds = null;
    });
    try {
      final token = await _auth.getToken();
      if (token == null) throw Exception('Token topilmadi');
      final data = await _api.getExpenseRequests(token);
      setState(() {
        _all = data;
        _filtered = _applyFilter(data);
        _loading = false;
      });
    } on ApiException catch (e) {
      if (e.statusCode == 429) {
        final secs = _parseThrottleSeconds(e.message) ?? 60;
        setState(() => _loading = false);
        _startThrottleCountdown(secs);
      } else {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> list) {
    if (!_filter.isActive) return list;
    return list.where((item) {
      final project = item['project_info'] as Map<String, dynamic>? ?? {};
      final category =
          item['expense_category_info'] as Map<String, dynamic>? ?? {};
      final amount = (num.tryParse(item['amount']?.toString() ?? '') ?? 0)
          .abs()
          .toDouble();

      if (_filter.projectId != null && project['id'] != _filter.projectId) {
        return false;
      }
      if (_filter.categoryId != null && category['id'] != _filter.categoryId) {
        return false;
      }
      if (_filter.amountMin != null && amount < _filter.amountMin!) {
        return false;
      }
      if (_filter.amountMax != null && amount > _filter.amountMax!) {
        return false;
      }
      if (_filter.createdAtFrom != null || _filter.createdAtTo != null) {
        final raw = item['created_at'] as String?;
        final dt = raw != null ? DateTime.tryParse(raw) : null;
        if (dt == null) return false;
        if (_filter.createdAtFrom != null &&
            dt.isBefore(
              _filter.createdAtFrom!.copyWith(hour: 0, minute: 0, second: 0),
            )) {
          return false;
        }
        if (_filter.createdAtTo != null &&
            dt.isAfter(
              _filter.createdAtTo!.copyWith(hour: 23, minute: 59, second: 59),
            )) {
          return false;
        }
      }
      if (_filter.paidAtFrom != null || _filter.paidAtTo != null) {
        final raw = item['paid_at'] as String?;
        final dt = raw != null ? DateTime.tryParse(raw) : null;
        if (dt == null) return false;
        if (_filter.paidAtFrom != null &&
            dt.isBefore(
              _filter.paidAtFrom!.copyWith(hour: 0, minute: 0, second: 0),
            )) {
          return false;
        }
        if (_filter.paidAtTo != null &&
            dt.isAfter(
              _filter.paidAtTo!.copyWith(hour: 23, minute: 59, second: 59),
            )) {
          return false;
        }
      }
      if (_filter.confirmedAtFrom != null || _filter.confirmedAtTo != null) {
        final raw = item['confirmed_at'] as String?;
        final dt = raw != null ? DateTime.tryParse(raw) : null;
        if (dt == null) return false;
        if (_filter.confirmedAtFrom != null &&
            dt.isBefore(
              _filter.confirmedAtFrom!.copyWith(hour: 0, minute: 0, second: 0),
            )) {
          return false;
        }
        if (_filter.confirmedAtTo != null &&
            dt.isAfter(
              _filter.confirmedAtTo!.copyWith(hour: 23, minute: 59, second: 59),
            )) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> _openFilter(AppColors colors) async {
    final result = await Navigator.of(context).push<ExpenseFilter>(
      MaterialPageRoute(builder: (_) => ExpenseFilterScreen(initial: _filter)),
    );
    if (result != null && mounted) {
      setState(() {
        _filter = result;
        _filtered = _applyFilter(_all);
      });
    }
  }

  void _applySearch(String q) {
    final query = q.toLowerCase();
    setState(() {
      _filtered = _all.where((item) {
        final user = item['user_info'] as Map<String, dynamic>? ?? {};
        final project = item['project_info'] as Map<String, dynamic>? ?? {};
        final category =
            item['expense_category_info'] as Map<String, dynamic>? ?? {};
        return (user['username'] as String? ?? '').toLowerCase().contains(
              query,
            ) ||
            (project['title'] as String? ?? '').toLowerCase().contains(query) ||
            (category['title'] as String? ?? '').toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.backgroundElevation1Alt,
      appBar: AppBar(
        backgroundColor: colors.backgroundElevation1Alt,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textStrong),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await context.push<bool>(
                  '/finance/expense-request-form',
                );
                if (result == true && mounted) _load();
              },
              iconAlignment: IconAlignment.end,
              label: const Text(
                "So'rov yuborish",
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              icon: Image.asset(
                'assets/images/money.png',
                width: 18,
                height: 18,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentSub,
                foregroundColor: colors.textWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: _searching
                  ? TextField(
                      controller: _searchCtrl,
                      autofocus: true,
                      onChanged: _applySearch,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w500,
                        color: colors.textStrong,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Qidirish...',
                        hintStyle: TextStyle(
                          fontFamily: 'Manrope',
                          color: colors.textSoft,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.close, color: colors.iconSub),
                          onPressed: () {
                            setState(() {
                              _searching = false;
                              _searchCtrl.clear();
                              _filtered = _all;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.strokeSub),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.strokeSub),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.accentSub),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor: colors.backgroundElevation1,
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Xarajat so'rovlari",
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: colors.textStrong,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            _ActionButton(
                              icon: Icons.search_rounded,
                              colors: colors,
                              onTap: () => setState(() => _searching = true),
                            ),
                            const SizedBox(width: 10),
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                _ActionButton(
                                  icon: LucideIcons.filter,
                                  colors: colors,
                                  onTap: () => _openFilter(colors),
                                ),
                                if (_filter.isActive)
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: colors.accentSub,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ],
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
    if (_throttleSeconds != null) {
      return ThrottleCountdown(seconds: _throttleSeconds!, colors: colors);
    }
    if (_error != null) {
      return ErrorRetry(message: _error!, onRetry: _load, colors: colors);
    }
    if (_filtered.isEmpty) {
      return Center(
        child: Text(
          "Ma'lumot topilmadi",
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w500,
            color: colors.textSoft,
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: colors.accentSub,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: _filtered.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) => GestureDetector(
          onTap: () {
            final id = _filtered[index]['id'] as int?;
            if (id == null) return;
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ExpenseDetailScreen(id: id)),
            );
          },
          child: _ExpenseCard(item: _filtered[index], colors: colors),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────

class _ExpenseCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final AppColors colors;

  const _ExpenseCard({required this.item, required this.colors});

  static const _avatarColors = [
    Color(0xFF7C6AF7),
    Color(0xFF526ED3),
    Color(0xFF3F8FA8),
    Color(0xFF5A9E6F),
    Color(0xFFB06B3A),
    Color(0xFF8F4CA8),
    Color(0xFFA84C6E),
    Color(0xFF4C7EA8),
  ];

  Color _avatarColor(String name) {
    if (name.isEmpty) return _avatarColors[0];
    return _avatarColors[name.codeUnitAt(0) % _avatarColors.length];
  }

  String _formatAmount(dynamic raw) {
    final num value = num.tryParse(raw?.toString() ?? '') ?? 0;
    final formatter = NumberFormat('#,##0.00', 'uz_UZ');
    return formatter
        .format(value.abs())
        .replaceAll(',', ' ')
        .replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    final user = item['user_info'] as Map<String, dynamic>? ?? {};
    final project = item['project_info'] as Map<String, dynamic>? ?? {};
    final category =
        item['expense_category_info'] as Map<String, dynamic>? ?? {};

    final username = user['username'] as String? ?? '—';
    final projectTitle = project['title'] as String? ?? '—';
    final categoryTitle = category['title'] as String? ?? '—';
    final amount = _formatAmount(item['amount']);
    final status = item['status'] as String? ?? 'pending';
    final isApproved = status == 'confirmed' || status == 'paid';

    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';
    final avatarColor = _avatarColor(username);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: colors.backgroundElevation1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.strokeSub),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: avatar + ism/loyiha
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.backgroundElevation3,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: colors.iconStrong,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InfoRow(
                      colors: colors,
                      label: 'Ism sharifi:  ',
                      value: username,
                      valueBold: true,
                    ),
                    const SizedBox(height: 2),
                    InfoRow(
                      colors: colors,
                      label: 'Loyiha: ',
                      value: projectTitle,
                      valueBold: true,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Bottom rows: full width
          InfoRow(
            colors: colors,
            label: 'Xarajat turi:  ',
            value: categoryTitle,
            valueBold: true,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: InfoRow(
                  colors: colors,
                  label: 'Summasi:  ',
                  value: amount,
                  valueBold: true,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isApproved
                      ? colors.successStrong
                      : colors.backgroundElevation2,
                  borderRadius: BorderRadius.circular(6),
                  border: isApproved
                      ? null
                      : Border.all(color: colors.strokeStrong),
                ),
                child: isApproved
                    ? Icon(
                        Icons.check_rounded,
                        color: colors.white,
                        size: 18,
                      )
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final AppColors colors;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: colors.backgroundElevation1, // 👈 orqa fon
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.strokeSub, // 👈 border
          ),
        ),
        child: Icon(icon, color: colors.iconSub, size: 22),
      ),
    );
  }
}

import 'dart:async';

import 'package:dcmanagement/api/api.dart';
import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/models/expense_filter.dart';
import 'package:dcmanagement/screens/expense_detail_screen.dart';
import 'package:dcmanagement/screens/expense_filter_screen.dart';
import 'package:dcmanagement/screens/expense_request_form_sheet.dart';
import 'package:dcmanagement/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
      final amount =
          (num.tryParse(item['amount']?.toString() ?? '') ?? 0).abs().toDouble();

      if (_filter.projectId != null && project['id'] != _filter.projectId) {
        return false;
      }
      if (_filter.categoryId != null &&
          category['id'] != _filter.categoryId) {
        return false;
      }
      if (_filter.amountMin != null && amount < _filter.amountMin!) {
        return false;
      }
      if (_filter.amountMax != null && amount > _filter.amountMax!) {
        return false;
      }
      if (_filter.createdAt != null) {
        final raw = item['created_at'] as String?;
        if (raw != null) {
          final dt = DateTime.tryParse(raw);
          if (dt != null &&
              dt.isBefore(_filter.createdAt!
                  .copyWith(hour: 0, minute: 0, second: 0))) return false;
        }
      }
      if (_filter.paidAt != null) {
        final raw = item['paid_at'] as String?;
        if (raw == null) return false;
        final dt = DateTime.tryParse(raw);
        if (dt == null ||
            dt.isBefore(
                _filter.paidAt!.copyWith(hour: 0, minute: 0, second: 0))) {
          return false;
        }
      }
      if (_filter.confirmedAt != null) {
        final raw = item['confirmed_at'] as String?;
        if (raw == null) return false;
        final dt = DateTime.tryParse(raw);
        if (dt == null ||
            dt.isBefore(_filter.confirmedAt!
                .copyWith(hour: 0, minute: 0, second: 0))) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> _openFilter(AppColors colors) async {
    final result = await Navigator.of(context).push<ExpenseFilter>(
      MaterialPageRoute(
        builder: (_) => ExpenseFilterScreen(initial: _filter),
      ),
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
      backgroundColor: colors.backgroundBase,
      appBar: AppBar(
        backgroundColor: colors.backgroundBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: colors.textStrong,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => showExpenseRequestForm(context).then((_) => _load()),
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
                        IconButton(
                          icon: Icon(
                            Icons.search_rounded,
                            color: colors.iconSub,
                            size: 24,
                          ),
                          onPressed: () =>
                              setState(() => _searching = true),
                        ),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.tune_rounded,
                                color: colors.iconSub,
                                size: 24,
                              ),
                              onPressed: () => _openFilter(colors),
                            ),
                            if (_filter.isActive)
                              Positioned(
                                top: 8,
                                right: 8,
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colors.errorSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.access_time_rounded,
                  color: colors.errorSub,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Juda ko\'p so\'rov yuborildi',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: colors.textStrong,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Iltimos qayta urinib ko\'ring',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.textSub,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: colors.backgroundElevation2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.strokeSub),
                ),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$_throttleSeconds',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: colors.errorSub,
                        ),
                      ),
                      TextSpan(
                        text: ' soniya',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: colors.textSub,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: colors.errorSub, size: 48),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w500,
                color: colors.textSub,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentSub,
                foregroundColor: colors.textWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Qayta urinish',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      );
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
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ExpenseDetailScreen(id: id),
            ));
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
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      colors: colors,
                      label: 'Ism sharifi:  ',
                      value: username,
                      valueBold: true,
                    ),
                    const SizedBox(height: 2),
                    _InfoRow(
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
          _InfoRow(
            colors: colors,
            label: 'Xarajat turi:  ',
            value: categoryTitle,
            valueBold: true,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _InfoRow(
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
                      ? const Color(0xFF34C759)
                      : colors.backgroundElevation2,
                  borderRadius: BorderRadius.circular(6),
                  border: isApproved
                      ? null
                      : Border.all(color: colors.strokeStrong),
                ),
                child: isApproved
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 18)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final AppColors colors;
  final String label;
  final String value;
  final bool valueBold;

  const _InfoRow({
    required this.colors,
    required this.label,
    required this.value,
    required this.valueBold,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: colors.textSub,
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: valueBold ? FontWeight.w900 : FontWeight.w500,
              fontSize: 13,
              color: colors.textStrong,
            ),
          ),
        ],
      ),
    );
  }
}

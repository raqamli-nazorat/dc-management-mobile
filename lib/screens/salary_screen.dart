import 'dart:async';

import 'package:dcmanagement/api/api.dart';
import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/screens/salary_detail_screen.dart';
import 'package:dcmanagement/screens/salary_filter_screen.dart';
import 'package:dcmanagement/services/auth_service.dart';
import 'package:dcmanagement/widgets/app_state_widgets.dart';
import 'package:dcmanagement/widgets/info_row.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SalaryScreen extends StatefulWidget {
  const SalaryScreen({super.key});

  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen> {
  final _api = ApiService();
  final _auth = AuthService();

  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String? _error;
  bool _searching = false;
  final _searchCtrl = TextEditingController();

  SalaryFilter _filter = const SalaryFilter();

  int? _throttleSeconds;
  Timer? _throttleTimer;

  static const _monthNames = [
    'Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'Iyun',
    'Iyul', 'Avgust', 'Sentabr', 'Oktabr', 'Noyabr', 'Dekabr',
  ];

  @override
  void initState() {
    super.initState();
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
      setState(() => _throttleSeconds = (_throttleSeconds ?? 1) - 1);
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
      final data = await _api.getPayrolls(token);
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

  String _monthLabel(dynamic raw) {
    if (raw == null) return '—';
    final s = raw.toString();
    // Try parse as date string like "2024-01-01"
    final dt = DateTime.tryParse(s);
    if (dt != null) return _monthNames[dt.month - 1];
    // Try parse as month name directly
    final idx = _monthNames.indexWhere(
        (m) => m.toLowerCase() == s.toLowerCase());
    if (idx >= 0) return _monthNames[idx];
    // Try parse as month number
    final n = int.tryParse(s);
    if (n != null && n >= 1 && n <= 12) return _monthNames[n - 1];
    return s;
  }

  bool _isConfirmed(Map<String, dynamic> item) {
    final isConfirmedField = item['is_confirmed'];
    if (isConfirmedField is bool) return isConfirmedField;
    final isPaidField = item['is_paid'];
    if (isPaidField is bool) return isPaidField;
    final status = item['status'] as String? ?? '';
    return status == 'confirmed' || status == 'paid';
  }

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> list) {
    if (!_filter.isActive) return list;
    return list.where((item) {
      // month filter (string month name like "Yanvar")
      if (_filter.month != null) {
        final rawMonth = item['month'] ?? item['period'];
        final itemMonthLabel = _monthLabel(rawMonth);
        if (itemMonthLabel != _filter.month) return false;
      }
      // amount filter
      final totalRaw = item['total_amount'] ?? item['amount'] ?? item['salary'];
      final total =
          (num.tryParse(totalRaw?.toString() ?? '') ?? 0).abs().toDouble();
      if (_filter.amountMin != null && total < _filter.amountMin!) return false;
      if (_filter.amountMax != null && total > _filter.amountMax!) return false;
      // date filter
      if (_filter.createdAtFrom != null || _filter.createdAtTo != null) {
        final raw = item['created_at'] as String?;
        final dt = raw != null ? DateTime.tryParse(raw) : null;
        if (dt == null) return false;
        if (_filter.createdAtFrom != null &&
            dt.isBefore(
                _filter.createdAtFrom!.copyWith(hour: 0, minute: 0, second: 0))) {
          return false;
        }
        if (_filter.createdAtTo != null &&
            dt.isAfter(
                _filter.createdAtTo!.copyWith(hour: 23, minute: 59, second: 59))) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _applySearch(String q) {
    final query = q.toLowerCase();
    setState(() {
      _filtered = _all.where((item) {
        final user = item['user_info'] as Map<String, dynamic>? ?? {};
        final username = (user['username'] as String? ?? '').toLowerCase();
        return username.contains(query);
      }).toList();
    });
  }

  Future<void> _openFilter() async {
    final result = await Navigator.of(context).push<SalaryFilter>(
      MaterialPageRoute(
          builder: (_) => SalaryFilterScreen(initial: _filter)),
    );
    if (result != null && mounted) {
      setState(() {
        _filter = result;
        _filtered = _applyFilter(_all);
      });
    }
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
          icon: Icon(Icons.arrow_back_rounded, color: colors.textStrong),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
                            fontFamily: 'Manrope', color: colors.textSoft),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.close, color: colors.iconSub),
                          onPressed: () => setState(() {
                            _searching = false;
                            _searchCtrl.clear();
                            _filtered = _applyFilter(_all);
                          }),
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
                            horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: colors.backgroundElevation1,
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Ish haqi',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: colors.textStrong,
                            ),
                          ),
                        ),
                        _ActionBtn(
                          icon: LucideIcons.search,
                          colors: colors,
                          onTap: () => setState(() => _searching = true),
                        ),
                        const SizedBox(width: 10),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _ActionBtn(
                              icon: LucideIcons.filter,
                              colors: colors,
                              onTap: _openFilter,
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
      return Center(
          child: CircularProgressIndicator(color: colors.accentSub));
    }
    if (_throttleSeconds != null) {
      return ThrottleCountdown(seconds: _throttleSeconds!, colors: colors);
    }
    if (_error != null) {
      return ErrorRetry(message: _error!, onRetry: _load, colors: colors);
    }
    if (_filtered.isEmpty) {
      return RefreshIndicator(
        color: colors.accentSub,
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: colors.backgroundElevation2,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.payments_outlined,
                        size: 36, color: colors.iconSoft),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Ma'lumot topilmadi",
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: colors.textStrong,
                    ),
                  ),
                ],
              ),
            ),
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
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = _filtered[index];
          final rawMonth = item['month'] ?? item['period'];
          final monthLabel = _monthLabel(rawMonth);
          final isConfirmedItem = _isConfirmed(item);
          return GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SalaryDetailScreen(
                  item: item,
                  monthLabel: monthLabel,
                ),
              ),
            ),
            child: _SalaryCard(
              item: item,
              monthLabel: monthLabel,
              isPaid: isConfirmedItem,
              colors: colors,
            ),
          );
        },
      ),
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _SalaryCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String monthLabel;
  final bool isPaid;
  final AppColors colors;

  const _SalaryCard({
    required this.item,
    required this.monthLabel,
    required this.isPaid,
    required this.colors,
  });

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
    final username = user['username'] as String? ?? '—';
    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';
    final avatarColor = _avatarColor(username);

    final kpiRaw = item['kpi_bonus'] ?? item['bonus'] ?? item['kpi'];
    final totalRaw =
        item['total_amount'] ?? item['amount'] ?? item['salary'];

    final kpiBonus = _formatAmount(kpiRaw);
    final totalAmount = _formatAmount(totalRaw);

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
                    color: avatarColor,
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
                      label: 'Oy:  ',
                      value: monthLabel,
                      valueBold: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          InfoRow(
            colors: colors,
            label: 'KPI bonus:  ',
            value: kpiBonus,
            valueBold: true,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: InfoRow(
                  colors: colors,
                  label: 'Jami miqdori:  ',
                  value: totalAmount,
                  valueBold: true,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isPaid
                      ? colors.successStrong
                      : colors.backgroundElevation2,
                  borderRadius: BorderRadius.circular(6),
                  border: isPaid
                      ? null
                      : Border.all(color: colors.strokeStrong),
                ),
                child: isPaid
                    ? Icon(Icons.check_rounded,
                        color: colors.white, size: 18)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final AppColors colors;

  const _ActionBtn({
    required this.icon,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colors.backgroundElevation1,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.strokeSub),
        ),
        child: Icon(icon, color: colors.iconSub, size: 20),
      ),
    );
  }
}

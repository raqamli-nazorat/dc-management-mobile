import 'dart:async';

import 'package:dcmanagement/api/api.dart';
import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  int? _throttleSeconds;
  Timer? _throttleTimer;

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
        _filtered = data;
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

  void _applySearch(String q) {
    final query = q.toLowerCase();
    setState(() {
      _filtered = _all.where((item) {
        final user = item['user_info'] as Map<String, dynamic>? ?? {};
        final username = (user['username'] as String? ?? '').toLowerCase();
        final month = (item['month_display'] as String? ?? '').toLowerCase();
        return username.contains(query) || month.contains(query);
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
                            _filtered = _all;
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
                        IconButton(
                          icon: Icon(Icons.search_rounded,
                              color: colors.iconSub, size: 24),
                          onPressed: () =>
                              setState(() => _searching = true),
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
                child: Icon(Icons.access_time_rounded,
                    color: colors.errorSub, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                "Juda ko'p so'rov yuborildi",
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
                "Iltimos qayta urinib ko'ring",
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
                    horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: colors.backgroundElevation2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.strokeSub),
                ),
                child: RichText(
                  text: TextSpan(children: [
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
                  ]),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  color: colors.errorSub, size: 48),
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
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text(
                  'Qayta urinish',
                  style: TextStyle(
                      fontFamily: 'Manrope', fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      );
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
                    "Hozircha ish haqlari yo'q",
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
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) =>
            _PayrollCard(item: _filtered[index], colors: colors),
      ),
    );
  }
}

// ── Payroll Card ──────────────────────────────────────────────────────────────

class _PayrollCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final AppColors colors;

  const _PayrollCard({required this.item, required this.colors});

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

  String _fmt(dynamic raw) {
    final num value = num.tryParse(raw?.toString() ?? '') ?? 0;
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return formatter
        .format(value.abs())
        .replaceAll(',', ' ')
        .replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    final user = item['user_info'] as Map<String, dynamic>? ?? {};
    final username = user['username'] as String? ?? '—';
    final monthDisplay = item['month_display'] as String? ?? '—';
    final isConfirmed = item['is_confirmed'] as bool? ?? false;
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
          // Top: avatar + ism/oy
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
                    _InfoRow(
                      colors: colors,
                      label: 'Ism sharifi:  ',
                      value: username,
                    ),
                    const SizedBox(height: 2),
                    _InfoRow(
                      colors: colors,
                      label: 'Oy:  ',
                      value: monthDisplay,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // KPI bonus
          _InfoRow(
            colors: colors,
            label: 'KPI bonus:  ',
            value: _fmt(item['kpi_bonus']),
          ),
          const SizedBox(height: 4),

          // Jami miqdori + checkbox
          Row(
            children: [
              Expanded(
                child: _InfoRow(
                  colors: colors,
                  label: 'Jami miqdori:  ',
                  value: _fmt(item['total_amount']),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isConfirmed
                      ? const Color(0xFF34C759)
                      : colors.backgroundElevation2,
                  borderRadius: BorderRadius.circular(6),
                  border: isConfirmed
                      ? null
                      : Border.all(color: colors.strokeStrong),
                ),
                child: isConfirmed
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

// ─────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final AppColors colors;
  final String label;
  final String value;

  const _InfoRow({
    required this.colors,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => RichText(
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
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: colors.textStrong,
              ),
            ),
          ],
        ),
      );
}

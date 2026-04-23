import 'dart:async';

import 'package:dcmanagement/api/api.dart';
import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/screens/expense_detail_screen.dart';
import 'package:dcmanagement/services/auth_service.dart';
import 'package:dcmanagement/widgets/app_state_widgets.dart';
import 'package:dcmanagement/widgets/info_row.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class WorkerMyRequestsScreen extends StatefulWidget {
  const WorkerMyRequestsScreen({super.key});

  @override
  State<WorkerMyRequestsScreen> createState() =>
      _WorkerMyRequestsScreenState();
}

class _WorkerMyRequestsScreenState extends State<WorkerMyRequestsScreen> {
  final _api = ApiService();
  final _auth = AuthService();

  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  int? _throttleSeconds;
  Timer? _throttleTimer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _throttleTimer?.cancel();
    super.dispose();
  }

  int? _parseThrottleSeconds(String msg) {
    final match = RegExp(r'(\d+)\s+second').firstMatch(msg);
    return match != null ? int.tryParse(match.group(1)!) : null;
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
      final data = await _api.getMyExpenseRequests(token);
      setState(() {
        _items = data;
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

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.backgroundBase,
      appBar: AppBar(
        backgroundColor: colors.backgroundBase,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await context
                    .push<bool>('/finance/expense-request-form');
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
              child: Text(
                "Mening so'rovlarim",
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: colors.textStrong,
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
    if (_throttleSeconds != null) {
      return ThrottleCountdown(seconds: _throttleSeconds!, colors: colors);
    }
    if (_error != null) {
      return ErrorRetry(message: _error!, onRetry: _load, colors: colors);
    }
    if (_items.isEmpty) {
      return Center(
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
              child: Icon(
                Icons.inbox_outlined,
                size: 36,
                color: colors.iconSoft,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "So'rovlar mavjud emas",
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.textStrong,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Yangi so'rov yuborish uchun yuqoridagi tugmani bosing",
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                color: colors.textSoft,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: colors.accentSub,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => GestureDetector(
          onTap: () {
            final id = _items[index]['id'] as int?;
            if (id == null) return;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    ExpenseDetailScreen(id: id, canDelete: true),
              ),
            );
          },
          child: _RequestCard(item: _items[index], colors: colors),
        ),
      ),
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final AppColors colors;

  const _RequestCard({required this.item, required this.colors});

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

  String _categoryLabel(Map<String, dynamic> item) {
    final category = item['expense_category_info'] as Map<String, dynamic>?;
    if (category != null && (category['title'] as String?)?.isNotEmpty == true) {
      return category['title'] as String;
    }
    const typeMap = {
      'withdrawal': "Mablag' chiqarish",
      'expense': 'Xarajat',
      'income': 'Daromad',
    };
    final type = item['type'] as String? ?? '';
    return typeMap[type] ?? type;
  }

  @override
  Widget build(BuildContext context) {
    final user = item['user_info'] as Map<String, dynamic>? ?? {};
    final project = item['project_info'] as Map<String, dynamic>? ?? {};

    final username = user['username'] as String? ?? '—';
    final projectTitle = project['title'] as String? ?? '';
    final categoryTitle = _categoryLabel(item);
    final amount = _formatAmount(item['amount']);
    final status = item['status'] as String? ?? 'pending';

    final isPaid = status == 'paid' || item['paid_at'] != null;
    final isConfirmed =
        status == 'confirmed' || status == 'paid' || item['confirmed_at'] != null;

    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';
    final avatarBgColor = _avatarColor(username);

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
                    color: avatarBgColor,
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
                      label: 'Loyiha:  ',
                      value: projectTitle,
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
            label: 'Xarajat turi:  ',
            value: categoryTitle,
            valueBold: true,
          ),
          const SizedBox(height: 4),
          InfoRow(
            colors: colors,
            label: 'Summasi:  ',
            value: amount,
            valueBold: true,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _CheckRow(
                label: "To'lov yuborildi:",
                checked: isPaid,
                colors: colors,
              ),
              const Spacer(),
              _CheckRow(
                label: 'Qabul qilindi:',
                checked: isConfirmed,
                colors: colors,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String label;
  final bool checked;
  final AppColors colors;

  const _CheckRow({
    required this.label,
    required this.checked,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colors.textSub,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: checked ? colors.successStrong : colors.backgroundElevation2,
            borderRadius: BorderRadius.circular(6),
            border: checked ? null : Border.all(color: colors.strokeStrong),
          ),
          child: checked
              ? Icon(Icons.check_rounded, color: colors.white, size: 16)
              : null,
        ),
      ],
    );
  }
}


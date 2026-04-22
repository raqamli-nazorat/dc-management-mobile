import 'dart:async';
import 'dart:convert';

import 'package:dcmanagement/api/api.dart';
import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/screens/expense_detail_screen.dart';
import 'package:dcmanagement/services/auth_service.dart';
import 'package:dcmanagement/services/storage_service.dart';
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
  int? _currentUserId;

  int? _throttleSeconds;
  Timer? _throttleTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _throttleTimer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    final raw = await StorageService().getString(StorageService.userKey);
    if (raw != null) {
      try {
        final user = jsonDecode(raw) as Map<String, dynamic>;
        _currentUserId = user['id'] as int?;
      } catch (_) {}
    }
    await _load();
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
      final all = await _api.getExpenseRequests(token);
      final filtered = _currentUserId == null
          ? all
          : all.where((item) {
              final userInfo =
                  item['user_info'] as Map<String, dynamic>? ?? {};
              return userInfo['id'] == _currentUserId;
            }).toList();
      setState(() {
        _items = filtered;
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
      backgroundColor: colors.backgroundElevation1Alt,
      appBar: AppBar(
        backgroundColor: colors.backgroundElevation1Alt,
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
                  builder: (_) => ExpenseDetailScreen(id: id)),
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

  String _formatAmount(dynamic raw) {
    final num value = num.tryParse(raw?.toString() ?? '') ?? 0;
    final formatter = NumberFormat('#,##0.00', 'uz_UZ');
    return formatter
        .format(value.abs())
        .replaceAll(',', ' ')
        .replaceAll('.', ',');
  }

  String _formatDate(String? raw) {
    if (raw == null) return '—';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('dd.MM.yyyy  HH:mm').format(dt);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final project = item['project_info'] as Map<String, dynamic>? ?? {};
    final category =
        item['expense_category_info'] as Map<String, dynamic>? ?? {};

    final projectTitle = project['title'] as String? ?? '—';
    final categoryTitle = category['title'] as String? ?? '—';
    final amount = _formatAmount(item['amount']);
    final status = item['status'] as String? ?? 'pending';
    final createdAt = _formatDate(item['created_at'] as String?);

    final isApproved = status == 'confirmed' || status == 'paid';
    final isPaid = status == 'paid';

    Color statusColor;
    String statusLabel;
    if (isPaid) {
      statusColor = colors.successStrong;
      statusLabel = "To'landi";
    } else if (isApproved) {
      statusColor = colors.accentSub;
      statusLabel = 'Tasdiqlandi';
    } else {
      statusColor = colors.textSoft;
      statusLabel = 'Kutilmoqda';
    }

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
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InfoRow(
                      colors: colors,
                      label: 'Loyiha: ',
                      value: projectTitle,
                      valueBold: true,
                    ),
                    const SizedBox(height: 2),
                    InfoRow(
                      colors: colors,
                      label: 'Xarajat turi: ',
                      value: categoryTitle,
                      valueBold: true,
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InfoRow(
                  colors: colors,
                  label: 'Summa: ',
                  value: amount,
                  valueBold: true,
                ),
              ),
              Text(
                createdAt,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 11,
                  color: colors.textSoft,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

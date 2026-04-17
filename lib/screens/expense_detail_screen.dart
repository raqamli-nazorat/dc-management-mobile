import 'package:dcmanagement/api/api.dart';
import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpenseDetailScreen extends StatefulWidget {
  final int id;
  const ExpenseDetailScreen({super.key, required this.id});

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  final _api = ApiService();
  final _auth = AuthService();
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final token = await _auth.getToken();
      if (token == null) throw Exception('Token topilmadi');
      final data = await _api.getExpenseRequestDetail(token, widget.id);
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
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

  String _formatAmount(dynamic raw) {
    final num value = num.tryParse(raw?.toString() ?? '') ?? 0;
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return formatter
        .format(value.abs())
        .replaceAll(',', ' ')
        .replaceAll('.', ',');
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
        title: Text(
          "Foydalanuvchining ma'lumotlari",
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: colors.textStrong,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(colors),
    );
  }

  Widget _buildBody(AppColors colors) {
    if (_loading) {
      return Center(
          child: CircularProgressIndicator(color: colors.accentSub));
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
    if (_data == null) return const SizedBox();

    final user = _data!['user_info'] as Map<String, dynamic>? ?? {};
    final project = _data!['project_info'] as Map<String, dynamic>? ?? {};
    final category =
        _data!['expense_category_info'] as Map<String, dynamic>? ?? {};
    final avatarUrl = user['avatar'] as String?;
    final username = user['username'] as String? ?? '—';
    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Center(
            child: Container(
              width: 90,
              height: 90,
              margin: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: colors.backgroundElevation3,
              ),
              clipBehavior: Clip.antiAlias,
              child: (avatarUrl != null &&
                      (avatarUrl.startsWith('http://') ||
                          avatarUrl.startsWith('https://')))
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context2, err, st) =>
                          _InitialAvatar(initial: initial, colors: colors),
                    )
                  : _InitialAvatar(initial: initial, colors: colors),
            ),
          ),

          _InfoField(
              label: 'Ism Sharifi', value: username, colors: colors),
          const SizedBox(height: 12),
          _InfoField(
              label: 'Loyiha',
              value: project['title'] as String? ?? '—',
              colors: colors),
          const SizedBox(height: 12),
          _InfoField(
              label: 'Xarajat turi',
              value: category['title'] as String? ?? '—',
              colors: colors),
          const SizedBox(height: 12),
          _InfoField(
              label: 'Summa',
              value: _formatAmount(_data!['amount']),
              colors: colors),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _InfoField(
                  label: 'Yaratilgan vaqt',
                  value: _formatDate(_data!['created_at'] as String?),
                  colors: colors,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoField(
                  label: "To'langan vaqt",
                  value: _formatDate(_data!['paid_at'] as String?),
                  colors: colors,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoField(
            label: 'Tastiqlangan vaqt',
            value: _formatDate(_data!['confirmed_at'] as String?),
            colors: colors,
          ),
        ],
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  final String initial;
  final AppColors colors;
  const _InitialAvatar({required this.initial, required this.colors});

  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          initial,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w900,
            fontSize: 32,
            color: colors.accentSub,
          ),
        ),
      );
}

class _InfoField extends StatelessWidget {
  final String label;
  final String value;
  final AppColors colors;
  const _InfoField(
      {required this.label, required this.value, required this.colors});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: colors.backgroundElevation1,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.strokeSub),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.textStrong,
              ),
            ),
          ),
        ],
      );
}

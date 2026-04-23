import 'package:dcmanagement/api/api.dart';
import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/screens/expense_request_edit_screen.dart';
import 'package:dcmanagement/services/auth_service.dart';
import 'package:dcmanagement/services/role_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpenseDetailScreen extends StatefulWidget {
  final int id;
  final bool canDelete;
  const ExpenseDetailScreen({super.key, required this.id, this.canDelete = false});

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  final _api = ApiService();
  final _auth = AuthService();
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await _auth.getToken();
      if (token == null) throw Exception('Token topilmadi');
      final data = await _api.getExpenseRequestDetail(token, widget.id);
      setState(() {
        _data = data;
        _confirmed = (data['status'] as String?) == 'confirmed' ||
            (data['status'] as String?) == 'paid';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _confirmRequest() async {
    try {
      final token = await _auth.getToken();
      if (token == null) throw Exception('Token topilmadi');
      await _api.confirmExpenseRequest(token, widget.id);
      setState(() => _confirmed = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
            style: const TextStyle(fontFamily: 'Manrope'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteRequest() async {
    try {
      final token = await _auth.getToken();
      if (token == null) throw Exception('Token topilmadi');
      await _api.deleteExpenseRequest(token, widget.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString(),
              style: const TextStyle(fontFamily: 'Manrope')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showDeleteModal(AppColors colors) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => _DeleteModal(colors: colors),
    );
    if (confirmed == true && mounted) await _deleteRequest();
  }

  Future<void> _showConfirmModal(AppColors colors) async {
    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => _ConfirmModal(
        colors: colors,
        onConfirm: () async {
          Navigator.of(ctx).pop();
          await _confirmRequest();
        },
      ),
    );
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

  bool get _isManager => RoleService.instance.group == 'manager';

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
          "So'rov ma'lumotlari",
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: colors.textStrong,
          ),
        ),
        centerTitle: true,
        actions: [
          if (widget.canDelete)
            IconButton(
              icon: Icon(Icons.close_rounded, color: colors.errorSub),
              onPressed: () => _showDeleteModal(colors),
            ),
        ],
      ),
      body: _buildBody(colors),
      bottomNavigationBar: _buildBottomBar(colors),
    );
  }

  Widget? _buildBottomBar(AppColors colors) {
    if (_loading || _error != null || _data == null) return null;

    final status = _data!['status'] as String? ?? 'pending';
    final isPaid = status == 'paid' || _data!['paid_at'] != null;
    final isConfirmed = status == 'confirmed' || status == 'paid' ||
        _data!['confirmed_at'] != null;

    // Worker's own request panel
    if (widget.canDelete) {
      final isDone = isPaid && isConfirmed;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isDone
                  ? null
                  : () async {
                      final result = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => ExpenseRequestEditScreen(
                              initialData: _data!),
                        ),
                      );
                      if (result == true && mounted) _load();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDone ? colors.successStrong : colors.accentSub,
                foregroundColor: colors.white,
                disabledBackgroundColor: colors.successStrong,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                isDone ? 'Tasdiqlangan' : 'Tahrirlash',
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Manager confirm panel
    if (!_isManager) return null;
    if (_confirmed) return null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => _showConfirmModal(colors),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.successStrong,
              foregroundColor: colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text(
              'Tasdiqlash',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
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
    final category =
        _data!['expense_category_info'] as Map<String, dynamic>? ?? {};
    final avatarUrl = user['avatar'] as String?;
    final username = user['username'] as String? ?? '—';
    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';

    const typeMap = {
      'withdrawal': "Mablag' chiqarish",
      'expense': 'Xarajat',
      'income': 'Daromad',
    };
    final type = _data!['type'] as String? ?? '';
    final toifa = typeMap[type] ?? type;

    final status = _data!['status'] as String? ?? 'pending';
    final isPaid = status == 'paid' || _data!['paid_at'] != null;
    final isConfirmed =
        status == 'confirmed' || status == 'paid' || _data!['confirmed_at'] != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      errorBuilder: (_, __, ___) =>
                          _InitialAvatar(initial: initial, colors: colors),
                    )
                  : _InitialAvatar(initial: initial, colors: colors),
            ),
          ),

          _InfoField(label: 'Ism Sharifi', value: username, colors: colors),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InfoField(
                  label: 'Xarajat turi',
                  value: category['title'] as String? ?? '—',
                  colors: colors,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoField(
                  label: 'Toifa',
                  value: toifa.isEmpty ? '—' : toifa,
                  colors: colors,
                ),
              ),
            ],
          ),
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
            label: 'Tasdiqlangan vaqt',
            value: _formatDate(_data!['confirmed_at'] as String?),
            colors: colors,
          ),
          const SizedBox(height: 20),
          _StatusRow(
            label: "To'lov yuborildi:",
            checked: isPaid,
            checkedLabel: 'Tasdiqlangan',
            uncheckedLabel: 'Tasdiqlanmagan',
            colors: colors,
          ),
          const SizedBox(height: 12),
          _StatusRow(
            label: 'Qabul qilindi:',
            checked: isConfirmed,
            checkedLabel: 'Tasdiqlangan',
            uncheckedLabel: 'Tasdiqlash',
            colors: colors,
          ),
        ],
      ),
    );
  }
}

// ── Confirm Modal ─────────────────────────────────────────────────────────────

class _ConfirmModal extends StatelessWidget {
  final AppColors colors;
  final VoidCallback onConfirm;

  const _ConfirmModal({required this.colors, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: colors.backgroundElevation1,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.successStrong.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              color: colors.successStrong,
              size: 26,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Ish haqqini tasdiqlaysizmi?",
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colors.textStrong,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Tasdiqlangandan so'ng bu amalni bekor qilib bo'lmaydi",
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colors.textSub,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // Bekor qilish
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.strokeSub),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.close_rounded,
                            color: colors.textSub, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Bekor qilish',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.textSub,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Tasdiqlash
              Expanded(
                child: GestureDetector(
                  onTap: onConfirm,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: colors.successStrong,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_rounded,
                            color: colors.white, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Tasdiqlash',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

// ── Delete Modal ─────────────────────────────────────────────────────────────

class _DeleteModal extends StatelessWidget {
  final AppColors colors;
  const _DeleteModal({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
        decoration: BoxDecoration(
          color: colors.backgroundElevation1,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.errorSub.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.delete_outline_rounded,
                  color: colors.errorSub, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              "So'rovni o'chirish",
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.textStrong,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Bu so'rov o'chiriladi va uni qayta tiklash mumkin bo'lmaydi",
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.textSub,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(false),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.strokeSub),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.close_rounded,
                              color: colors.textSub, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Bekor qilish',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colors.textSub,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(true),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: colors.errorSub,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_rounded,
                              color: colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            "O'chirish",
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status Row ────────────────────────────────────────────────────────────────

class _StatusRow extends StatelessWidget {
  final String label;
  final bool checked;
  final String checkedLabel;
  final String uncheckedLabel;
  final AppColors colors;

  const _StatusRow({
    required this.label,
    required this.checked,
    required this.checkedLabel,
    required this.uncheckedLabel,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colors.textSub,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          checked ? checkedLabel : uncheckedLabel,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: checked ? colors.successStrong : colors.textStrong,
          ),
        ),
        const Spacer(),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: checked ? colors.successStrong : colors.backgroundElevation2,
            borderRadius: BorderRadius.circular(7),
            border: checked ? null : Border.all(color: colors.strokeStrong),
          ),
          child: checked
              ? Icon(Icons.check_rounded, color: colors.white, size: 18)
              : null,
        ),
      ],
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

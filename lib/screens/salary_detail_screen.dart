import 'package:dcmanagement/api/api.dart';
import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/services/auth_service.dart';
import 'package:dcmanagement/services/role_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SalaryDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  final String? monthLabel;
  const SalaryDetailScreen({super.key, required this.item, this.monthLabel});

  @override
  State<SalaryDetailScreen> createState() => _SalaryDetailScreenState();
}

class _SalaryDetailScreenState extends State<SalaryDetailScreen> {
  final _api = ApiService();
  final _auth = AuthService();
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    _confirmed = _isPaid(widget.item);
  }

  bool _isPaid(Map<String, dynamic> item) {
    final isConfirmedField = item['is_confirmed'];
    if (isConfirmedField is bool) return isConfirmedField;
    final isPaidField = item['is_paid'];
    if (isPaidField is bool) return isPaidField;
    final status = item['status'] as String? ?? '';
    return status == 'confirmed' || status == 'paid';
  }

  bool get _isSuperAdmin =>
      RoleService.instance.role?.toLowerCase() == 'superadmin';

  String _fmt(dynamic raw) {
    final v = num.tryParse(raw?.toString() ?? '') ?? 0;
    final s = v.abs().toStringAsFixed(2).replaceAll('.', ',');
    final parts = s.split(',');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ',
    );
    return '$intPart,${parts[1]}';
  }

  String _fmtDate(dynamic raw) {
    if (raw == null) return '—';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      return DateFormat('dd.MM.yyyy').format(dt);
    } catch (_) {
      return raw.toString();
    }
  }

  Future<void> _confirmPayroll() async {
    final id = widget.item['id'];
    if (id == null) return;
    try {
      final token = await _auth.getToken();
      if (token == null) throw Exception('Token topilmadi');
      await _api.confirmPayroll(token, id as int);
      if (mounted) setState(() => _confirmed = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
            style: const TextStyle(fontFamily: 'Manrope'),
          ),
          backgroundColor: AppColors.of(context).errorSub,
        ),
      );
    }
  }

  Future<void> _showConfirmModal(AppColors colors) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _ConfirmModal(
        colors: colors,
        onConfirm: () async {
          Navigator.of(ctx).pop();
          await _confirmPayroll();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final user = widget.item['user_info'] as Map<String, dynamic>? ?? {};
    final username = user['username'] as String? ?? '—';
    final avatarUrl = user['avatar'] as String?;
    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';
    final jarima = num.tryParse(widget.item['penalty']?.toString() ?? '') ?? 0;

    final displayMonth = widget.monthLabel ??
        widget.item['month_display'] as String? ??
        widget.item['month'] as String? ??
        '—';

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
          "Ish haqi ma'lumotlari",
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.textStrong,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
                          ? Image.network(avatarUrl, fit: BoxFit.cover,
                              errorBuilder: (_, e, st) => _InitialAvatar(
                                  initial: initial, colors: colors))
                          : _InitialAvatar(initial: initial, colors: colors),
                    ),
                  ),

                  _Field(
                      label: 'Ism Sharifi', value: username, colors: colors),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _Field(
                          label: 'Oy',
                          value: displayMonth,
                          colors: colors,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Field(
                          label: 'Oylik maosh',
                          value: _fmt(widget.item['base_salary']),
                          colors: colors,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _Field(
                          label: 'KPI bonus',
                          value: _fmt(widget.item['kpi_bonus']),
                          colors: colors,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Field(
                          label: 'Jarima miqdori',
                          value:
                              jarima != 0 ? '-${_fmt(jarima)}' : '0,00',
                          colors: colors,
                          valueColor: jarima != 0 ? colors.errorSub : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _Field(
                    label: 'Jami miqdori',
                    value: _fmt(widget.item['total_amount']),
                    colors: colors,
                  ),
                  const SizedBox(height: 12),

                  _Field(
                    label: 'Yaratilgan vaqt',
                    value: _fmtDate(widget.item['created_at']),
                    colors: colors,
                  ),
                ],
              ),
            ),
          ),

          // Bottom bar
          _buildBottomBar(colors),
        ],
      ),
    );
  }

  Widget _buildBottomBar(AppColors colors) {
    // Tasdiqlangan: outline tugma (hammaga ko'rinadi)
    if (_confirmed) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: null,
            icon: Icon(Icons.check_rounded,
                color: colors.successStrong, size: 20),
            label: Text(
              'Tasdiqlangan',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: colors.successStrong,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colors.successStrong, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
          ),
        ),
      );
    }

    // Faqat superadmin uchun: faol "Tasdiqlash" tugma
    if (_isSuperAdmin) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showConfirmModal(AppColors.of(context)),
            icon: Icon(Icons.check_rounded,
                color: colors.white, size: 20),
            label: Text(
              'Tasdiqlash',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.successStrong,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(vertical: 18),
              elevation: 0,
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

// ── Confirm Modal ─────────────────────────────────────────────────────────────

class _ConfirmModal extends StatelessWidget {
  final AppColors colors;
  final VoidCallback onConfirm;

  const _ConfirmModal({required this.colors, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: colors.backgroundElevation1,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: colors.strokeStrong,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Ish haqini tasdiqlaysizmi?',
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

class _Field extends StatelessWidget {
  final String label;
  final String value;
  final AppColors colors;
  final Color? valueColor;
  const _Field({
    required this.label,
    required this.value,
    required this.colors,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
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
                color: valueColor ?? colors.textStrong,
              ),
            ),
          ),
        ],
      );
}

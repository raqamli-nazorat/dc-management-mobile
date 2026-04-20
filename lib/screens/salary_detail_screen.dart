import 'package:dcmanagement/colors/app_colors.dart';
import 'package:flutter/material.dart';

class SalaryDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;
  const SalaryDetailScreen({super.key, required this.item});

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

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final user = item['user_info'] as Map<String, dynamic>? ?? {};
    final username = user['username'] as String? ?? '—';
    final avatarUrl = user['avatar'] as String?;
    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';
    final jarima = num.tryParse(item['penalty']?.toString() ?? '') ?? 0;

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
                          ? Image.network(avatarUrl, fit: BoxFit.cover,
                              errorBuilder: (_, e, st) =>
                                  _InitialAvatar(initial: initial, colors: colors))
                          : _InitialAvatar(initial: initial, colors: colors),
                    ),
                  ),

                  _Field(label: 'Ism Sharifi', value: username, colors: colors),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _Field(
                          label: 'Oy',
                          value: item['month_display'] as String? ?? '—',
                          colors: colors,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Field(
                          label: 'Oylik maosh',
                          value: _fmt(item['base_salary']),
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
                          value: _fmt(item['kpi_bonus']),
                          colors: colors,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Field(
                          label: 'Jarima miqdori',
                          value: jarima != 0 ? '-${_fmt(jarima)}' : '0,00',
                          colors: colors,
                          valueColor: jarima != 0
                              ? const Color(0xFFEF4444)
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _Field(
                    label: 'Jami miqdori',
                    value: _fmt(item['total_amount']),
                    colors: colors,
                  ),
                  const SizedBox(height: 12),

                  _Field(
                    label: 'Yaratilgan vaqt',
                    value: item['created_at'] as String? ?? '—',
                    colors: colors,
                  ),
                ],
              ),
            ),
          ),

          // Tasdiqlash button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                label: const Text(
                  'Tasdiqlash',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF34C759),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  elevation: 0,
                ),
              ),
            ),
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
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF292A2A)),
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

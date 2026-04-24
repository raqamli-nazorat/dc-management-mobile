import 'package:dcmanagement/api/api.dart';
import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/services/auth_service.dart';
import 'package:dcmanagement/services/role_service.dart';
import 'package:dcmanagement/widgets/app_state_widgets.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  final _api = ApiService();
  final _auth = AuthService();

  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String? _error;
  bool _searching = false;
  final _searchCtrl = TextEditingController();
  String? _statusFilter;

  static const _statuses = [
    (null, 'Barchasi'),
    ('planning', 'Rejalashtirilmoqda'),
    ('active', 'Faol'),
    ('overdue', "Muddati o'tgan"),
    ('completed', 'Yakunlangan'),
    ('cancelled', 'Bekor qilingan'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await _auth.getToken();
      if (token == null) throw Exception('Token topilmadi');
      final data = await _api.getProjects(token);
      if (mounted) {
        setState(() {
          _all = data;
          _filtered = _applyFilter(data);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> list) {
    var result = list;
    if (_statusFilter != null) {
      result =
          result.where((p) => p['status'] == _statusFilter).toList();
    }
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((p) {
        final title = (p['title'] as String? ?? '').toLowerCase();
        final desc = (p['description'] as String? ?? '').toLowerCase();
        return title.contains(q) || desc.contains(q);
      }).toList();
    }
    return result;
  }

  void _onSearch(String q) {
    setState(() => _filtered = _applyFilter(_all));
  }

  void _setStatus(String? val) {
    setState(() {
      _statusFilter = val;
      _filtered = _applyFilter(_all);
    });
  }

  bool get _canCreate =>
      RoleService.instance.isAdmin || RoleService.instance.isManager;

  String get _currentStatusLabel {
    for (final (val, lbl) in _statuses) {
      if (val == _statusFilter) return lbl;
    }
    return 'Barchasi';
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
        actions: [
          if (_canCreate)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: create project screen
                },
                iconAlignment: IconAlignment.end,
                label: const Text(
                  "Loyiha qo'shish",
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                icon: const Icon(Icons.add_box_outlined, size: 18),
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
                      onChanged: _onSearch,
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
                          onPressed: () {
                            setState(() {
                              _searching = false;
                              _searchCtrl.clear();
                              _filtered = _applyFilter(_all);
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
                            horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: colors.backgroundElevation1,
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Loyihalar',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: colors.textStrong,
                            ),
                          ),
                        ),
                        _IconBtn(
                          icon: Icons.search_rounded,
                          colors: colors,
                          onTap: () => setState(() => _searching = true),
                        ),
                        const SizedBox(width: 8),
                        _StatusDropdown(
                          label: _currentStatusLabel,
                          colors: colors,
                          statuses: _statuses,
                          selected: _statusFilter,
                          onSelect: _setStatus,
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
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Text(
                "Loyihalar mavjud emas",
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w500,
                  color: colors.textSoft,
                ),
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
        itemBuilder: (context, i) => _ProjectCard(
          item: _filtered[i],
          colors: colors,
          onTap: () => context.push(
            '/projects/tasks',
            extra: {'project': _filtered[i]},
          ),
        ),
      ),
    );
  }
}

// ── Project Card ──────────────────────────────────────────────────────────────

class _ProjectCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final AppColors colors;
  final VoidCallback onTap;

  const _ProjectCard({
    required this.item,
    required this.colors,
    required this.onTap,
  });

  static const _statusMap = {
    'planning': ('Rejalashtirilmoqda', Color(0xFF7C6AF7)),
    'active': ('Faol', Color(0xFF27AE60)),
    'overdue': ("Muddati o'tgan", Color(0xFFE74C3C)),
    'completed': ('Yakunlangan', Color(0xFF2ECC71)),
    'cancelled': ('Bekor qilingan', Color(0xFF95A5A6)),
  };

  String _formatDate(String? raw) {
    if (raw == null) return '—';
    try {
      return DateFormat('dd.MM.yyyy').format(DateTime.parse(raw).toLocal());
    } catch (_) {
      return raw;
    }
  }

  double? _parsePercent(dynamic raw) {
    if (raw == null) return null;
    return double.tryParse(raw.toString());
  }

  @override
  Widget build(BuildContext context) {
    final title = item['title'] as String? ?? '—';
    final description = item['description'] as String? ?? '';
    final status = item['status'] as String? ?? 'planning';
    final deadline = _formatDate(item['deadline'] as String?);
    final percent = _parsePercent(item['completion_percentage']);

    final manager =
        item['manager_info'] as Map<String, dynamic>? ?? {};
    final managerName = manager['username'] as String? ?? '';

    final employees =
        (item['employees_info'] as List? ?? []).length;
    final testers = (item['testers_info'] as List? ?? []).length;

    final (statusLabel, statusColor) =
        _statusMap[status] ?? ('Noma\'lum', const Color(0xFF95A5A6));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.backgroundElevation1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.strokeSub),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sarlavha + holat
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: colors.textStrong,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
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

            if (description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: colors.textSub,
                ),
              ),
            ],

            // Progress bar
            if (percent != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (percent / 100).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor:
                            colors.strokeSub.withValues(alpha: 0.4),
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${percent.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 10),

            // Muddat + mas'ul + xodimlar soni
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 13, color: colors.iconSub),
                const SizedBox(width: 4),
                Text(
                  deadline,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colors.textSub,
                  ),
                ),
                if (managerName.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.person_outline_rounded,
                      size: 13, color: colors.iconSub),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      managerName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colors.textSub,
                      ),
                    ),
                  ),
                ] else
                  const Spacer(),
                if (employees > 0 || testers > 0) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.group_outlined,
                      size: 13, color: colors.iconSub),
                  const SizedBox(width: 4),
                  Text(
                    '${employees + testers}',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.textSub,
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded,
                    color: colors.iconSub, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status Dropdown ───────────────────────────────────────────────────────────

class _StatusDropdown extends StatelessWidget {
  final String label;
  final String? selected;
  final AppColors colors;
  final List<(String?, String)> statuses;
  final ValueChanged<String?> onSelect;

  const _StatusDropdown({
    required this.label,
    required this.selected,
    required this.colors,
    required this.statuses,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String?>(
      onSelected: onSelect,
      color: colors.backgroundElevation1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (_) => statuses.map((entry) {
        final (val, lbl) = entry;
        return PopupMenuItem<String?>(
          value: val,
          child: Text(
            lbl,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              fontWeight:
                  val == selected ? FontWeight.w700 : FontWeight.w500,
              color: colors.textStrong,
            ),
          ),
        );
      }).toList(),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.backgroundElevation1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.strokeSub),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textStrong,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 18, color: colors.iconSub),
          ],
        ),
      ),
    );
  }
}

// ── Icon Button ───────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final AppColors colors;

  const _IconBtn({
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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.strokeSub),
        ),
        child: Icon(icon, color: colors.iconSub, size: 20),
      ),
    );
  }
}

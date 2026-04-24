import 'package:dcmanagement/api/api.dart';
import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/services/auth_service.dart';
import 'package:dcmanagement/services/role_service.dart';
import 'package:dcmanagement/widgets/app_state_widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

class TaskListScreen extends StatefulWidget {
  final Map<String, dynamic>? project;

  const TaskListScreen({super.key, this.project});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _api = ApiService();
  final _auth = AuthService();

  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String? _error;
  bool _searching = false;
  final _searchCtrl = TextEditingController();
  String? _statusFilter = 'in_progress';

  // status: todo | in_progress | in_review | done | cancelled
  static const _statuses = [
    (null, 'Barchasi'),
    ('todo', "Bajarilmagan"),
    ('in_progress', 'Jarayonda'),
    ('in_review', "Ko'rib chiqilmoqda"),
    ('done', 'Bajarildi'),
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
      final projectId = widget.project?['id'] as int?;
      final data = await _api.getTasks(
        token,
        status: _statusFilter,
        projectId: projectId,
      );
      if (mounted) {
        setState(() {
          _all = data;
          _filtered = _applySearch(_searchCtrl.text, data);
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

  List<Map<String, dynamic>> _applySearch(
    String q,
    List<Map<String, dynamic>> list,
  ) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) return list;
    return list.where((item) {
      final title = (item['title'] as String? ?? '').toLowerCase();
      final desc = (item['description'] as String? ?? '').toLowerCase();
      final project = (item['project_info'] as String? ?? '').toLowerCase();
      return title.contains(query) ||
          desc.contains(query) ||
          project.contains(query);
    }).toList();
  }

  void _onSearch(String q) =>
      setState(() => _filtered = _applySearch(q, _all));

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
                  // TODO: create task screen
                },
                iconAlignment: IconAlignment.end,
                label: const Text(
                  "Vazifa qo'shish",
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                icon: const Icon(Icons.assignment_outlined, size: 18),
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
                            horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: colors.backgroundElevation1,
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Vazifalar',
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
                        _IconBtn(
                          icon: LucideIcons.filter,
                          colors: colors,
                          onTap: () {},
                        ),
                        const SizedBox(width: 8),
                        _StatusDropdown(
                          label: _currentStatusLabel,
                          colors: colors,
                          statuses: _statuses,
                          selected: _statusFilter,
                          onSelect: (val) {
                            setState(() => _statusFilter = val);
                            _load();
                          },
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.assignment_outlined,
                      size: 48, color: colors.iconSoft),
                  const SizedBox(height: 12),
                  Text(
                    "Vazifalar mavjud emas",
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.textSoft,
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
        itemBuilder: (_, i) =>
            _TaskCard(item: _filtered[i], colors: colors, onDelete: _load),
      ),
    );
  }
}

// ── Task Card ─────────────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final AppColors colors;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.item,
    required this.colors,
    required this.onDelete,
  });

  // priority: low | medium | high
  static const _priorityMap = <String, (String, Color)>{
    'low': ("Past", Color(0xFF95A5A6)),
    'medium': ("O'rta", Color(0xFFFF6B35)),
    'high': ('Yuqori', Color(0xFFE74C3C)),
  };

  // status: todo | in_progress | in_review | done | cancelled
  static const _statusMap = <String, (String, Color)>{
    'todo': ("Bajarilmagan", Color(0xFF95A5A6)),
    'in_progress': ('Jarayonda', Color(0xFFFFB300)),
    'in_review': ("Ko'rib chiqilmoqda", Color(0xFF7C6AF7)),
    'done': ('Bajarildi', Color(0xFF27AE60)),
    'cancelled': ('Bekor qilingan', Color(0xFFE74C3C)),
  };

  String _formatDate(String? raw) {
    if (raw == null) return '—';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('dd.MM.yyyy  HH:mm').format(dt);
    } catch (_) {
      return raw;
    }
  }

  String _formatMinutes(dynamic raw) {
    final mins = int.tryParse(raw?.toString() ?? '') ?? 0;
    if (mins == 0) return '—';
    if (mins < 60) return '$mins daqiqa';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '$h soat' : '$h soat $m daqiqa';
  }

  @override
  Widget build(BuildContext context) {
    final title = item['title'] as String? ?? '—';
    // project_info bu yerda string keladi
    final projectName = item['project_info'] as String? ?? '';
    final description = item['description'] as String? ?? '';
    final priority = item['priority'] as String? ?? 'medium';
    final status = item['status'] as String? ?? 'todo';
    final deadline = _formatDate(item['deadline'] as String?);
    final duration = _formatMinutes(item['estimated_minutes']);

    final assignee =
        item['assignee_info'] as Map<String, dynamic>?;

    final (priorityLabel, priorityColor) =
        _priorityMap[priority] ?? ("O'rta", const Color(0xFFFF6B35));
    final (statusLabel, statusColor) =
        _statusMap[status] ?? ('Jarayonda', const Color(0xFFFFB300));

    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundElevation1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.strokeSub),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sarlavha + prioritet
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: colors.textStrong,
                            ),
                          ),
                          if (projectName.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              projectName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: colors.textSub,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        priorityLabel,
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: priorityColor,
                        ),
                      ),
                    ),
                  ],
                ),

                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: colors.textSub,
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                // Sana + muddat + status badge
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
                    const SizedBox(width: 10),
                    Icon(Icons.access_time_rounded,
                        size: 13, color: colors.iconSub),
                    const SizedBox(width: 4),
                    Text(
                      duration,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colors.textSub,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
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
              ],
            ),
          ),

          // Assignee satri
          if (assignee != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
              child: Row(
                children: [
                  _Avatar(user: assignee, colors: colors),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assignee['username'] as String? ?? '—',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.textStrong,
                          ),
                        ),
                        if ((assignee['position'] as String? ?? '').isNotEmpty)
                          Text(
                            assignee['position'] as String,
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: colors.textSub,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showMenu(context),
                    icon: Icon(Icons.more_vert_rounded,
                        color: colors.iconSub, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ] else
            const SizedBox(height: 14),
        ],
      ),
    );
  }

  void _showMenu(BuildContext context) {
    final colors = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.backgroundElevation1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: colors.strokeSub,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading:
                    Icon(Icons.edit_outlined, color: colors.iconSub, size: 22),
                title: Text(
                  'Tahrirlash',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textStrong,
                  ),
                ),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Icon(Icons.delete_outline_rounded,
                    color: colors.errorSub, size: 22),
                title: Text(
                  "O'chirish",
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.errorSub,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onDelete();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final Map<String, dynamic> user;
  final AppColors colors;

  const _Avatar({required this.user, required this.colors});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user['avatar'] as String?;
    final username = user['username'] as String? ?? '';
    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';

    final hasUrl = avatarUrl != null &&
        (avatarUrl.startsWith('http://') ||
            avatarUrl.startsWith('https://'));

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: colors.backgroundElevation3,
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasUrl
          ? Image.network(
              avatarUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  _InitialText(initial: initial, colors: colors),
            )
          : _InitialText(initial: initial, colors: colors),
    );
  }
}

class _InitialText extends StatelessWidget {
  final String initial;
  final AppColors colors;
  const _InitialText({required this.initial, required this.colors});

  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          initial,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: colors.accentSub,
          ),
        ),
      );
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
      itemBuilder: (_) => statuses.map((e) {
        final (val, lbl) = e;
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

  const _IconBtn(
      {required this.icon, required this.onTap, required this.colors});

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

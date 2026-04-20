import 'package:dcmanagement/colors/app_colors.dart';
import 'package:flutter/material.dart';

enum UserSortMode { none, az, za, salaryAsc, salaryDesc }

class UserFilter {
  final String? role;
  final UserSortMode sortMode;

  const UserFilter({this.role, this.sortMode = UserSortMode.none});

  UserFilter copyWith({String? role, bool clearRole = false, UserSortMode? sortMode}) {
    return UserFilter(
      role: clearRole ? null : (role ?? this.role),
      sortMode: sortMode ?? this.sortMode,
    );
  }

  bool get hasActive => role != null || sortMode != UserSortMode.none;
}

class UserFilterScreen extends StatefulWidget {
  final UserFilter initial;
  final List<String> availableRoles;

  const UserFilterScreen({
    super.key,
    required this.initial,
    required this.availableRoles,
  });

  @override
  State<UserFilterScreen> createState() => _UserFilterScreenState();
}

class _UserFilterScreenState extends State<UserFilterScreen> {
  late UserFilter _filter;
  String? _open; // 'role' | 'sort'

  static const _sortOptions = [
    (label: 'A dan Z gacha', value: UserSortMode.az),
    (label: 'Z dan A gacha', value: UserSortMode.za),
    (label: "Oylik o'sish", value: UserSortMode.salaryAsc),
    (label: 'Oylik kamayish', value: UserSortMode.salaryDesc),
  ];

  @override
  void initState() {
    super.initState();
    _filter = widget.initial;
  }

  void _toggle(String key) =>
      setState(() => _open = _open == key ? null : key);

  String get _sortLabel {
    for (final o in _sortOptions) {
      if (o.value == _filter.sortMode) return o.label;
    }
    return 'Saralash';
  }

  void _clear() => setState(() {
        _filter = const UserFilter();
        _open = null;
      });

  void _apply() => Navigator.of(context).pop(_filter);

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.backgroundBase,
      appBar: AppBar(
        backgroundColor: colors.backgroundBase,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(widget.initial),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Container(
              decoration: BoxDecoration(
                color: colors.backgroundElevation1,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.strokeSub),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: colors.textStrong,
                size: 20,
              ),
            ),
          ),
        ),
        title: Text(
          'Filtrlash',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.textStrong,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_filter.hasActive)
            GestureDetector(
              onTap: _clear,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    'Tozalash',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.accentSub,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Lavozim ─────────────────────────────────────────────
                  _SectionLabel(label: 'Lavozim', colors: colors),
                  _DropTile(
                    colors: colors,
                    placeholder: 'Barcha lavozimlar',
                    value: _filter.role,
                    isOpen: _open == 'role',
                    onTap: () => _toggle('role'),
                    onClear: _filter.role != null
                        ? () => setState(() {
                              _filter = _filter.copyWith(clearRole: true);
                              _open = null;
                            })
                        : null,
                  ),
                  if (_open == 'role')
                    _OptionList(
                      colors: colors,
                      items: widget.availableRoles,
                      selected: _filter.role,
                      onSelect: (val) => setState(() {
                        _filter = _filter.copyWith(role: val);
                        _open = null;
                      }),
                    ),

                  const SizedBox(height: 12),

                  // ── Saralash ─────────────────────────────────────────────
                  _SectionLabel(label: 'Saralash', colors: colors),
                  _DropTile(
                    colors: colors,
                    placeholder: 'Barcha rollar',
                    value: _filter.sortMode != UserSortMode.none
                        ? _sortLabel
                        : null,
                    isOpen: _open == 'sort',
                    onTap: () => _toggle('sort'),
                    onClear: _filter.sortMode != UserSortMode.none
                        ? () => setState(() {
                              _filter = _filter.copyWith(
                                sortMode: UserSortMode.none,
                              );
                              _open = null;
                            })
                        : null,
                  ),
                  if (_open == 'sort')
                    _OptionList(
                      colors: colors,
                      items: _sortOptions.map((o) => o.label).toList(),
                      selected: _filter.sortMode != UserSortMode.none
                          ? _sortLabel
                          : null,
                      onSelect: (val) {
                        final mode = _sortOptions
                            .firstWhere((o) => o.label == val)
                            .value;
                        setState(() {
                          _filter = _filter.copyWith(sortMode: mode);
                          _open = null;
                        });
                      },
                    ),
                ],
              ),
            ),
          ),

          // ── Bottom buttons ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            decoration: BoxDecoration(
              color: colors.backgroundBase,
              border: Border(top: BorderSide(color: colors.strokeSub)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clear,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textStrong,
                      side: BorderSide(color: colors.strokeStrong),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Tozalash',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _apply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accentSub,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Qidirish',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Private widgets ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final AppColors colors;
  const _SectionLabel({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
            color: colors.textSub,
          ),
        ),
      );
}

class _DropTile extends StatelessWidget {
  final AppColors colors;
  final String placeholder;
  final String? value;
  final bool isOpen;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DropTile({
    required this.colors,
    required this.placeholder,
    required this.value,
    required this.isOpen,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
          decoration: BoxDecoration(
            color: colors.backgroundElevation1,
            borderRadius: isOpen
                ? const BorderRadius.vertical(top: Radius.circular(14))
                : BorderRadius.circular(14),
            border: Border.all(
              color: isOpen ? colors.accentSub : colors.strokeSub,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value ?? placeholder,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: value != null ? colors.textStrong : colors.textSoft,
                  ),
                ),
              ),
              if (value != null && onClear != null)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onClear,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.close_rounded,
                      color: colors.iconSub,
                      size: 20,
                    ),
                  ),
                )
              else
                Icon(
                  isOpen
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: colors.iconSub,
                  size: 22,
                ),
            ],
          ),
        ),
      );
}

class _OptionList extends StatelessWidget {
  final AppColors colors;
  final List<String> items;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _OptionList({
    required this.colors,
    required this.items,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: colors.backgroundElevation1,
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(14)),
          border: Border(
            left: BorderSide(color: colors.accentSub),
            right: BorderSide(color: colors.accentSub),
            bottom: BorderSide(color: colors.accentSub),
          ),
        ),
        child: items.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'Mavjud emas',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13,
                    color: colors.textSoft,
                  ),
                ),
              )
            : Column(
                children: items.map((item) {
                  final isSel = item == selected;
                  return InkWell(
                    onTap: () => onSelect(item),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      color: isSel
                          ? colors.accentDisabled
                          : Colors.transparent,
                      child: Text(
                        item,
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 14,
                          fontWeight:
                              isSel ? FontWeight.w700 : FontWeight.w500,
                          color: isSel
                              ? colors.accentSub
                              : colors.textStrong,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
      );
}

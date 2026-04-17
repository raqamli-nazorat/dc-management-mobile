import 'package:dcmanagement/api/api.dart';
import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/models/expense_filter.dart';
import 'package:dcmanagement/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpenseFilterScreen extends StatefulWidget {
  final ExpenseFilter initial;
  const ExpenseFilterScreen({super.key, required this.initial});

  @override
  State<ExpenseFilterScreen> createState() => _ExpenseFilterScreenState();
}

class _ExpenseFilterScreenState extends State<ExpenseFilterScreen> {
  final _api = ApiService();
  final _auth = AuthService();

  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _categories = [];

  late ExpenseFilter _filter;

  final _amountMinCtrl = TextEditingController();
  final _amountMaxCtrl = TextEditingController();

  String? _open; // which section is expanded: 'project','category','created','paid','confirmed'

  @override
  void initState() {
    super.initState();
    _filter = widget.initial;
    if (_filter.amountMin != null) {
      _amountMinCtrl.text = _filter.amountMin!.toStringAsFixed(0);
    }
    if (_filter.amountMax != null) {
      _amountMaxCtrl.text = _filter.amountMax!.toStringAsFixed(0);
    }
    _loadDropdowns();
  }

  @override
  void dispose() {
    _amountMinCtrl.dispose();
    _amountMaxCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDropdowns() async {
    try {
      final token = await _auth.getToken();
      if (token == null) return;
      final results = await Future.wait([
        _api.getProjects(token),
        _api.getExpenseCategories(token),
      ]);
      setState(() {
        _projects = results[0];
        _categories = results[1];
      });
    } catch (_) {}
  }

  void _toggle(String key) =>
      setState(() => _open = _open == key ? null : key);

  String _fmtDate(DateTime? dt) {
    if (dt == null) return '01.01.2026';
    return DateFormat('dd.MM.yyyy').format(dt);
  }

  void _apply() async {
    final minText = _amountMinCtrl.text.trim();
    final maxText = _amountMaxCtrl.text.trim();
    final updated = _filter.copyWith(
      amountMin: minText.isNotEmpty ? double.tryParse(minText) : null,
      amountMax: maxText.isNotEmpty ? double.tryParse(maxText) : null,
    );
    await updated.save();
    if (mounted) Navigator.of(context).pop(updated);
  }

  void _clear() async {
    await ExpenseFilter.clearSaved();
    if (mounted) Navigator.of(context).pop(const ExpenseFilter());
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
          onPressed: () => Navigator.of(context).pop(_filter),
        ),
        title: Text(
          'Filtrlash',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: colors.textStrong,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Loyiha
                  _SectionLabel(label: 'Loyiha', colors: colors),
                  _DropdownTile(
                    colors: colors,
                    placeholder: 'Loyiha tanlang',
                    value: _filter.projectTitle,
                    isOpen: _open == 'project',
                    onTap: () => _toggle('project'),
                  ),
                  if (_open == 'project')
                    _OptionsList(
                      colors: colors,
                      items: _projects.map((p) {
                        final createdAt = p['created_at'] as String?;
                        String? subtitle;
                        if (p['description'] != null &&
                            (p['description'] as String).isNotEmpty) {
                          subtitle = p['description'] as String;
                        }
                        String? dateStr;
                        if (createdAt != null) {
                          try {
                            dateStr = DateFormat('dd.MM.yyyy')
                                .format(DateTime.parse(createdAt));
                          } catch (_) {}
                        }
                        return _OptionItem(
                          id: p['id'] as int,
                          title: p['title'] as String? ?? '',
                          subtitle: subtitle,
                          trailing: dateStr,
                          selected: _filter.projectId == p['id'],
                        );
                      }).toList(),
                      onSelect: (item) {
                        setState(() {
                          _filter = _filter.copyWith(
                            projectId: item.id,
                            projectTitle: item.title,
                          );
                          _open = null;
                        });
                      },
                    ),

                  const SizedBox(height: 14),

                  // Xarajat turi
                  _SectionLabel(label: 'Xarajat turi', colors: colors),
                  _DropdownTile(
                    colors: colors,
                    placeholder: 'Xarajat turini tanlang',
                    value: _filter.categoryTitle,
                    isOpen: _open == 'category',
                    onTap: () => _toggle('category'),
                  ),
                  if (_open == 'category')
                    _OptionsList(
                      colors: colors,
                      items: _categories
                          .map((c) => _OptionItem(
                                id: c['id'] as int,
                                title: c['title'] as String? ?? '',
                                selected: _filter.categoryId == c['id'],
                              ))
                          .toList(),
                      onSelect: (item) {
                        setState(() {
                          _filter = _filter.copyWith(
                            categoryId: item.id,
                            categoryTitle: item.title,
                          );
                          _open = null;
                        });
                      },
                    ),

                  const SizedBox(height: 14),

                  // Summa
                  _SectionLabel(label: 'Summa', colors: colors),
                  Row(
                    children: [
                      Expanded(
                        child: _AmountField(
                          controller: _amountMinCtrl,
                          hint: 'dan: 0',
                          colors: colors,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AmountField(
                          controller: _amountMaxCtrl,
                          hint: 'gacha: 0',
                          colors: colors,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Yaratilgan vaqti
                  _SectionLabel(label: 'Yaratilgan vaqti', colors: colors),
                  _DateTile(
                    colors: colors,
                    value: _filter.createdAt,
                    display: _fmtDate(_filter.createdAt),
                    isOpen: _open == 'created',
                    onTap: () => _toggle('created'),
                  ),
                  if (_open == 'created')
                    _InlineCalendar(
                      colors: colors,
                      selected: _filter.createdAt,
                      onChanged: (d) => setState(() {
                        _filter = _filter.copyWith(createdAt: d);
                        _open = null;
                      }),
                    ),

                  const SizedBox(height: 14),

                  // To'langan vaqti
                  _SectionLabel(label: "To'langan vaqti", colors: colors),
                  _DateTile(
                    colors: colors,
                    value: _filter.paidAt,
                    display: _fmtDate(_filter.paidAt),
                    isOpen: _open == 'paid',
                    onTap: () => _toggle('paid'),
                  ),
                  if (_open == 'paid')
                    _InlineCalendar(
                      colors: colors,
                      selected: _filter.paidAt,
                      onChanged: (d) => setState(() {
                        _filter = _filter.copyWith(paidAt: d);
                        _open = null;
                      }),
                    ),

                  const SizedBox(height: 14),

                  // Tasdiqlangan vaqti
                  _SectionLabel(
                      label: 'Tasdiqlangan vaqti', colors: colors),
                  _DateTile(
                    colors: colors,
                    value: _filter.confirmedAt,
                    display: _fmtDate(_filter.confirmedAt),
                    isOpen: _open == 'confirmed',
                    onTap: () => _toggle('confirmed'),
                  ),
                  if (_open == 'confirmed')
                    _InlineCalendar(
                      colors: colors,
                      selected: _filter.confirmedAt,
                      onChanged: (d) => setState(() {
                        _filter = _filter.copyWith(confirmedAt: d);
                        _open = null;
                      }),
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom buttons
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Tozalash',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w900,
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
                      foregroundColor: colors.textWhite,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Qidirish',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w900,
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

// ── Helper widgets ────────────────────────────────────────────────────────────

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
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colors.textSub,
          ),
        ),
      );
}

class _DropdownTile extends StatelessWidget {
  final AppColors colors;
  final String placeholder;
  final String? value;
  final bool isOpen;
  final VoidCallback onTap;

  const _DropdownTile({
    required this.colors,
    required this.placeholder,
    required this.value,
    required this.isOpen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          decoration: BoxDecoration(
            color: colors.backgroundBase,
            borderRadius: isOpen
                ? const BorderRadius.vertical(top: Radius.circular(12))
                : BorderRadius.circular(12),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: value != null
                        ? colors.textStrong
                        : colors.textSoft,
                  ),
                ),
              ),
              Icon(
                isOpen
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: colors.iconSub,
                size: 20,
              ),
            ],
          ),
        ),
      );
}

class _OptionItem {
  final int id;
  final String title;
  final String? subtitle;
  final String? trailing;
  final bool selected;

  const _OptionItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.selected,
  });
}

class _OptionsList extends StatelessWidget {
  final AppColors colors;
  final List<_OptionItem> items;
  final ValueChanged<_OptionItem> onSelect;

  const _OptionsList({
    required this.colors,
    required this.items,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: colors.backgroundBase,
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(12)),
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
                      color: colors.textSoft),
                ),
              )
            : Column(
                children: items.map((item) {
                  return InkWell(
                    onTap: () => onSelect(item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: item.selected
                            ? colors.accentDisabled
                            : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 14,
                                    fontWeight: item.selected
                                        ? FontWeight.w900
                                        : FontWeight.w500,
                                    color: colors.textStrong,
                                  ),
                                ),
                                if (item.subtitle != null)
                                  Text(
                                    item.subtitle!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: colors.textSoft,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (item.trailing != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              item.trailing!,
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
                  );
                }).toList(),
              ),
      );
}

class _DateTile extends StatelessWidget {
  final AppColors colors;
  final DateTime? value;
  final String display;
  final bool isOpen;
  final VoidCallback onTap;

  const _DateTile({
    required this.colors,
    required this.value,
    required this.display,
    required this.isOpen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          decoration: BoxDecoration(
            color: colors.backgroundBase,
            borderRadius: isOpen
                ? const BorderRadius.vertical(top: Radius.circular(12))
                : BorderRadius.circular(12),
            border: Border.all(
              color: isOpen ? colors.accentSub : colors.strokeSub,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  display,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: value != null
                        ? colors.textStrong
                        : colors.textSoft,
                  ),
                ),
              ),
              Icon(Icons.calendar_today_outlined,
                  size: 18, color: colors.iconSub),
            ],
          ),
        ),
      );
}

class _InlineCalendar extends StatelessWidget {
  final AppColors colors;
  final DateTime? selected;
  final ValueChanged<DateTime> onChanged;

  const _InlineCalendar({
    required this.colors,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: colors.backgroundBase,
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(12)),
          border: Border(
            left: BorderSide(color: colors.accentSub),
            right: BorderSide(color: colors.accentSub),
            bottom: BorderSide(color: colors.accentSub),
          ),
        ),
        child: CalendarDatePicker(
          initialDate: selected ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          onDateChanged: onChanged,
        ),
      );
}

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final AppColors colors;

  const _AmountField({
    required this.controller,
    required this.hint,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: colors.textStrong,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            color: colors.textSoft,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          filled: true,
          fillColor: colors.backgroundBase,
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
        ),
      );
}

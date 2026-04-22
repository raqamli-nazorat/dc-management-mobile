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

  // which tile is open: 'project','category','toifa',
  // 'created_from','created_to','paid_from','paid_to','confirmed_from','confirmed_to'
  String? _open;

  @override
  void initState() {
    super.initState();
    _filter = widget.initial;
    if (_filter.amountMin != null) {
      _amountMinCtrl.text = _fmt(_filter.amountMin!);
    }
    if (_filter.amountMax != null) {
      _amountMaxCtrl.text = _fmt(_filter.amountMax!);
    }
    _loadDropdowns();
  }

  @override
  void dispose() {
    _amountMinCtrl.dispose();
    _amountMaxCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v) {
    final n = NumberFormat('#,##0.00', 'uz').format(v);
    return n.replaceAll(',', ' ').replaceAll('.', ',');
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

  double? _parseAmount(String text) {
    final clean = text.replaceAll(' ', '').replaceAll(',', '.');
    return clean.isEmpty ? null : double.tryParse(clean);
  }

  void _apply() async {
    final updated = _filter.copyWith(
      amountMin: _parseAmount(_amountMinCtrl.text),
      amountMax: _parseAmount(_amountMaxCtrl.text),
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
            fontSize: 17,
            fontWeight: FontWeight.w800,
            height: 28 / 17,
            letterSpacing: 0,
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
                  // ── Loyiha ──────────────────────────────────────────────
                  _Label(label: 'Loyiha', colors: colors),
                  _FloatingDropdown(
                    colors: colors,
                    placeholder: 'Loyiha tanlang',
                    value: _filter.projectTitle,
                    items: _projects,
                    selectedId: _filter.projectId,
                    onSelect: (item) => setState(() {
                      _filter = _filter.copyWith(
                        projectId: item['id'] as int,
                        projectTitle: item['title'] as String,
                      );
                    }),
                    onClear: _filter.projectId != null
                        ? () => setState(() {
                              _filter = _filter.copyWith(
                                projectId: null,
                                projectTitle: null,
                              );
                            })
                        : null,
                  ),

                  const SizedBox(height: 14),

                  // ── Xarajat turi ─────────────────────────────────────────
                  _Label(label: 'Xarajat turi', colors: colors),
                  _FloatingDropdown(
                    colors: colors,
                    placeholder: 'Xarajat turini tanlang',
                    value: _filter.categoryTitle,
                    items: _categories,
                    selectedId: _filter.categoryId,
                    onSelect: (item) => setState(() {
                      _filter = _filter.copyWith(
                        categoryId: item['id'] as int,
                        categoryTitle: item['title'] as String,
                      );
                    }),
                    onClear: _filter.categoryId != null
                        ? () => setState(() {
                              _filter = _filter.copyWith(
                                categoryId: null,
                                categoryTitle: null,
                              );
                            })
                        : null,
                  ),

                  const SizedBox(height: 14),

                  // ── Toifa ────────────────────────────────────────────────
                  _Label(label: 'Toifa', colors: colors),
                  _FloatingDropdown(
                    colors: colors,
                    placeholder: 'Toifani tanlang',
                    value: _filter.toifaTitle,
                    items: _categories,
                    selectedId: _filter.toifaId,
                    onSelect: (item) => setState(() {
                      _filter = _filter.copyWith(
                        toifaId: item['id'] as int,
                        toifaTitle: item['title'] as String,
                      );
                    }),
                    onClear: _filter.toifaId != null
                        ? () => setState(() {
                              _filter = _filter.copyWith(
                                toifaId: null,
                                toifaTitle: null,
                              );
                            })
                        : null,
                  ),

                  const SizedBox(height: 14),

                  // ── Summa ────────────────────────────────────────────────
                  _Label(label: 'Summa (UZS)', colors: colors),
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

                  // ── Yaratilgan vaqti oralig'i ────────────────────────────
                  _Label(label: "Yaratilgan vaqti oralig'i", colors: colors),
                  Row(
                    children: [
                      Expanded(
                        child: _DateTile(
                          colors: colors,
                          display: _fmtDate(_filter.createdAtFrom),
                          isOpen: _open == 'created_from',
                          onTap: () => _toggle('created_from'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DateTile(
                          colors: colors,
                          display: _fmtDate(_filter.createdAtTo),
                          isOpen: _open == 'created_to',
                          onTap: () => _toggle('created_to'),
                        ),
                      ),
                    ],
                  ),
                  if (_open == 'created_from')
                    _InlineCalendar(
                      colors: colors,
                      selected: _filter.createdAtFrom,
                      onChanged: (d) => setState(() {
                        _filter = _filter.copyWith(createdAtFrom: d);
                        _open = null;
                      }),
                    ),
                  if (_open == 'created_to')
                    _InlineCalendar(
                      colors: colors,
                      selected: _filter.createdAtTo,
                      onChanged: (d) => setState(() {
                        _filter = _filter.copyWith(createdAtTo: d);
                        _open = null;
                      }),
                    ),

                  const SizedBox(height: 14),

                  // ── To'langan vaqti oralig'i ─────────────────────────────
                  _Label(label: "To'langan vaqti oralig'i", colors: colors),
                  Row(
                    children: [
                      Expanded(
                        child: _DateTile(
                          colors: colors,
                          display: _fmtDate(_filter.paidAtFrom),
                          isOpen: _open == 'paid_from',
                          onTap: () => _toggle('paid_from'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DateTile(
                          colors: colors,
                          display: _fmtDate(_filter.paidAtTo),
                          isOpen: _open == 'paid_to',
                          onTap: () => _toggle('paid_to'),
                        ),
                      ),
                    ],
                  ),
                  if (_open == 'paid_from')
                    _InlineCalendar(
                      colors: colors,
                      selected: _filter.paidAtFrom,
                      onChanged: (d) => setState(() {
                        _filter = _filter.copyWith(paidAtFrom: d);
                        _open = null;
                      }),
                    ),
                  if (_open == 'paid_to')
                    _InlineCalendar(
                      colors: colors,
                      selected: _filter.paidAtTo,
                      onChanged: (d) => setState(() {
                        _filter = _filter.copyWith(paidAtTo: d);
                        _open = null;
                      }),
                    ),

                  const SizedBox(height: 14),

                  // ── Tasdiqlangan vaqti oralig'i ──────────────────────────
                  _Label(label: "Tasdiqlangan vaqti oralig'i", colors: colors),
                  Row(
                    children: [
                      Expanded(
                        child: _DateTile(
                          colors: colors,
                          display: _fmtDate(_filter.confirmedAtFrom),
                          isOpen: _open == 'confirmed_from',
                          onTap: () => _toggle('confirmed_from'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DateTile(
                          colors: colors,
                          display: _fmtDate(_filter.confirmedAtTo),
                          isOpen: _open == 'confirmed_to',
                          onTap: () => _toggle('confirmed_to'),
                        ),
                      ),
                    ],
                  ),
                  if (_open == 'confirmed_from')
                    _InlineCalendar(
                      colors: colors,
                      selected: _filter.confirmedAtFrom,
                      onChanged: (d) => setState(() {
                        _filter = _filter.copyWith(confirmedAtFrom: d);
                        _open = null;
                      }),
                    ),
                  if (_open == 'confirmed_to')
                    _InlineCalendar(
                      colors: colors,
                      selected: _filter.confirmedAtTo,
                      onChanged: (d) => setState(() {
                        _filter = _filter.copyWith(confirmedAtTo: d);
                        _open = null;
                      }),
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── Bottom buttons ───────────────────────────────────────────────
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
                      foregroundColor: colors.textWhite,
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

// ── Widgets ───────────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String label;
  final AppColors colors;
  const _Label({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            height: 16 / 11,
            letterSpacing: 0.4,
            color: colors.textSub,
          ),
        ),
      );
}

class _FloatingDropdown extends StatefulWidget {
  final String placeholder;
  final String? value;
  final List<Map<String, dynamic>> items;
  final int? selectedId;
  final ValueChanged<Map<String, dynamic>> onSelect;
  final VoidCallback? onClear;
  final AppColors colors;

  const _FloatingDropdown({
    required this.placeholder,
    required this.value,
    required this.items,
    required this.selectedId,
    required this.onSelect,
    required this.colors,
    this.onClear,
  });

  @override
  State<_FloatingDropdown> createState() => _FloatingDropdownState();
}

class _FloatingDropdownState extends State<_FloatingDropdown> {
  final _key = GlobalKey();
  OverlayEntry? _entry;
  bool _isOpen = false;

  void _open() {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;

    _entry = OverlayEntry(
      builder: (_) => _DropdownOverlay(
        top: offset.dy + size.height + 6,
        left: offset.dx,
        width: size.width,
        items: widget.items,
        selectedId: widget.selectedId,
        colors: widget.colors,
        onSelect: (item) {
          _close();
          widget.onSelect(item);
        },
        onDismiss: _close,
      ),
    );
    Overlay.of(context).insert(_entry!);
    setState(() => _isOpen = true);
  }

  void _close() {
    _entry?.remove();
    _entry = null;
    if (mounted) setState(() => _isOpen = false);
  }

  @override
  void dispose() {
    _entry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return GestureDetector(
      key: _key,
      onTap: _isOpen ? _close : _open,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: BoxDecoration(
          color: colors.backgroundElevation1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isOpen ? colors.accentSub : colors.strokeSub,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.value ?? widget.placeholder,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: widget.value != null
                      ? colors.textStrong
                      : colors.textSoft,
                ),
              ),
            ),
            if (widget.value != null && widget.onClear != null)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _close();
                  widget.onClear!();
                },
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
                _isOpen
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
}

class _DropdownOverlay extends StatelessWidget {
  final double top;
  final double left;
  final double width;
  final List<Map<String, dynamic>> items;
  final int? selectedId;
  final AppColors colors;
  final ValueChanged<Map<String, dynamic>> onSelect;
  final VoidCallback onDismiss;

  const _DropdownOverlay({
    required this.top,
    required this.left,
    required this.width,
    required this.items,
    required this.selectedId,
    required this.colors,
    required this.onSelect,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
        ),
        Positioned(
          top: top,
          left: left,
          width: width,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 240),
              decoration: BoxDecoration(
                color: colors.backgroundElevation1,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.strokeSub),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
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
                    : ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        children: items.map((item) {
                          final selected = item['id'] == selectedId;
                          return InkWell(
                            onTap: () => onSelect(item),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              color: selected
                                  ? colors.accentDisabled
                                  : Colors.transparent,
                              child: Text(
                                item['title'] as String? ?? '',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 14,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: colors.textStrong,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DateTile extends StatelessWidget {
  final AppColors colors;
  final String display;
  final bool isOpen;
  final VoidCallback onTap;

  const _DateTile({
    required this.colors,
    required this.display,
    required this.isOpen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          decoration: BoxDecoration(
            color: colors.backgroundElevation1,
            borderRadius: BorderRadius.circular(12),
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
                    color: colors.textStrong,
                  ),
                ),
              ),
              Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: colors.iconSub,
              ),
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
          color: colors.backgroundElevation1,
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(12)),
          border: Border(
            left: BorderSide(color: colors.accentSub),
            right: BorderSide(color: colors.accentSub),
            bottom: BorderSide(color: colors.accentSub),
          ),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: colors.accentSub,
                  onSurface: colors.textStrong,
                  surface: colors.backgroundElevation1,
                ),
          ),
          child: CalendarDatePicker(
            initialDate: selected ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            onDateChanged: onChanged,
          ),
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
        textAlign: TextAlign.right,
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
          fillColor: colors.backgroundElevation1,
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

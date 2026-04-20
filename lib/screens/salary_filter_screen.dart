import 'package:dcmanagement/colors/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SalaryFilter {
  final String? month;
  final DateTime? createdAtFrom;
  final DateTime? createdAtTo;
  final double? amountMin;
  final double? amountMax;
  final bool hasJarima;

  const SalaryFilter({
    this.month,
    this.createdAtFrom,
    this.createdAtTo,
    this.amountMin,
    this.amountMax,
    this.hasJarima = false,
  });

  bool get isActive =>
      month != null ||
      createdAtFrom != null ||
      createdAtTo != null ||
      amountMin != null ||
      amountMax != null ||
      hasJarima;

  SalaryFilter copyWith({
    Object? month = _unset,
    Object? createdAtFrom = _unset,
    Object? createdAtTo = _unset,
    Object? amountMin = _unset,
    Object? amountMax = _unset,
    bool? hasJarima,
  }) =>
      SalaryFilter(
        month: month == _unset ? this.month : month as String?,
        createdAtFrom: createdAtFrom == _unset
            ? this.createdAtFrom
            : createdAtFrom as DateTime?,
        createdAtTo:
            createdAtTo == _unset ? this.createdAtTo : createdAtTo as DateTime?,
        amountMin: amountMin == _unset ? this.amountMin : amountMin as double?,
        amountMax: amountMax == _unset ? this.amountMax : amountMax as double?,
        hasJarima: hasJarima ?? this.hasJarima,
      );
}

const _unset = Object();

const _months = [
  'Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'Iyun',
  'Iyul', 'Avgust', 'Sentabr', 'Oktabr', 'Noyabr', 'Dekabr',
];

class SalaryFilterScreen extends StatefulWidget {
  final SalaryFilter initial;
  const SalaryFilterScreen({super.key, required this.initial});

  @override
  State<SalaryFilterScreen> createState() => _SalaryFilterScreenState();
}

class _SalaryFilterScreenState extends State<SalaryFilterScreen> {
  late SalaryFilter _filter;
  final _minCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();
  String? _open; // 'month','from_cal','to_cal'

  @override
  void initState() {
    super.initState();
    _filter = widget.initial;
    if (_filter.amountMin != null) {
      _minCtrl.text = _filter.amountMin!.toStringAsFixed(2).replaceAll('.', ',');
    }
    if (_filter.amountMax != null) {
      _maxCtrl.text = _filter.amountMax!.toStringAsFixed(2).replaceAll('.', ',');
    }
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  void _toggle(String key) =>
      setState(() => _open = _open == key ? null : key);

  String _fmtDate(DateTime? dt) =>
      dt == null ? '01.01.2026' : DateFormat('dd.MM.yyyy').format(dt);

  double? _parseAmount(String t) {
    final c = t.replaceAll(' ', '').replaceAll(',', '.');
    return c.isEmpty ? null : double.tryParse(c);
  }

  void _apply() => Navigator.of(context).pop(
        _filter.copyWith(
          amountMin: _parseAmount(_minCtrl.text),
          amountMax: _parseAmount(_maxCtrl.text),
        ),
      );

  void _clear() => Navigator.of(context).pop(const SalaryFilter());

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
                  // Oy
                  _Label(label: 'Oy', colors: colors),
                  _DropdownTile(
                    colors: colors,
                    placeholder: 'Oyni tanlang',
                    value: _filter.month,
                    isOpen: _open == 'month',
                    onTap: () => _toggle('month'),
                    onClear: _filter.month != null
                        ? () => setState(() {
                              _filter = _filter.copyWith(month: null);
                              _open = null;
                            })
                        : null,
                  ),
                  if (_open == 'month')
                    _MonthList(
                      colors: colors,
                      selected: _filter.month,
                      onSelect: (m) => setState(() {
                        _filter = _filter.copyWith(month: m);
                        _open = null;
                      }),
                    ),

                  const SizedBox(height: 14),

                  // Yaratilgan vaqti oralig'i
                  _Label(label: "Yaratilgan vaqti oralig'i", colors: colors),
                  Row(
                    children: [
                      Expanded(
                        child: _DateTile(
                          colors: colors,
                          display: _fmtDate(_filter.createdAtFrom),
                          isOpen: _open == 'from_cal',
                          onTap: () => _toggle('from_cal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DateTile(
                          colors: colors,
                          display: _fmtDate(_filter.createdAtTo),
                          isOpen: _open == 'to_cal',
                          onTap: () => _toggle('to_cal'),
                        ),
                      ),
                    ],
                  ),
                  if (_open == 'from_cal')
                    _InlineCalendar(
                      colors: colors,
                      selected: _filter.createdAtFrom,
                      onChanged: (d) => setState(() {
                        _filter = _filter.copyWith(createdAtFrom: d);
                        _open = null;
                      }),
                    ),
                  if (_open == 'to_cal')
                    _InlineCalendar(
                      colors: colors,
                      selected: _filter.createdAtTo,
                      onChanged: (d) => setState(() {
                        _filter = _filter.copyWith(createdAtTo: d);
                        _open = null;
                      }),
                    ),

                  const SizedBox(height: 14),

                  // Jami miqdori
                  _Label(label: 'Jami miqdori (UZS)', colors: colors),
                  Row(
                    children: [
                      Expanded(
                        child: _AmountField(
                          colors: colors,
                          controller: _minCtrl,
                          hint: 'dan: 0',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AmountField(
                          colors: colors,
                          controller: _maxCtrl,
                          hint: 'gacha: 0',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Jarima miqdori toggle
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Jarima miqdori',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            height: 16 / 11,
                            letterSpacing: 0.4,
                            color: colors.textSub,
                          ),
                        ),
                      ),
                      Switch(
                        value: _filter.hasJarima,
                        onChanged: (v) =>
                            setState(() => _filter = _filter.copyWith(hasJarima: v)),
                        activeThumbColor: Colors.white,
                        activeTrackColor: colors.accentSub,
                        inactiveThumbColor: colors.iconSub,
                        inactiveTrackColor: colors.strokeStrong,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

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
                          borderRadius: BorderRadius.circular(14)),
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

// ── Reusable widgets ──────────────────────────────────────────────────────────

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

class _DropdownTile extends StatelessWidget {
  final AppColors colors;
  final String placeholder;
  final String? value;
  final bool isOpen;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DropdownTile({
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: isOpen
                ? const BorderRadius.vertical(top: Radius.circular(12))
                : BorderRadius.circular(12),
            border: Border.all(
              color: isOpen ? colors.accentSub : const Color(0xFF292A2A),
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
                    child: Icon(Icons.close_rounded,
                        color: colors.iconSub, size: 20),
                  ),
                )
              else
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

class _MonthList extends StatelessWidget {
  final AppColors colors;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _MonthList({
    required this.colors,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(12)),
          border: Border(
            left: BorderSide(color: colors.accentSub),
            right: BorderSide(color: colors.accentSub),
            bottom: BorderSide(color: colors.accentSub),
          ),
        ),
        child: Column(
          children: _months.map((m) {
            final isSelected = m == selected;
            return InkWell(
              onTap: () => onSelect(m),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                color: isSelected
                    ? colors.accentDisabled
                    : Colors.transparent,
                child: Text(
                  m,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: colors.textStrong,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
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
            color: const Color(0xFF111111),
            borderRadius: isOpen
                ? const BorderRadius.vertical(top: Radius.circular(12))
                : BorderRadius.circular(12),
            border: Border.all(
              color: isOpen ? colors.accentSub : const Color(0xFF292A2A),
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
          color: const Color(0xFF111111),
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
                  surface: const Color(0xFF111111),
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
          fillColor: const Color(0xFF111111),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF292A2A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF292A2A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.accentSub),
          ),
        ),
      );
}

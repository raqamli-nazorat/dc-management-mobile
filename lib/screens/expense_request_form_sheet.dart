import 'package:dcmanagement/api/api.dart';
import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/screens/expance_page_wrapper.dart';
import 'package:dcmanagement/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> showExpenseRequestForm(BuildContext context) {
  return Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const ExpenseRequestPage()));
}

const _paymentOptions = [
  _Option(value: 'cash', label: "Naqt pul orqali"),
  _Option(value: 'card', label: "Karta raqam orqali"),
];

class _Option {
  final String value;
  final String label;
  const _Option({required this.value, required this.label});
}

// ── Card number formatter ─────────────────────────────────────────────────────

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

// ── Main form widget ──────────────────────────────────────────────────────────

class ExpenseRequestForm extends StatefulWidget {
  const ExpenseRequestForm();

  @override
  State<ExpenseRequestForm> createState() => _ExpenseRequestFormState();
}

class _ExpenseRequestFormState extends State<ExpenseRequestForm> {
  final _api = ApiService();
  final _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _categories = [];

  Map<String, dynamic>? _selectedProject;
  Map<String, dynamic>? _selectedCategory;
  Map<String, dynamic>? _selectedToifa;
  _Option? _selectedPayment;

  final _amountCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _cardNumberCtrl = TextEditingController();

  bool _loadingDropdowns = true;
  bool _submitting = false;

  String? _openDropdown; // 'project','category','toifa','payment'

  bool _projectError = false;
  bool _reasonError = false;

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
    _reasonCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    _cardNumberCtrl.dispose();
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
        _loadingDropdowns = false;
      });
    } catch (_) {
      setState(() => _loadingDropdowns = false);
    }
  }

  void _toggleDropdown(String key) =>
      setState(() => _openDropdown = _openDropdown == key ? null : key);

  Future<void> _submit() async {
    final hasProjectError = _selectedProject == null;
    final hasReasonError = _reasonCtrl.text.trim().isEmpty;
    setState(() {
      _projectError = hasProjectError;
      _reasonError = hasReasonError;
    });
    if (hasProjectError || hasReasonError) return;

    setState(() => _submitting = true);
    try {
      final token = await _auth.getToken();
      if (token == null) throw Exception('Token topilmadi');
      await _api.createExpenseRequest(token, {
        if (_selectedProject != null) 'project': _selectedProject!['id'],
        if (_selectedCategory != null)
          'expense_category': _selectedCategory!['id'],
        if (_selectedToifa != null) 'type': _selectedToifa!['id'],
        'amount': _amountCtrl.text.trim().isNotEmpty
            ? _amountCtrl.text.trim().replaceAll(' ', '').replaceAll(',', '.')
            : '0',
        'reason': _reasonCtrl.text.trim(),
        if (_selectedPayment != null) 'payment_method': _selectedPayment!.value,
        if (_selectedPayment?.value == 'card' &&
            _cardNumberCtrl.text.isNotEmpty)
          'card_number': _cardNumberCtrl.text.replaceAll(' ', ''),
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString(),
              style: const TextStyle(fontFamily: 'Manrope'),
            ),
            backgroundColor: AppColors.of(context).errorStrong,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "So'rov yuborish",
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 28 / 17,
                    letterSpacing: 0,
                    color: colors.textStrong,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: colors.iconSub),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),

        // Form
        Expanded(
          child: _loadingDropdowns
              ? Center(
                  child: CircularProgressIndicator(color: colors.accentSub),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Loyiha
                        _FormLabel(label: 'Loyiha uchun', colors: colors),
                        _FormDropdownTile(
                          colors: colors,
                          placeholder: 'Loyiha tanlang',
                          value: _selectedProject?['title'] as String?,
                          isOpen: _openDropdown == 'project',
                          onTap: () => _toggleDropdown('project'),
                          onClear: _selectedProject != null
                              ? () => setState(() {
                                    _selectedProject = null;
                                    _openDropdown = null;
                                  })
                              : null,
                        ),
                        if (_projectError)
                          _ErrorText(
                            label: 'Loyiha tanlang',
                            colors: colors,
                          ),
                        if (_openDropdown == 'project')
                          _FormOptionsList(
                            colors: colors,
                            items: _projects,
                            selectedId: _selectedProject?['id'] as int?,
                            onSelect: (item) => setState(() {
                              _selectedProject = item;
                              _projectError = false;
                              _openDropdown = null;
                            }),
                          ),

                        const SizedBox(height: 14),

                        // Xarajat turi
                        _FormLabel(label: 'Xarajat turi', colors: colors),
                        _FormDropdownTile(
                          colors: colors,
                          placeholder: 'Xarajat turini tanlang',
                          value: _selectedCategory?['title'] as String?,
                          isOpen: _openDropdown == 'category',
                          onTap: () => _toggleDropdown('category'),
                          onClear: _selectedCategory != null
                              ? () => setState(() {
                                    _selectedCategory = null;
                                    _openDropdown = null;
                                  })
                              : null,
                        ),
                        if (_openDropdown == 'category')
                          _FormOptionsList(
                            colors: colors,
                            items: _categories,
                            selectedId: _selectedCategory?['id'] as int?,
                            onSelect: (item) => setState(() {
                              _selectedCategory = item;
                              _openDropdown = null;
                            }),
                          ),

                        const SizedBox(height: 14),

                        // Toifa
                        _FormLabel(label: 'Toifa', colors: colors),
                        _FormDropdownTile(
                          colors: colors,
                          placeholder: 'Biror narsa uchun',
                          value: _selectedToifa?['title'] as String?,
                          isOpen: _openDropdown == 'toifa',
                          onTap: () => _toggleDropdown('toifa'),
                          onClear: _selectedToifa != null
                              ? () => setState(() {
                                    _selectedToifa = null;
                                    _openDropdown = null;
                                  })
                              : null,
                        ),
                        if (_openDropdown == 'toifa')
                          _FormOptionsList(
                            colors: colors,
                            items: _categories,
                            selectedId: _selectedToifa?['id'] as int?,
                            onSelect: (item) => setState(() {
                              _selectedToifa = item;
                              _openDropdown = null;
                            }),
                          ),

                        const SizedBox(height: 14),

                        // Miqdori
                        _FormLabel(label: 'Miqdori', colors: colors),
                        _StyledTextField(
                          colors: colors,
                          controller: _amountCtrl,
                          hint: 'Summani kiriting: 0,00',
                          keyboardType: TextInputType.number,
                        ),

                        const SizedBox(height: 14),

                        // Sababi
                        _FormLabel(label: 'Sababi', colors: colors),
                        _StyledTextField(
                          colors: colors,
                          controller: _reasonCtrl,
                          hint: 'Sababini yozing',
                          maxLines: 4,
                          onChanged: (_) {
                            if (_reasonError) {
                              setState(() => _reasonError = false);
                            }
                          },
                          suffixIcon: _reasonCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    color: colors.iconSub,
                                    size: 18,
                                  ),
                                  onPressed: () =>
                                      setState(() => _reasonCtrl.clear()),
                                )
                              : null,
                        ),
                        if (_reasonError)
                          _ErrorText(
                            label: 'Bu maydon majburiy',
                            colors: colors,
                          ),

                        const SizedBox(height: 14),

                        // To'lov turi
                        _FormLabel(label: "To'lov turi", colors: colors),
                        _FormDropdownTile(
                          colors: colors,
                          placeholder: "To'lov turini tanlang",
                          value: _selectedPayment?.label,
                          isOpen: _openDropdown == 'payment',
                          onTap: () => _toggleDropdown('payment'),
                          onClear: _selectedPayment != null
                              ? () => setState(() {
                                    _selectedPayment = null;
                                    _cardNumberCtrl.clear();
                                    _openDropdown = null;
                                  })
                              : null,
                        ),
                        if (_openDropdown == 'payment')
                          _PaymentOptionsList(
                            colors: colors,
                            options: _paymentOptions,
                            selected: _selectedPayment,
                            onSelect: (opt) => setState(() {
                              _selectedPayment = opt;
                              _cardNumberCtrl.clear();
                              _openDropdown = null;
                            }),
                          ),

                        // Karta raqam (faqat karta tanlanganda)
                        if (_selectedPayment?.value == 'card') ...[
                          const SizedBox(height: 14),
                          _FormLabel(label: 'Karta raqam', colors: colors),
                          _StyledTextField(
                            colors: colors,
                            controller: _cardNumberCtrl,
                            hint: '0000 0000 0000 0000',
                            keyboardType: TextInputType.number,
                            inputFormatters: [_CardNumberFormatter()],
                          ),
                        ],

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
        ),

        // Submit button
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: colors.backgroundBase,
            border: Border(top: BorderSide(color: colors.strokeSub)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentSub,
                foregroundColor: colors.textWhite,
                disabledBackgroundColor: colors.accentSoft,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 18),
                elevation: 0,
              ),
              child: _submitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: colors.textWhite,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "So'rov yuborish",
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Form helper widgets ───────────────────────────────────────────────────────

class _FormLabel extends StatelessWidget {
  final String label;
  final AppColors colors;
  const _FormLabel({required this.label, required this.colors});

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

class _ErrorText extends StatelessWidget {
  final String label;
  final AppColors colors;
  const _ErrorText({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      label,
      style: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: colors.errorSub,
      ),
    ),
  );
}

class _StyledTextField extends StatelessWidget {
  final AppColors colors;
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;

  const _StyledTextField({
    required this.colors,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.suffixIcon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    maxLines: maxLines,
    keyboardType: keyboardType,
    inputFormatters: inputFormatters,
    onChanged: onChanged,
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
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

class _FormDropdownTile extends StatelessWidget {
  final AppColors colors;
  final String placeholder;
  final String? value;
  final bool isOpen;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _FormDropdownTile({
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
        color: colors.backgroundElevation1,
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
              size: 20,
            ),
        ],
      ),
    ),
  );
}

class _FormOptionsList extends StatelessWidget {
  final AppColors colors;
  final List<Map<String, dynamic>> items;
  final int? selectedId;
  final ValueChanged<Map<String, dynamic>> onSelect;

  const _FormOptionsList({
    required this.colors,
    required this.items,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: colors.backgroundElevation1,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
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
              final selected = item['id'] == selectedId;
              return InkWell(
                onTap: () => onSelect(item),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  color: selected ? colors.accentDisabled : Colors.transparent,
                  child: Text(
                    item['title'] as String? ?? '',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      color: colors.textStrong,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
  );
}

class _PaymentOptionsList extends StatelessWidget {
  final AppColors colors;
  final List<_Option> options;
  final _Option? selected;
  final ValueChanged<_Option> onSelect;

  const _PaymentOptionsList({
    required this.colors,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: colors.backgroundElevation1,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      border: Border(
        left: BorderSide(color: colors.accentSub),
        right: BorderSide(color: colors.accentSub),
        bottom: BorderSide(color: colors.accentSub),
      ),
    ),
    child: Column(
      children: options.map((opt) {
        final isSelected = selected?.value == opt.value;
        return InkWell(
          onTap: () => onSelect(opt),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            color: isSelected ? colors.accentDisabled : Colors.transparent,
            child: Text(
              opt.label,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: colors.textStrong,
              ),
            ),
          ),
        );
      }).toList(),
    ),
  );
}

import 'package:dcmanagement/api/api.dart';
import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/services/auth_service.dart';
import 'package:flutter/material.dart';

Future<void> showExpenseRequestForm(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ExpenseRequestForm(),
  );
}

// ── Payment method options ────────────────────────────────────────────────────

const _paymentOptions = [
  _Option(value: 'cash', label: "Naqt pul orqali"),
  _Option(value: 'card', label: "Karta orqali"),
];

class _Option {
  final String value;
  final String label;
  const _Option({required this.value, required this.label});
}

// ── Main form widget ──────────────────────────────────────────────────────────

class _ExpenseRequestForm extends StatefulWidget {
  const _ExpenseRequestForm();

  @override
  State<_ExpenseRequestForm> createState() => _ExpenseRequestFormState();
}

class _ExpenseRequestFormState extends State<_ExpenseRequestForm> {
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

  bool _loadingDropdowns = true;
  bool _submitting = false;

  String? _openDropdown; // 'project','category','toifa','payment'

  // Validation errors
  bool _projectError = false;
  bool _reasonError = false;

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
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
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString(),
                style: const TextStyle(fontFamily: 'Manrope')),
            backgroundColor: Colors.red.shade700,
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

    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: BoxDecoration(
        color: colors.backgroundBase,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
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
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
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

          const SizedBox(height: 4),
          Divider(color: colors.strokeSub, height: 1),

          // Form
          Expanded(
            child: _loadingDropdowns
                ? Center(
                    child:
                        CircularProgressIndicator(color: colors.accentSub))
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
                          ),
                          if (_projectError)
                            _ErrorText(colors: colors),
                          if (_openDropdown == 'project')
                            _FormOptionsList(
                              colors: colors,
                              items: _projects,
                              selectedId:
                                  _selectedProject?['id'] as int?,
                              onSelect: (item) => setState(() {
                                _selectedProject = item;
                                _projectError = false;
                                _openDropdown = null;
                              }),
                            ),

                          const SizedBox(height: 14),

                          // Xarajat turi
                          _FormLabel(
                              label: 'Xarajat turi', colors: colors),
                          _FormDropdownTile(
                            colors: colors,
                            placeholder: 'Xarajat turini tanlang',
                            value: _selectedCategory?['title'] as String?,
                            isOpen: _openDropdown == 'category',
                            onTap: () => _toggleDropdown('category'),
                          ),
                          if (_openDropdown == 'category')
                            _FormOptionsList(
                              colors: colors,
                              items: _categories,
                              selectedId:
                                  _selectedCategory?['id'] as int?,
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
                          TextField(
                            controller: _amountCtrl,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: colors.textStrong,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Summani kiriting: 0,00',
                              hintStyle: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 14,
                                color: colors.textSoft,
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 14),
                              filled: true,
                              fillColor: colors.backgroundBase,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: colors.strokeSub),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: colors.strokeSub),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: colors.accentSub),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Sababi
                          _FormLabel(label: 'Sababi', colors: colors),
                          TextField(
                            controller: _reasonCtrl,
                            maxLines: 4,
                            onChanged: (_) {
                              if (_reasonError) {
                                setState(() => _reasonError = false);
                              }
                            },
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: colors.textStrong,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Sababini yozing',
                              hintStyle: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 14,
                                color: colors.textSoft,
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 14),
                              filled: true,
                              fillColor: colors.backgroundBase,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: colors.strokeSub),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: colors.strokeSub),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: colors.accentSub),
                              ),
                              suffixIcon: _reasonCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.close,
                                          color: colors.iconSub, size: 18),
                                      onPressed: () => setState(
                                          () => _reasonCtrl.clear()),
                                    )
                                  : null,
                            ),
                          ),
                          if (_reasonError) _ErrorText(colors: colors),

                          const SizedBox(height: 14),

                          // To'lov turi
                          _FormLabel(
                              label: "To'lov turi", colors: colors),
                          _FormDropdownTile(
                            colors: colors,
                            placeholder: "To'lov turini tanlang",
                            value: _selectedPayment?.label,
                            isOpen: _openDropdown == 'payment',
                            onTap: () => _toggleDropdown('payment'),
                          ),
                          if (_openDropdown == 'payment')
                            Container(
                              decoration: BoxDecoration(
                                color: colors.backgroundBase,
                                borderRadius: const BorderRadius.vertical(
                                    bottom: Radius.circular(12)),
                                border: Border(
                                  left: BorderSide(
                                      color: colors.accentSub),
                                  right: BorderSide(
                                      color: colors.accentSub),
                                  bottom: BorderSide(
                                      color: colors.accentSub),
                                ),
                              ),
                              child: Column(
                                children: _paymentOptions.map((opt) {
                                  final selected =
                                      _selectedPayment?.value ==
                                          opt.value;
                                  return InkWell(
                                    onTap: () => setState(() {
                                      _selectedPayment = opt;
                                      _openDropdown = null;
                                    }),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 14),
                                      color: selected
                                          ? colors.accentDisabled
                                          : Colors.transparent,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              opt.label,
                                              style: TextStyle(
                                                fontFamily: 'Manrope',
                                                fontSize: 14,
                                                fontWeight: selected
                                                    ? FontWeight.w900
                                                    : FontWeight.w500,
                                                color: colors.textStrong,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

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
                      borderRadius: BorderRadius.circular(16)),
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
      ),
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
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colors.textSub,
          ),
        ),
      );
}

class _ErrorText extends StatelessWidget {
  final AppColors colors;
  const _ErrorText({required this.colors});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          'Bu maydon majburiy',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colors.errorSub,
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

  const _FormDropdownTile({
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
                  final selected = item['id'] == selectedId;
                  return InkWell(
                    onTap: () => onSelect(item),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      color: selected
                          ? colors.accentDisabled
                          : Colors.transparent,
                      child: Text(
                        item['title'] as String? ?? '',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 14,
                          fontWeight: selected
                              ? FontWeight.w900
                              : FontWeight.w500,
                          color: colors.textStrong,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
      );
}

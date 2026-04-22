import 'package:dcmanagement/api/api.dart';
import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/services/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Future<bool> showExpenseRequestForm(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ExpenseRequestSheet(),
  );
  return result == true;
}

class _ExpenseRequestSheet extends StatefulWidget {
  const _ExpenseRequestSheet();

  @override
  State<_ExpenseRequestSheet> createState() => _ExpenseRequestSheetState();
}

class _ExpenseRequestSheetState extends State<_ExpenseRequestSheet> {
  final _api = ApiService();
  final _auth = AuthService();
  final _amountCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _cardCtrl = TextEditingController();

  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _categories = [];

  Map<String, dynamic>? _selectedProject;
  Map<String, dynamic>? _selectedCategory;
  _Option? _selectedPayment;

  bool _loadingDropdowns = true;
  bool _submitting = false;
  bool _success = false;
  String? _submitError;

  static const _paymentOptions = [
    _Option(value: 'cash', label: 'Naqd pul'),
    _Option(value: 'card', label: 'Plastik karta'),
    _Option(value: 'transfer', label: "Bank o'tkazmasi"),
  ];

  bool get _isCard => _selectedPayment?.value == 'card';

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    _cardCtrl.dispose();
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
      if (mounted) {
        setState(() {
          _projects = results[0];
          _categories = results[1];
          _loadingDropdowns = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingDropdowns = false);
    }
  }

  Future<void> _submit() async {
    final amount = _amountCtrl.text.trim();
    final reason = _reasonCtrl.text.trim();

    if (_selectedProject == null ||
        _selectedCategory == null ||
        amount.isEmpty ||
        reason.isEmpty ||
        _selectedPayment == null) {
      setState(
        () => _submitError = "Iltimos barcha majburiy maydonlarni to'ldiring",
      );
      return;
    }
    if (_isCard && _cardCtrl.text.trim().isEmpty) {
      setState(() => _submitError = "Plastik karta raqamini kiriting");
      return;
    }

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      final token = await _auth.getToken();
      if (token == null) throw Exception('Token topilmadi');

      final body = <String, dynamic>{
        'type': 'withdrawal',
        'project': _selectedProject!['id'],
        'expense_category': _selectedCategory!['id'],
        'amount': amount,
        'reason': reason,
        'payment_method': _selectedPayment!.value,
        if (_isCard) 'card_number': _cardCtrl.text.trim(),
      };

      await _api.createExpenseRequest(token, body);

      if (mounted) {
        setState(() {
          _submitting = false;
          _success = true;
        });
        await Future.delayed(const Duration(milliseconds: 1800));
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e, stack) {
      debugPrint('=== EXPENSE FORM SUBMIT ERROR: $e ===');
      debugPrint('=== STACK: $stack ===');
      if (mounted) {
        setState(() {
          _submitting = false;
          _submitError = e.toString();
        });
      }
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
      child: _success ? _buildSuccess(colors) : _buildForm(colors),
    );
  }

  Widget _buildSuccess(AppColors colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colors.successStrong.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              color: colors.successStrong,
              size: 38,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "So'rov yuborildi!",
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: colors.textStrong,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Xarajat so'rovingiz muvaffaqiyatli yuborildi",
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              color: colors.textSub,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(AppColors colors) {
    return Column(
      children: [
        // ── Header ────────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "So'rov yuborish",
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: colors.textStrong,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(false),
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.backgroundElevation2,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: colors.iconSub,
                  ),
                ),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        // ── Scrollable fields ─────────────────────────────────────────────────
        Expanded(
          child: _loadingDropdowns
              ? Center(
                  child: CircularProgressIndicator(color: colors.accentSub),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Loyiha *', colors),
                      const SizedBox(height: 6),
                      FloatingDropdown(
                        placeholder: 'Loyihani tanlang',
                        value: _selectedProject?['title'] as String?,
                        items: _projects,
                        selectedId: _selectedProject?['id'] as int?,
                        colors: colors,
                        onSelect: (item) =>
                            setState(() => _selectedProject = item),
                        onClear: () => setState(() => _selectedProject = null),
                      ),
                      const SizedBox(height: 16),

                      _label('Xarajat turi *', colors),
                      const SizedBox(height: 6),
                      FloatingDropdown(
                        placeholder: 'Xarajat turini tanlang',
                        value: _selectedCategory?['title'] as String?,
                        items: _categories,
                        selectedId: _selectedCategory?['id'] as int?,
                        colors: colors,
                        onSelect: (item) =>
                            setState(() => _selectedCategory = item),
                        onClear: () => setState(() => _selectedCategory = null),
                      ),
                      const SizedBox(height: 16),

                      _label("To'lov usuli *", colors),
                      const SizedBox(height: 6),
                      FloatingPaymentDropdown(
                        placeholder: "To'lov usulini tanlang",
                        options: _paymentOptions,
                        selected: _selectedPayment,
                        colors: colors,
                        onSelect: (opt) {
                          setState(() {
                            _selectedPayment = opt;
                            if (opt.value != 'card') _cardCtrl.clear();
                          });
                        },
                        onClear: () {
                          setState(() {
                            _selectedPayment = null;
                            _cardCtrl.clear();
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      if (_isCard) ...[
                        _label('Karta raqami *', colors),
                        const SizedBox(height: 6),
                        _textField(
                          controller: _cardCtrl,
                          hint: '0000 0000 0000 0000',
                          colors: colors,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                      ],

                      _label('Summa *', colors),
                      const SizedBox(height: 6),
                      _textField(
                        controller: _amountCtrl,
                        hint: '0.00',
                        colors: colors,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _label('Sabab *', colors),
                      const SizedBox(height: 6),
                      _textField(
                        controller: _reasonCtrl,
                        hint: 'Xarajat sababi...',
                        colors: colors,
                        maxLines: 3,
                      ),

                      if (_submitError != null) ...[
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 15,
                              color: colors.errorSub,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _submitError!,
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 13,
                                  color: colors.errorSub,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        ),

        // ── Submit button ─────────────────────────────────────────────────────
        if (!_loadingDropdowns)
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentSub,
                  foregroundColor: colors.textWhite,
                  disabledBackgroundColor: colors.accentDisabled,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _submitting
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: colors.textWhite,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Yuborish',
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

  Widget _label(String text, AppColors colors) => Text(
    text,
    style: TextStyle(
      fontFamily: 'Manrope',
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: colors.textSub,
    ),
  );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required AppColors colors,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(
        fontFamily: 'Manrope',
        fontWeight: FontWeight.w500,
        color: colors.textStrong,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontFamily: 'Manrope', color: colors.textSoft),
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
        filled: true,
        fillColor: colors.backgroundElevation1,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }
}

// ── Floating Dropdown ─────────────────────────────────────────────────────────

class FloatingDropdown extends StatefulWidget {
  final String placeholder;
  final String? value;
  final List<Map<String, dynamic>> items;
  final int? selectedId;
  final ValueChanged<Map<String, dynamic>> onSelect;
  final VoidCallback? onClear;
  final AppColors colors;

  const FloatingDropdown({
    super.key,
    required this.placeholder,
    required this.value,
    required this.items,
    required this.selectedId,
    required this.onSelect,
    required this.colors,
    this.onClear,
  });

  @override
  State<FloatingDropdown> createState() => _FloatingDropdownState();
}

class _FloatingDropdownState extends State<FloatingDropdown> {
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
                    color: colors.shadow.withValues(alpha: 0.08),
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

// ── Payment Dropdown ──────────────────────────────────────────────────────────

class FloatingPaymentDropdown extends StatefulWidget {
  final String placeholder;
  final List<_Option> options;
  final _Option? selected;
  final ValueChanged<_Option> onSelect;
  final VoidCallback? onClear;
  final AppColors colors;

  const FloatingPaymentDropdown({
    super.key,
    required this.placeholder,
    required this.options,
    required this.selected,
    required this.onSelect,
    required this.colors,
    this.onClear,
  });

  @override
  State<FloatingPaymentDropdown> createState() =>
      _FloatingPaymentDropdownState();
}

class _FloatingPaymentDropdownState extends State<FloatingPaymentDropdown> {
  final _key = GlobalKey();
  OverlayEntry? _entry;
  bool _isOpen = false;

  void _open() {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;

    _entry = OverlayEntry(
      builder: (_) => _PaymentOverlay(
        top: offset.dy + size.height + 6,
        left: offset.dx,
        width: size.width,
        options: widget.options,
        selected: widget.selected,
        colors: widget.colors,
        onSelect: (opt) {
          _close();
          widget.onSelect(opt);
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
                widget.selected?.label ?? widget.placeholder,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: widget.selected != null
                      ? colors.textStrong
                      : colors.textSoft,
                ),
              ),
            ),
            if (widget.selected != null && widget.onClear != null)
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

class _PaymentOverlay extends StatelessWidget {
  final double top;
  final double left;
  final double width;
  final List<_Option> options;
  final _Option? selected;
  final AppColors colors;
  final ValueChanged<_Option> onSelect;
  final VoidCallback onDismiss;

  const _PaymentOverlay({
    required this.top,
    required this.left,
    required this.width,
    required this.options,
    required this.selected,
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
              decoration: BoxDecoration(
                color: colors.backgroundElevation1,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.strokeSub),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: options.map((opt) {
                    final isSelected = selected?.value == opt.value;
                    return InkWell(
                      onTap: () => onSelect(opt),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        color: isSelected
                            ? colors.accentDisabled
                            : Colors.transparent,
                        child: Text(
                          opt.label,
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 14,
                            fontWeight: isSelected
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

class _Option {
  final String value;
  final String label;
  const _Option({required this.value, required this.label});
}

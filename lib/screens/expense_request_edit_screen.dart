import 'package:dcmanagement/api/api.dart';
import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/screens/expense_request_form_sheet.dart';
import 'package:dcmanagement/services/auth_service.dart';
import 'package:flutter/material.dart';

class ExpenseRequestEditScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;

  const ExpenseRequestEditScreen({super.key, required this.initialData});

  @override
  State<ExpenseRequestEditScreen> createState() =>
      _ExpenseRequestEditScreenState();
}

class _ExpenseRequestEditScreenState extends State<ExpenseRequestEditScreen> {
  final _api = ApiService();
  final _auth = AuthService();
  final _amountCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _cardCtrl = TextEditingController();

  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _categories = [];

  Map<String, dynamic>? _selectedProject;
  Map<String, dynamic>? _selectedCategory;
  _PayOption? _selectedPayment;

  bool _loadingDropdowns = true;
  bool _submitting = false;
  bool _success = false;
  String? _submitError;

  static const _paymentOptions = [
    _PayOption(value: 'cash', label: 'Naqd pul'),
    _PayOption(value: 'card', label: 'Plastik karta'),
    _PayOption(value: 'transfer', label: "Bank o'tkazmasi"),
  ];

  bool get _isCard => _selectedPayment?.value == 'card';

  int get _id => widget.initialData['id'] as int;

  @override
  void initState() {
    super.initState();
    _prefill();
    _loadDropdowns();
  }

  void _prefill() {
    final data = widget.initialData;
    _amountCtrl.text = data['amount']?.toString() ?? '';
    _reasonCtrl.text = data['reason'] as String? ?? '';
    _cardCtrl.text = data['card_number'] as String? ?? '';

    final pm = data['payment_method'] as String?;
    if (pm != null) {
      _selectedPayment = _paymentOptions.where((o) => o.value == pm).firstOrNull;
    }

    final project = data['project_info'] as Map<String, dynamic>?;
    if (project != null && project['id'] != null) {
      _selectedProject = project;
    }

    final category = data['expense_category_info'] as Map<String, dynamic>?;
    if (category != null && category['id'] != null) {
      _selectedCategory = category;
    }
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

      await _api.updateExpenseRequest(token, _id, {
        'type': widget.initialData['type'] ?? 'withdrawal',
        'project': _selectedProject!['id'],
        'expense_category': _selectedCategory!['id'],
        'amount': amount,
        'reason': reason,
        'payment_method': _selectedPayment!.value,
        'card_number': _isCard ? _cardCtrl.text.trim() : '',
      });

      if (mounted) {
        setState(() {
          _submitting = false;
          _success = true;
        });
        await Future.delayed(const Duration(milliseconds: 1400));
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
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

    return Scaffold(
      backgroundColor: colors.backgroundBase,
      appBar: AppBar(
        backgroundColor: colors.backgroundBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textStrong),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: Text(
          "So'rovni tahrirlash",
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: colors.textStrong,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _success ? _buildSuccess(colors) : _buildForm(colors),
      ),
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
            child:
                Icon(Icons.check_rounded, color: colors.successStrong, size: 38),
          ),
          const SizedBox(height: 20),
          Text(
            "Muvaffaqiyatli yangilandi!",
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: colors.textStrong,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Xarajat so'rovingiz yangilandi",
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
        Expanded(
          child: _loadingDropdowns
              ? Center(child: CircularProgressIndicator(color: colors.accentSub))
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
                      _PaymentDropdown(
                        options: _paymentOptions,
                        selected: _selectedPayment,
                        colors: colors,
                        onSelect: (opt) => setState(() {
                          _selectedPayment = opt;
                          if (opt.value != 'card') _cardCtrl.clear();
                        }),
                        onClear: () => setState(() {
                          _selectedPayment = null;
                          _cardCtrl.clear();
                        }),
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
                            decimal: true),
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
                            Icon(Icons.error_outline_rounded,
                                size: 15, color: colors.errorSub),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _submitError!,
                                style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 13,
                                    color: colors.errorSub),
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
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _submitting
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: colors.textWhite, strokeWidth: 2.5),
                      )
                    : const Text(
                        'Saqlash',
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

// ── Payment Dropdown ──────────────────────────────────────────────────────────

class _PayOption {
  final String value;
  final String label;
  const _PayOption({required this.value, required this.label});
}

class _PaymentDropdown extends StatefulWidget {
  final List<_PayOption> options;
  final _PayOption? selected;
  final ValueChanged<_PayOption> onSelect;
  final VoidCallback? onClear;
  final AppColors colors;

  const _PaymentDropdown({
    required this.options,
    required this.selected,
    required this.onSelect,
    required this.colors,
    this.onClear,
  });

  @override
  State<_PaymentDropdown> createState() => _PaymentDropdownState();
}

class _PaymentDropdownState extends State<_PaymentDropdown> {
  final _key = GlobalKey();
  OverlayEntry? _entry;
  bool _isOpen = false;

  void _open() {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    _entry = OverlayEntry(
      builder: (_) => _Overlay(
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
              color: _isOpen ? colors.accentSub : colors.strokeSub),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.selected?.label ?? "To'lov usulini tanlang",
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
                  child:
                      Icon(Icons.close_rounded, color: colors.iconSub, size: 20),
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

class _Overlay extends StatelessWidget {
  final double top;
  final double left;
  final double width;
  final List<_PayOption> options;
  final _PayOption? selected;
  final AppColors colors;
  final ValueChanged<_PayOption> onSelect;
  final VoidCallback onDismiss;

  const _Overlay({
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
                    final isSel = selected?.value == opt.value;
                    return InkWell(
                      onTap: () => onSelect(opt),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        color: isSel
                            ? colors.accentDisabled
                            : Colors.transparent,
                        child: Text(
                          opt.label,
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 14,
                            fontWeight:
                                isSel ? FontWeight.w700 : FontWeight.w500,
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

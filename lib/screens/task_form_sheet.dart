import 'package:dcmanagement/api/api.dart';
import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/models/user_model.dart';
import 'package:dcmanagement/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

Future<bool> showTaskForm(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _TaskFormSheet(),
  );
  return result == true;
}

class _TaskFormSheet extends StatefulWidget {
  const _TaskFormSheet();

  @override
  State<_TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<_TaskFormSheet> {
  final _api = ApiService();
  final _auth = AuthService();

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _penaltyCtrl = TextEditingController();

  List<Map<String, dynamic>> _projects = [];
  List<UserModel> _users = [];
  bool _loadingDropdowns = true;
  bool _submitting = false;
  bool _success = false;
  String? _error;

  Map<String, dynamic>? _selectedProject;
  _Option? _selectedPriority;
  _Option? _selectedType;
  UserModel? _selectedAssignee;

  DateTime? _deadlineDate;
  TimeOfDay? _deadlineTime;
  int _estHours = 0;
  int _estMinutes = 0;

  static const _priorityOptions = [
    _Option('low', "Past"),
    _Option('medium', "O'rta"),
    _Option('high', 'Yuqori'),
  ];

  static const _typeOptions = [
    _Option('bug', 'Bug'),
    _Option('feature', 'Yangi imkoniyat'),
    _Option('task', 'Vazifa'),
    _Option('improvement', 'Yaxshilash'),
    _Option('test', 'Test'),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _penaltyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final token = await _auth.getToken();
      if (token == null) return;
      final results = await Future.wait([
        _api.getProjects(token),
        _api.getUsers(token),
      ]);
      if (mounted) {
        setState(() {
          _projects = results[0] as List<Map<String, dynamic>>;
          _users = results[1] as List<UserModel>;
          _loadingDropdowns = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingDropdowns = false);
    }
  }

  String _formatDeadline() {
    if (_deadlineDate == null) return '—';
    final d = _deadlineDate!;
    final t = _deadlineTime ?? const TimeOfDay(hour: 0, minute: 0);
    final dt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    return dt.toUtc().toIso8601String();
  }

  Future<void> _pickDate(AppColors colors) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadlineDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: colors.accentSub,
            onPrimary: colors.white,
            surface: colors.backgroundElevation1,
            onSurface: colors.textStrong,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deadlineDate = picked);
  }

  Future<void> _pickTime(AppColors colors) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _deadlineTime ?? const TimeOfDay(hour: 0, minute: 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: colors.accentSub,
            onPrimary: colors.white,
            surface: colors.backgroundElevation1,
            onSurface: colors.textStrong,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deadlineTime = picked);
  }

  Future<void> _pickEstimated(AppColors colors) async {
    int tempH = _estHours;
    int tempM = _estMinutes;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: colors.backgroundElevation1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Taxminiy vaqt',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w800,
              color: colors.textStrong,
            ),
          ),
          content: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Soat',
                        style: TextStyle(
                            fontFamily: 'Manrope', color: colors.textSub)),
                    const SizedBox(height: 8),
                    _NumberSpinner(
                      value: tempH,
                      min: 0,
                      max: 99,
                      colors: colors,
                      onChanged: (v) => setLocal(() => tempH = v),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(':',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: colors.textStrong)),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Daqiqa',
                        style: TextStyle(
                            fontFamily: 'Manrope', color: colors.textSub)),
                    const SizedBox(height: 8),
                    _NumberSpinner(
                      value: tempM,
                      min: 0,
                      max: 59,
                      colors: colors,
                      onChanged: (v) => setLocal(() => tempM = v),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Bekor',
                  style: TextStyle(
                      fontFamily: 'Manrope', color: colors.textSub)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _estHours = tempH;
                  _estMinutes = tempM;
                });
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentSub,
                foregroundColor: colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('OK',
                  style: TextStyle(fontFamily: 'Manrope')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    if (_selectedProject == null || title.isEmpty) {
      setState(() => _error = "Loyiha va nomni to'ldiring");
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final token = await _auth.getToken();
      if (token == null) throw Exception('Token topilmadi');

      final body = <String, dynamic>{
        'project': _selectedProject!['id'],
        'title': title,
        'description': _descCtrl.text.trim(),
        'status': 'todo',
        'priority': _selectedPriority?.value ?? 'medium',
        'type': _selectedType?.value ?? 'task',
        if (_selectedAssignee != null) 'assignee': _selectedAssignee!.id,
        if (_deadlineDate != null) 'deadline': _formatDeadline(),
        if (_priceCtrl.text.trim().isNotEmpty)
          'task_price': _priceCtrl.text.trim(),
        if (_penaltyCtrl.text.trim().isNotEmpty)
          'penalty_percentage': _penaltyCtrl.text.trim(),
        'estimated_input_hours': _estHours,
        'estimated_input_minutes': _estMinutes,
      };

      await _api.createTask(token, body);

      if (mounted) {
        setState(() {
          _submitting = false;
          _success = true;
        });
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = e.toString();
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
            child: Icon(Icons.check_rounded,
                color: colors.successStrong, size: 38),
          ),
          const SizedBox(height: 20),
          Text(
            'Vazifa yaratildi!',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: colors.textStrong,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yangi vazifa muvaffaqiyatli qo\'shildi',
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
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: Text(
                  "Vazifa qo'shish",
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: colors.textStrong,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: Icon(Icons.close_rounded,
                      size: 20, color: colors.iconSub),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),

        // Form
        Expanded(
          child: _loadingDropdowns
              ? Center(
                  child: CircularProgressIndicator(color: colors.accentSub))
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Loyiha
                      _label('Loyiha', colors),
                      const SizedBox(height: 6),
                      _ProjectDropdown(
                        placeholder: 'Loyiha tanlang',
                        value: _selectedProject?['title'] as String?,
                        items: _projects,
                        selectedId: _selectedProject?['id'] as int?,
                        colors: colors,
                        onSelect: (item) =>
                            setState(() => _selectedProject = item),
                        onClear: () =>
                            setState(() => _selectedProject = null),
                      ),
                      const SizedBox(height: 16),

                      // Nomi
                      _label('Nomi', colors),
                      const SizedBox(height: 6),
                      _textField(
                          ctrl: _titleCtrl,
                          hint: 'Nomi kiriting',
                          colors: colors),
                      const SizedBox(height: 16),

                      // Tavsifi
                      _label('Tavsifi', colors),
                      const SizedBox(height: 6),
                      _textField(
                          ctrl: _descCtrl,
                          hint: 'Tavsif yozing',
                          colors: colors,
                          maxLines: 3),
                      const SizedBox(height: 16),

                      // Darajasi
                      _label('Darajasi', colors),
                      const SizedBox(height: 6),
                      _OptionDropdown(
                        placeholder: 'Darajasi tanlang',
                        options: _priorityOptions,
                        selected: _selectedPriority,
                        colors: colors,
                        onSelect: (o) =>
                            setState(() => _selectedPriority = o),
                        onClear: () =>
                            setState(() => _selectedPriority = null),
                      ),
                      const SizedBox(height: 16),

                      // Turi
                      _label('Turi', colors),
                      const SizedBox(height: 6),
                      _OptionDropdown(
                        placeholder: 'Turi tanlang',
                        options: _typeOptions,
                        selected: _selectedType,
                        colors: colors,
                        onSelect: (o) =>
                            setState(() => _selectedType = o),
                        onClear: () => setState(() => _selectedType = null),
                      ),
                      const SizedBox(height: 16),

                      // Topshiruvchi
                      _label('Topshiruvchi', colors),
                      const SizedBox(height: 6),
                      _UserDropdown(
                        placeholder: 'Topshiruvchi',
                        users: _users,
                        selected: _selectedAssignee,
                        colors: colors,
                        onSelect: (u) =>
                            setState(() => _selectedAssignee = u),
                        onClear: () =>
                            setState(() => _selectedAssignee = null),
                      ),
                      const SizedBox(height: 16),

                      // Vazifa narxi
                      _label('Vazifa narxi (UZS)', colors),
                      const SizedBox(height: 6),
                      _textField(
                        ctrl: _priceCtrl,
                        hint: '0,00',
                        colors: colors,
                        textAlign: TextAlign.right,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,\-]'))
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Jarima foizi
                      _label('Jarima foizi (%)', colors),
                      const SizedBox(height: 6),
                      _textField(
                        ctrl: _penaltyCtrl,
                        hint: 'Jarima',
                        colors: colors,
                      ),
                      const SizedBox(height: 16),

                      // Muddat sanasi + Soati
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Muddat sanasi', colors),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () => _pickDate(colors),
                                  child: _FieldBox(
                                    colors: colors,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _deadlineDate != null
                                                ? DateFormat('dd.MM.yyyy')
                                                    .format(_deadlineDate!)
                                                : '01.01.2026',
                                            style: TextStyle(
                                              fontFamily: 'Manrope',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: _deadlineDate != null
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
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Soati', colors),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () => _pickTime(colors),
                                  child: _FieldBox(
                                    colors: colors,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _deadlineTime != null
                                                ? '${_deadlineTime!.hour.toString().padLeft(2, '0')}:${_deadlineTime!.minute.toString().padLeft(2, '0')}'
                                                : '00:00',
                                            style: TextStyle(
                                              fontFamily: 'Manrope',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: _deadlineTime != null
                                                  ? colors.textStrong
                                                  : colors.textSoft,
                                            ),
                                          ),
                                        ),
                                        Icon(Icons.access_time_rounded,
                                            size: 18, color: colors.iconSub),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Taxminiy vaqt
                      _label('Taxminiy vaqt', colors),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => _pickEstimated(colors),
                        child: _FieldBox(
                          colors: colors,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${_estHours.toString().padLeft(2, '0')}:${_estMinutes.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: (_estHours > 0 || _estMinutes > 0)
                                        ? colors.textStrong
                                        : colors.textSoft,
                                  ),
                                ),
                              ),
                              Icon(Icons.access_time_rounded,
                                  size: 18, color: colors.iconSub),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Fayl yuklash
                      _label("Qo'shimcha fayllar", colors),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: colors.backgroundElevation1,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colors.accentSub.withValues(alpha: 0.4),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.attach_file_rounded,
                                color: colors.accentSub, size: 22),
                            const SizedBox(height: 6),
                            Text(
                              'Fayl yuklash',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colors.accentSub,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Error
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.error_outline_rounded,
                                size: 15, color: colors.errorSub),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _error!,
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

        // Submit
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
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Vazifa qo'shish",
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ],
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
    required TextEditingController ctrl,
    required String hint,
    required AppColors colors,
    int maxLines = 1,
    TextAlign textAlign = TextAlign.start,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      textAlign: textAlign,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
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

// ── Field Box (date/time pickers uchun) ───────────────────────────────────────

class _FieldBox extends StatelessWidget {
  final AppColors colors;
  final Widget child;
  const _FieldBox({required this.colors, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      decoration: BoxDecoration(
        color: colors.backgroundElevation1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.strokeSub),
      ),
      child: child,
    );
  }
}

// ── Number Spinner (soat/daqiqa) ──────────────────────────────────────────────

class _NumberSpinner extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final AppColors colors;
  final ValueChanged<int> onChanged;

  const _NumberSpinner({
    required this.value,
    required this.min,
    required this.max,
    required this.colors,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: value > min ? () => onChanged(value - 1) : null,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.backgroundElevation2,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.remove_rounded,
                size: 18,
                color: value > min ? colors.textStrong : colors.textSoft),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 40,
          child: Text(
            value.toString().padLeft(2, '0'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: colors.textStrong,
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: value < max ? () => onChanged(value + 1) : null,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.backgroundElevation2,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.add_rounded,
                size: 18,
                color: value < max ? colors.textStrong : colors.textSoft),
          ),
        ),
      ],
    );
  }
}

// ── Dropdowns ─────────────────────────────────────────────────────────────────

class _Option {
  final String value;
  final String label;
  const _Option(this.value, this.label);
}

class _OptionDropdown extends StatefulWidget {
  final String placeholder;
  final List<_Option> options;
  final _Option? selected;
  final AppColors colors;
  final ValueChanged<_Option> onSelect;
  final VoidCallback? onClear;

  const _OptionDropdown({
    required this.placeholder,
    required this.options,
    required this.selected,
    required this.colors,
    required this.onSelect,
    this.onClear,
  });

  @override
  State<_OptionDropdown> createState() => _OptionDropdownState();
}

class _OptionDropdownState extends State<_OptionDropdown> {
  final _key = GlobalKey();
  OverlayEntry? _entry;
  bool _isOpen = false;

  void _open() {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    _entry = OverlayEntry(
      builder: (_) => _OverlayList(
        top: offset.dy + size.height + 6,
        left: offset.dx,
        width: size.width,
        colors: widget.colors,
        onDismiss: _close,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.options.map((opt) {
            final sel = opt.value == widget.selected?.value;
            return InkWell(
              onTap: () {
                _close();
                widget.onSelect(opt);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 13),
                color: sel
                    ? widget.colors.accentDisabled
                    : Colors.transparent,
                child: Text(
                  opt.label,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    color: widget.colors.textStrong,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
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
      child: _DropdownTile(
        label: widget.selected?.label ?? widget.placeholder,
        hasValue: widget.selected != null,
        isOpen: _isOpen,
        colors: colors,
        onClear: widget.selected != null && widget.onClear != null
            ? () {
                _close();
                widget.onClear!();
              }
            : null,
      ),
    );
  }
}

class _ProjectDropdown extends StatefulWidget {
  final String placeholder;
  final String? value;
  final List<Map<String, dynamic>> items;
  final int? selectedId;
  final AppColors colors;
  final ValueChanged<Map<String, dynamic>> onSelect;
  final VoidCallback? onClear;

  const _ProjectDropdown({
    required this.placeholder,
    required this.value,
    required this.items,
    required this.selectedId,
    required this.colors,
    required this.onSelect,
    this.onClear,
  });

  @override
  State<_ProjectDropdown> createState() => _ProjectDropdownState();
}

class _ProjectDropdownState extends State<_ProjectDropdown> {
  final _key = GlobalKey();
  OverlayEntry? _entry;
  bool _isOpen = false;

  void _open() {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    _entry = OverlayEntry(
      builder: (_) => _OverlayList(
        top: offset.dy + size.height + 6,
        left: offset.dx,
        width: size.width,
        colors: widget.colors,
        onDismiss: _close,
        child: widget.items.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(14),
                child: Text('Mavjud emas',
                    style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 13,
                        color: widget.colors.textSoft)),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: widget.items.map((item) {
                  final sel = item['id'] == widget.selectedId;
                  return InkWell(
                    onTap: () {
                      _close();
                      widget.onSelect(item);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                      color: sel
                          ? widget.colors.accentDisabled
                          : Colors.transparent,
                      child: Text(
                        item['title'] as String? ?? '',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 14,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                          color: widget.colors.textStrong,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
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
    return GestureDetector(
      key: _key,
      onTap: _isOpen ? _close : _open,
      child: _DropdownTile(
        label: widget.value ?? widget.placeholder,
        hasValue: widget.value != null,
        isOpen: _isOpen,
        colors: widget.colors,
        onClear: widget.value != null && widget.onClear != null
            ? () {
                _close();
                widget.onClear!();
              }
            : null,
      ),
    );
  }
}

class _UserDropdown extends StatefulWidget {
  final String placeholder;
  final List<dynamic> users;
  final dynamic selected;
  final AppColors colors;
  final ValueChanged<dynamic> onSelect;
  final VoidCallback? onClear;

  const _UserDropdown({
    required this.placeholder,
    required this.users,
    required this.selected,
    required this.colors,
    required this.onSelect,
    this.onClear,
  });

  @override
  State<_UserDropdown> createState() => _UserDropdownState();
}

class _UserDropdownState extends State<_UserDropdown> {
  final _key = GlobalKey();
  OverlayEntry? _entry;
  bool _isOpen = false;

  void _open() {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    _entry = OverlayEntry(
      builder: (_) => _OverlayList(
        top: offset.dy + size.height + 6,
        left: offset.dx,
        width: size.width,
        colors: widget.colors,
        maxHeight: 200,
        onDismiss: _close,
        child: widget.users.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(14),
                child: Text('Foydalanuvchilar mavjud emas',
                    style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 13,
                        color: widget.colors.textSoft)),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: widget.users.map((u) {
                  final username = u.username as String? ?? '';
                  final sel = widget.selected?.id == u.id;
                  return InkWell(
                    onTap: () {
                      _close();
                      widget.onSelect(u);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                      color: sel
                          ? widget.colors.accentDisabled
                          : Colors.transparent,
                      child: Text(
                        username,
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 14,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                          color: widget.colors.textStrong,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
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
    final label = widget.selected?.username as String? ?? widget.placeholder;
    return GestureDetector(
      key: _key,
      onTap: _isOpen ? _close : _open,
      child: _DropdownTile(
        label: label,
        hasValue: widget.selected != null,
        isOpen: _isOpen,
        colors: widget.colors,
        onClear: widget.selected != null && widget.onClear != null
            ? () {
                _close();
                widget.onClear!();
              }
            : null,
      ),
    );
  }
}

// ── Shared Dropdown Tile ──────────────────────────────────────────────────────

class _DropdownTile extends StatelessWidget {
  final String label;
  final bool hasValue;
  final bool isOpen;
  final AppColors colors;
  final VoidCallback? onClear;

  const _DropdownTile({
    required this.label,
    required this.hasValue,
    required this.isOpen,
    required this.colors,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              label,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: hasValue ? colors.textStrong : colors.textSoft,
              ),
            ),
          ),
          if (onClear != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onClear,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child:
                    Icon(Icons.close_rounded, color: colors.iconSub, size: 20),
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
    );
  }
}

// ── Overlay Container ─────────────────────────────────────────────────────────

class _OverlayList extends StatelessWidget {
  final double top;
  final double left;
  final double width;
  final double maxHeight;
  final AppColors colors;
  final VoidCallback onDismiss;
  final Widget child;

  const _OverlayList({
    required this.top,
    required this.left,
    required this.width,
    required this.colors,
    required this.onDismiss,
    required this.child,
    this.maxHeight = 240,
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
              constraints: BoxConstraints(maxHeight: maxHeight),
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
                child: SingleChildScrollView(child: child),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../entities/expense_request/model/expense_request.dart';
import '../model/expense_request_create_notifier.dart';

class ExpenseRequestCreatePage extends ConsumerStatefulWidget {
  const ExpenseRequestCreatePage({super.key});

  @override
  ConsumerState<ExpenseRequestCreatePage> createState() =>
      _ExpenseRequestCreatePageState();
}

class _ExpenseRequestCreatePageState
    extends ConsumerState<ExpenseRequestCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _cardCtrl = TextEditingController();

  String _selectedCardType = '8600';

  static const _cardTypes = [
    ('8600', 'Uzcard (8600...)'),
    ('9860', 'Humo (9860...)'),
    ('4000', 'Visa'),
    ('5000', 'Mastercard'),
  ];

  @override
  void dispose() {
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    _cardCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _cardCtrl.text = _selectedCardType;
  }

  void _onCardTypeChanged(String prefix) {
    setState(() {
      _selectedCardType = prefix;
      final digits = _cardCtrl.text.replaceAll(RegExp(r'\D'), '');
      final tail = digits.length > 4 ? digits.substring(4) : '';
      final raw = (prefix + tail).substring(0, (prefix + tail).length.clamp(0, 16));
      _cardCtrl.text = _formatCardNumber(raw);
      _cardCtrl.selection = TextSelection.collapsed(offset: _cardCtrl.text.length);
    });
  }

  String _formatCardNumber(String digits) {
    final clean = digits.replaceAll(RegExp(r'\D'), '').substring(
          0,
          digits.replaceAll(RegExp(r'\D'), '').length.clamp(0, 16),
        );
    final groups = <String>[];
    for (var i = 0; i < clean.length; i += 4) {
      groups.add(clean.substring(i, (i + 4).clamp(0, clean.length)));
    }
    return groups.join(' ');
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final amount = double.tryParse(_amountCtrl.text.replaceAll(' ', '')) ?? 0;
    final payload = ExpenseRequestCreatePayload(
      amount: amount,
      reason: _reasonCtrl.text.trim(),
      cardNumber: _cardCtrl.text.replaceAll(' ', ''),
    );

    await ref.read(expenseRequestCreateProvider.notifier).submit(payload);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(expenseRequestCreateProvider, (_, state) {
      if (state is ExpenseRequestCreateSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("So'rov muvaffaqiyatli yuborildi"),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else if (state is ExpenseRequestCreateError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.message),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    });

    final formState = ref.watch(expenseRequestCreateProvider);
    final isLoading = formState is ExpenseRequestCreateLoading;

    return Scaffold(
      backgroundColor: AppColors.obsidian,
      appBar: AppBar(
        title: const Text('Yangi xarajat so\'rovi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.gold.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.gold.withAlpha(40)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.gold, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "So'rov tasdiqlanmagunicha karta hisobidan pul yechilmaydi",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Amount
              _SectionLabel(icon: Icons.attach_money, label: 'Miqdor (UZS)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(color: AppColors.ivory),
                decoration: const InputDecoration(
                  hintText: '500 000',
                  prefixText: 'UZS  ',
                  prefixStyle: TextStyle(color: AppColors.silver),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Miqdorni kiriting';
                  final n = double.tryParse(v);
                  if (n == null || n <= 0) return 'Miqdor 0 dan katta bo\'lishi kerak';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Reason
              _SectionLabel(icon: Icons.description_outlined, label: 'Sabab'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonCtrl,
                maxLines: 4,
                maxLength: 500,
                style: const TextStyle(color: AppColors.ivory),
                decoration: const InputDecoration(
                  hintText: 'Xarajat sababi va tafsilotlarini kiriting...',
                  alignLabelWithHint: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().length < 10) {
                    return 'Kamida 10 ta belgi kiriting';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Card type selector
              _SectionLabel(icon: Icons.credit_card_outlined, label: 'Karta turi'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.graphite,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.smoke),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedCardType,
                  dropdownColor: AppColors.graphite,
                  style: const TextStyle(color: AppColors.ivory),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  items: _cardTypes
                      .map((t) => DropdownMenuItem(
                            value: t.$1,
                            child: Text(t.$2),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) _onCardTypeChanged(v);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Card number
              _SectionLabel(icon: null, label: 'Karta raqami'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _cardCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  color: AppColors.ivory,
                  fontFamily: 'monospace',
                  letterSpacing: 1.5,
                ),
                decoration: const InputDecoration(
                  hintText: '8600 0000 0000 0000',
                  helperText: '16 ta raqam',
                ),
                onChanged: (v) {
                  final formatted = _formatCardNumber(v);
                  if (formatted != v) {
                    _cardCtrl.text = formatted;
                    _cardCtrl.selection = TextSelection.collapsed(
                      offset: formatted.length,
                    );
                  }
                },
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Karta raqamini kiriting';
                  final digits = v.replaceAll(RegExp(r'\D'), '');
                  if (digits.length != 16) return 'Karta raqami 16 ta raqamdan iborat';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xl),

              // Submit button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(AppColors.obsidian),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('So\'rov yuborish'),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: isLoading ? null : () => context.pop(),
                child: const Text('Bekor qilish',
                    style: TextStyle(color: AppColors.silver)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData? icon;
  final String label;
  const _SectionLabel({this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: AppColors.silver),
          const SizedBox(width: 6),
        ],
        Text(label, style: AppTextStyles.labelLarge),
      ],
    );
  }
}

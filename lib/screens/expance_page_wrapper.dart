import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/screens/expense_request_form_sheet.dart';
import 'package:flutter/material.dart';

class ExpenseRequestPage extends StatefulWidget {
  const ExpenseRequestPage({super.key});

  @override
  State<ExpenseRequestPage> createState() => _ExpenseRequestPageState();
}

class _ExpenseRequestPageState extends State<ExpenseRequestPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showExpenseRequestForm(context).then((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.backgroundBase,
      body: Center(
        child: CircularProgressIndicator(color: colors.accentSub),
      ),
    );
  }
}

import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/screens/expense_request_form_sheet.dart';
import 'package:flutter/material.dart';

class ExpenseRequestPage extends StatelessWidget {
  const ExpenseRequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.backgroundBase,
      body: SafeArea(
        child: ExpenseRequestForm(), 
      ),
    );
  }
}

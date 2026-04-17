import 'package:dcmanagement/colors/app_colors.dart';
import 'package:flutter/material.dart';

class FinanceHistoryScreen extends StatelessWidget {
  const FinanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.backgroundBase,
      appBar: AppBar(
        backgroundColor: colors.backgroundBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.textStrong),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Tarix',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: colors.textStrong,
          ),
        ),
      ),
      body: const SafeArea(
        child: Center(
          child: Text('Tarix'),
        ),
      ),
    );
  }
}

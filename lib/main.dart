import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/providers/theme_notifier.dart';
import 'package:dcmanagement/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeNotifier.load(); // sets ThemeNotifier.instance
  runApp(MyApp(themeNotifier: ThemeNotifier.instance));
}

ThemeData _buildTheme(Brightness brightness) {
  final base = brightness == Brightness.light
      ? ThemeData.light(useMaterial3: true)
      : ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    textTheme: GoogleFonts.manropeTextTheme(base.textTheme),
    extensions: [
      brightness == Brightness.light ? AppColors.light() : AppColors.dark(),
    ],
  );
}

class MyApp extends StatelessWidget {
  final ThemeNotifier themeNotifier;
  const MyApp({super.key, required this.themeNotifier});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeNotifier,
      builder: (context, child) => MaterialApp.router(
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
        themeMode: themeNotifier.mode,
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
      ),
    );
  }
}

import 'dart:async';

import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isPasswordHidden = true;
  bool _isLoading = false;
  String? _errorMessage;
  int _throttleSeconds = 0;
  Timer? _throttleTimer;

  bool get _isFormValid =>
      _usernameController.text.trim().isNotEmpty &&
      _passwordController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onChanged);
    _passwordController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _throttleTimer?.cancel();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _startThrottleTimer(int seconds) {
    _throttleTimer?.cancel();
    setState(() => _throttleSeconds = seconds);
    _throttleTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _throttleSeconds--);
      if (_throttleSeconds <= 0) {
        timer.cancel();
        setState(() => _errorMessage = null);
      }
    });
  }

  void _onChanged() => setState(() {});

  Future<void> _onLoginPressed() async {
    if (_throttleSeconds > 0) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "Login va parolni kiriting");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final (success, throttleSecs) = await _authService.signIn(username, password);
      if (!mounted) return;

      if (throttleSecs != null && throttleSecs > 0) {
        _startThrottleTimer(throttleSecs);
        setState(() => _isLoading = false);
        return;
      }

      if (success) {
        final roles = await _authService.getUserRoles();
        if (!mounted) return;

        if (roles.isEmpty) {
          setState(
            () => _errorMessage =
                "Rol topilmadi. Administrator bilan bog'laning.",
          );
        } else if (roles.length == 1) {
          context.go('/home');
        } else {
          context.go('/select-role');
        }
      } else {
        setState(() => _errorMessage = "Login yoki parol noto'g'ri");
      }
    } catch (e) {
      setState(
        () => _errorMessage = "Xatolik yuz berdi. Qayta urinib ko'ring.",
      );
      debugPrint("Login error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.backgroundBase,
      body: Container(
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage("assets/image.png"),
            fit: BoxFit.cover,
          ),
          color: colors.backgroundBase,
        ),
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 350,
                  height: 56,
                  child: Text(
                    "Raqamli boshqaruv tizimiga xush kelibsiz",
                    style: TextStyle(
                      fontFamily: "Manrope",
                      height: 28 / 24,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                      color: colors.textStrong,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 350,
                  height: 48,
                  child: Text(
                    "Loyihalar, vazifalar va moliyani bitta platformada boshqaring",
                    style: TextStyle(
                      fontSize: 15,
                      fontFamily: "Manrope",
                      color: colors.black,
                      fontWeight: FontWeight.w500,
                      height: 24 / 15,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Form card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.backgroundElevation1,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                        color: Colors.black.withValues(alpha: 0.12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              "assets/logo.png",
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Raqamli Nazorat",
                            style: TextStyle(
                              fontFamily: "Manrope",
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: colors.textStrong,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Kirish",
                        style: TextStyle(
                          fontFamily: "Manrope",
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          height: 32 / 28,
                          letterSpacing: 0,
                          color: colors.textStrong,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Username
                      _inputField(
                        "Login",
                        controller: _usernameController,
                        colors: colors,
                      ),
                      const SizedBox(height: 12),

                      // Password with Eye Button
                      _passwordField(colors),

                      if (_throttleSeconds > 0) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: colors.errorSub.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: colors.errorSub.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(LucideIcons.timer,
                                  color: colors.errorSub, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Juda ko'p urinish. $_throttleSeconds soniyadan so'ng qayta urinib ko'ring.",
                                  style: TextStyle(
                                    color: colors.errorSub,
                                    fontSize: 13,
                                    fontFamily: "Manrope",
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (_errorMessage != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: colors.errorSub,
                            fontSize: 13,
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Login button
                      GestureDetector(
                        onTap: (!_isFormValid || _isLoading || _throttleSeconds > 0)
                            ? null
                            : _onLoginPressed,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            color: (_isFormValid && _throttleSeconds == 0)
                                ? colors.accentSub
                                : colors.backgroundElevation2,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: _isLoading
                                ? SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: colors.textWhite,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    _throttleSeconds > 0
                                        ? "$_throttleSeconds s"
                                        : "Kirish",
                                    style: TextStyle(
                                      fontFamily: "Manrope",
                                      fontSize: 16,
                                      fontWeight: FontWeight.w300,
                                      color: (_isFormValid && _throttleSeconds == 0)
                                          ? colors.textWhite
                                          : colors.textDisabled,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================== Username Field ==================
  Widget _inputField(
    String hint, {
    required TextEditingController controller,
    required AppColors colors,
  }) {
    return Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.backgroundElevation1Alt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.strokeSoft, width: 1),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(
          fontFamily: "Manrope",
          color: colors.textStrong,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: "Manrope",
            color: colors.textSoft,
            fontSize: 15,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget _passwordField(AppColors colors) {
    return Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.backgroundElevation1Alt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.strokeSoft, width: 1),
      ),
      child: TextField(
        controller: _passwordController,
          obscureText: _isPasswordHidden,
          style: TextStyle(
            fontFamily: "Manrope",
            color: colors.textStrong,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: "Parol",
            hintStyle: TextStyle(
              fontFamily: "Manrope",
              color: colors.textSoft,
              fontSize: 15,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            suffixIcon: _passwordController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      _isPasswordHidden ? LucideIcons.eyeOff : LucideIcons.eye,
                      color: colors.iconSoft,
                      size: 22,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordHidden = !_isPasswordHidden;
                      });
                    },
                  )
                : null,
          ),
        ),
    );
  }
}
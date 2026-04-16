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
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  Future<void> _onLoginPressed() async {
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

    final success = await _authService.signIn(username, password);
    if (!mounted) return;

    if (success) {
      context.go('/home');
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage =
            "Login yoki parol noto'g'ri. Iltimos, qayta tekshiring.";
      });
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
                Text(
                  "Raqamli boshqaruv tizimiga xush kelibsiz",
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontFamily: "Manrope",
                    height: 1.2,
                    letterSpacing: 1.7,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: colors.textStrong,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Loyihalar, vazifalar va moliyani bitta platformada boshqaring",
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 15,
                    fontFamily: "Manrope",
                    color: colors.black,
                    fontWeight: FontWeight.w500,
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
                      // Logo row
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF5B6EF5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Text(
                                "R",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Raqamli Nazorat",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colors.textStrong,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Text(
                        "Kirish",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: colors.textStrong,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Username
                      _inputField(
                        "Login",
                        controller: _usernameController,
                        colors: colors,
                        prefixIcon: LucideIcons.user,
                      ),
                      const SizedBox(height: 12),

                      // Password
                      _inputField(
                        "Parol",
                        controller: _passwordController,
                        colors: colors,
                        prefixIcon: LucideIcons.lock,
                        isPassword: true,
                      ),

                      // Error
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Login button
                      GestureDetector(
                        onTap: (!_isFormValid || _isLoading)
                            ? null
                            : _onLoginPressed,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            color: _isFormValid
                                ? const Color(0xFF5B6EF5)
                                : Color(0xFFF2F1F0),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    "Kirish",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: _isFormValid
                                          ? Colors.white
                                          : Color(0xFFA3A3A3),
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

  Widget _inputField(
    String hint, {
    required TextEditingController controller,
    required AppColors colors,
    required IconData prefixIcon,
    bool isPassword = false,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: colors.backgroundElevation2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.strokeSub),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _isPasswordHidden : false,
        style: TextStyle(
          color: colors.textStrong,
          fontSize: 15,
          fontFamily: "Manrope",
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: colors.textSoft, fontSize: 15),
          border: InputBorder.none,
          fillColor: colors.backgroundElevation2,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          prefixIcon: Icon(prefixIcon, size: 18, color: colors.iconSub),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isPasswordHidden ? LucideIcons.eyeOff : LucideIcons.eye,
                    size: 18,
                    color: colors.iconSub,
                  ),
                  onPressed: () =>
                      setState(() => _isPasswordHidden = !_isPasswordHidden),
                )
              : null,
        ),
      ),
    );
  }
}

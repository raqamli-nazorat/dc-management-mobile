import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final _auth = AuthService();
  String _pin = '';
  bool _isLoading = false;
  bool _pinVisible = false;
  String? _error;
  String _username = '';

  static const _maxLength = 8;
  static const _accentColor = Color(0xFF5B6EF5);

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final name = await _auth.getUsername();
    if (mounted) setState(() => _username = name ?? '');
  }

  void _onKey(String digit) {
    if (_pin.length >= _maxLength || _isLoading) return;
    setState(() {
      _pin += digit;
      _error = null;
    });
  }

  void _onDelete() {
    if (_pin.isEmpty || _isLoading) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    if (_pin.isEmpty || _isLoading) return;
    setState(() => _isLoading = true);
    final success = await _auth.signInWithPin(_pin);
    if (!mounted) return;
    if (success) {
      context.go('/home');
    } else {
      setState(() {
        _isLoading = false;
        _pin = '';
        _error = 'PIN noto\'g\'ri. Qayta urinib ko\'ring.';
      });
    }
  }

  Future<void> _switchAccount() async {
    await _auth.signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.backgroundBase,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PIN-kodni kiriting',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: colors.textStrong,
                      fontFamily: 'Manrope',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hisobingizga kirishni tasdiqlash uchun PIN-kodni kiriting',
                    style: TextStyle(
                      fontSize: 15,
                      color: colors.textSub,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // PIN dots — centered
            SizedBox(
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Dots row — center
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_maxLength, (i) {
                      final filled = i < _pin.length;
                      final char = (filled && _pinVisible) ? _pin[i] : null;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: char != null
                            ? Text(
                                char,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textStrong,
                                ),
                              )
                            : AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: filled
                                      ? colors.textStrong
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: _error != null
                                        ? const Color(0xFFEF4444)
                                        : filled
                                            ? colors.textStrong
                                            : colors.strokeSub,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                      );
                    }),
                  ),
                  // Eye icon — right side
                  Positioned(
                    right: 24,
                    child: GestureDetector(
                      onTap: () => setState(() => _pinVisible = !_pinVisible),
                      child: Icon(
                        _pinVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 22,
                        color: colors.iconSub,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Error
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

            const Spacer(),

            // Keypad
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 48),
                  child: CircularProgressIndicator(color: _accentColor),
                ),
              )
            else
              _Keypad(
                colors: colors,
                onKey: _onKey,
                onDelete: _onDelete,
                onSend: _pin.isNotEmpty ? _submit : null,
              ),

            // Boshqa hisob
            Padding(
              padding: const EdgeInsets.only(bottom: 32, top: 16),
              child: Center(
                child: GestureDetector(
                  onTap: _switchAccount,
                  child: Text(
                    'Boshqa hisob bilan kirish',
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.accentSub,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  final AppColors colors;
  final void Function(String) onKey;
  final VoidCallback onDelete;
  final VoidCallback? onSend;

  const _Keypad({
    required this.colors,
    required this.onKey,
    required this.onDelete,
    this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          _buildRow(['1', '2', '3']),
          _buildRow(['4', '5', '6']),
          _buildRow(['7', '8', '9']),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                // Send
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _KeyButton(
                      colors: colors,
                      filled: onSend != null,
                      onTap: onSend ?? () {},
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 22,
                        color: onSend != null ? Colors.white : colors.iconSub,
                      ),
                    ),
                  ),
                ),
                // 0
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _KeyButton(
                      colors: colors,
                      onTap: () => onKey('0'),
                      child: Text(
                        '0',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: colors.textStrong,
                        ),
                      ),
                    ),
                  ),
                ),
                // Delete
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _KeyButton(
                      colors: colors,
                      transparent: true,
                      onTap: onDelete,
                      child: Icon(
                        Icons.arrow_back_rounded,
                        size: 22,
                        color: colors.textStrong,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: keys.map((key) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _KeyButton(
                colors: colors,
                onTap: () => onKey(key),
                child: Text(
                  key,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: colors.textStrong,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final AppColors colors;
  final Widget child;
  final VoidCallback onTap;
  final bool filled;
  final bool transparent;

  const _KeyButton({
    required this.colors,
    required this.child,
    required this.onTap,
    this.filled = false,
    this.transparent = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: transparent
              ? Colors.transparent
              : filled
                  ? const Color(0xFF5B6EF5)
                  : colors.backgroundElevation1,
          borderRadius: BorderRadius.circular(32),
          border: transparent
              ? null
              : Border.all(
                  color: filled
                      ? const Color(0xFF5B6EF5)
                      : colors.strokeSub,
                  width: 1,
                ),
        ),
        child: Center(child: child),
      ),
    );
  }
}
import 'dart:async';

import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/services/auth_service.dart';
import 'package:dcmanagement/services/pin_session.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen>
    with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  String _pin = '';
  bool _isLoading = false;
  bool _pinVisible = false;
  String? _error;
  bool _isApiError = false;
  int? _pinLength;
  int _throttleSeconds = 0;
  Timer? _throttleTimer;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: -7), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -7, end: 7), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 7, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));
    _loadData();
  }

  @override
  void dispose() {
    _throttleTimer?.cancel();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _startThrottle(int seconds) {
    _throttleTimer?.cancel();
    setState(() {
      _throttleSeconds = seconds;
      _pin = '';
      _error = null;
      _isApiError = false;
    });
    _throttleTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _throttleSeconds--);
      if (_throttleSeconds <= 0) t.cancel();
    });
  }

  Future<void> _loadData() async {
    final length = await _auth.getPasswordLength();
    if (mounted) {
      setState(() {
        _pinLength = length;
      });
    }
  }

  void _onKey(String digit) {
    if (_isLoading || _throttleSeconds > 0) return;
    if (_pinLength != null && _pin.length >= _pinLength!) return;
    setState(() {
      _pin += digit;
      _error = null;
      _isApiError = false;
    });
    if (_pinLength != null && _pin.length == _pinLength!) {
      _submit();
    }
  }

  void _onDelete() {
    if (_pin.isEmpty || _isLoading) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    if (_pin.isEmpty || _isLoading || _throttleSeconds > 0) return;
    setState(() => _isLoading = true);
    final (success, throttleSec, isApiError) = await _auth.signInWithPin(_pin);
    if (!mounted) return;
    if (success) {
      PinSession.instance.markVerified();
      context.go('/home');
    } else if (throttleSec != null) {
      setState(() => _isLoading = false);
      _startThrottle(throttleSec);
    } else if (isApiError) {
      _shakeCtrl.forward(from: 0);
      setState(() {
        _isLoading = false;
        _pin = '';
        _error =
            'Server bilan ulanishda xatolik. Internet aloqasini tekshiring.';
        _isApiError = true;
      });
    } else {
      _shakeCtrl.forward(from: 0);
      setState(() {
        _isLoading = false;
        _pin = '';
        _error = 'PIN noto\'g\'ri. Qayta urinib ko\'ring.';
        _isApiError = false;
      });
    }
  }

  Future<void> _switchAccount() async {
    await _auth.signOut();
    if (mounted) context.go('/login');
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  bool get _isBlocked => _isLoading || _throttleSeconds > 0;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.backgroundBase,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
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

            // ── PIN dots (only filled ones shown) ─────────────────────────
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (_, child) => Transform.translate(
                offset: Offset(_shakeAnim.value, 0),
                child: child,
              ),
              child: SizedBox(
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pin.length, (i) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: _pinVisible
                              ? Text(
                                  _pin[i],
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textStrong,
                                  ),
                                )
                              : Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: colors.textStrong,
                                  ),
                                ),
                        );
                      }),
                    ),
                    Positioned(
                      right: 24,
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _pinVisible = !_pinVisible),
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
            ),

            // ── Status messages ───────────────────────────────────────────
            SizedBox(
              height: 56,
              child: Center(
                child: _isLoading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: colors.accentSub,
                        ),
                      )
                    : _throttleSeconds > 0
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Kirish vaqtincha bloklandi',
                                style: TextStyle(
                                  color: colors.errorSub,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Qayta urinish uchun: ',
                                    style: TextStyle(
                                      color: colors.textStrong,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    _formatTime(_throttleSeconds),
                                    style: TextStyle(
                                      color: colors.textStrong,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : _error != null
                            ? Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isApiError
                                          ? Icons.wifi_off_rounded
                                          : Icons.error_outline_rounded,
                                      size: 15,
                                      color: colors.errorSub,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        _error!,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: colors.errorSub,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
              ),
            ),

            const SizedBox(height: 8),

            // ── Keypad — always visible, no visual change when disabled ───
            AbsorbPointer(
              absorbing: _isBlocked,
              child: _Keypad(
                colors: colors,
                onKey: _onKey,
                onDelete: _onDelete,
                onLogout: _switchAccount,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Keypad extends StatelessWidget {
  final AppColors colors;
  final void Function(String) onKey;
  final VoidCallback onDelete;
  final VoidCallback onLogout;

  const _Keypad({
    required this.colors,
    required this.onKey,
    required this.onDelete,
    required this.onLogout,
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
                // Logout
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _KeyButton(
                      colors: colors,
                      isLogout: true,
                      onTap: onLogout,
                      child: Icon(
                        Icons.logout_rounded,
                        size: 22,
                        color: colors.errorSub,
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
                      isTransparent: true,
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
  final bool isLogout;
  final bool isTransparent;

  const _KeyButton({
    required this.colors,
    required this.child,
    required this.onTap,
    this.isLogout = false,
    this.isTransparent = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: isTransparent
              ? Colors.transparent
              : colors.backgroundElevation1,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isLogout
                ? colors.errorSub.withValues(alpha: 0.5)
                : colors.strokeSub,
            width: 1,
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}

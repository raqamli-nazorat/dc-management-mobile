import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/services/auth_service.dart';
import 'package:dcmanagement/services/pin_session.dart';
import 'package:dcmanagement/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen>
    with SingleTickerProviderStateMixin {
  String _current = '';
  bool _hasError = false;
  int _attempts = 0;

  late final AnimationController _shake;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -14.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -14.0, end: 14.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 14.0, end: -10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shake, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _onDigit(String d) {
    if (_current.length >= 6) return;
    setState(() {
      _current += d;
      _hasError = false;
    });
    if (_current.length == 6) _verify();
  }

  void _onBackspace() {
    if (_current.isEmpty) return;
    setState(() {
      _current = _current.substring(0, _current.length - 1);
      _hasError = false;
    });
  }

  Future<void> _verify() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(StorageService.pinKey) ?? '';

    if (_current == saved) {
      PinSession.instance.markVerified();
      if (mounted) context.go('/home');
    } else {
      _attempts++;
      _shake.forward(from: 0);
      setState(() {
        _hasError = true;
        _current = '';
      });
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(),
    );
    if (confirmed == true && mounted) {
      PinSession.instance.reset();
      await AuthService().signOut();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.backgroundBase,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // Lock icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colors.accentDisabled,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  color: colors.accentSub,
                  size: 34,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'PIN kod kiriting',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colors.textStrong,
                ),
              ),
              const SizedBox(height: 8),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _hasError
                    ? Text(
                        _attempts >= 5
                            ? 'Juda ko\'p urinish. Chiqib qayta kiring.'
                            : 'Noto\'g\'ri PIN. Qayta urinib ko\'ring.',
                        key: const ValueKey('err'),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: colors.errorSub),
                      )
                    : Text(
                        'Ilovaga kirish uchun PIN kodni kiriting',
                        key: const ValueKey('hint'),
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(fontSize: 13, color: colors.textSoft),
                      ),
              ),

              const SizedBox(height: 48),

              // Dots
              AnimatedBuilder(
                animation: _shakeAnim,
                builder: (_, child) => Transform.translate(
                  offset: Offset(_shakeAnim.value, 0),
                  child: child,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (i) {
                    final filled = i < _current.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled ? colors.accentSub : Colors.transparent,
                        border: Border.all(
                          color: _hasError
                              ? colors.errorSub
                              : filled
                                  ? colors.accentSub
                                  : colors.strokeStrong,
                          width: 2,
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const Spacer(),

              // Numpad
              _Numpad(
                colors: colors,
                onDigit: _onDigit,
                onBackspace: _onBackspace,
              ),

              const SizedBox(height: 24),

              // Sign out link
              TextButton(
                onPressed: _signOut,
                child: Text(
                  'Hisobdan chiqish',
                  style: TextStyle(fontSize: 13, color: colors.textSoft),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Numpad extends StatelessWidget {
  final AppColors colors;
  final void Function(String) onDigit;
  final VoidCallback onBackspace;

  const _Numpad({
    required this.colors,
    required this.onDigit,
    required this.onBackspace,
  });

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['', '0', 'del'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _rows.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((key) {
              if (key.isEmpty) {
                return const SizedBox(width: 88, height: 62);
              }
              if (key == 'del') {
                return _Key(
                  colors: colors,
                  onTap: onBackspace,
                  child: Icon(
                    Icons.backspace_outlined,
                    size: 22,
                    color: colors.iconSub,
                  ),
                );
              }
              return _Key(
                colors: colors,
                onTap: () => onDigit(key),
                child: Text(
                  key,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                    color: colors.textStrong,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _Key extends StatefulWidget {
  final AppColors colors;
  final VoidCallback onTap;
  final Widget child;

  const _Key({
    required this.colors,
    required this.onTap,
    required this.child,
  });

  @override
  State<_Key> createState() => _KeyState();
}

class _KeyState extends State<_Key> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 88,
        height: 62,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: _pressed
              ? widget.colors.backgroundElevation2
              : widget.colors.backgroundElevation1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: widget.colors.strokeSub),
        ),
        alignment: Alignment.center,
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ConfirmDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AlertDialog(
      backgroundColor: colors.backgroundElevation1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Chiqishni tasdiqlang',
        style: TextStyle(
            color: colors.textStrong, fontWeight: FontWeight.w600),
      ),
      content: Text(
        'Hisobdan chiqmoqchimisiz?',
        style: TextStyle(color: colors.textSub),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child:
              Text('Bekor qilish', style: TextStyle(color: colors.textSub)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            'Chiqish',
            style: TextStyle(
                color: colors.errorSub, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

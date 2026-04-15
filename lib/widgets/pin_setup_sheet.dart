import 'package:dcmanagement/colors/app_colors.dart';
import 'package:flutter/material.dart';

/// A modal bottom sheet that guides the user through a two-step PIN setup.
///
/// Returns the confirmed 6-digit PIN string, or null if cancelled.
class PinSetupSheet extends StatefulWidget {
  const PinSetupSheet({super.key});

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PinSetupSheet(),
    );
  }

  @override
  State<PinSetupSheet> createState() => _PinSetupSheetState();
}

enum _Step { enter, confirm }

class _PinSetupSheetState extends State<PinSetupSheet>
    with SingleTickerProviderStateMixin {
  _Step _step = _Step.enter;
  String _firstPin = '';
  String _current = '';
  bool _hasError = false;

  late final AnimationController _shake;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
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
    if (_current.length == 6) _handleComplete();
  }

  void _onBackspace() {
    if (_current.isEmpty) return;
    setState(() {
      _current = _current.substring(0, _current.length - 1);
      _hasError = false;
    });
  }

  void _handleComplete() {
    if (_step == _Step.enter) {
      setState(() {
        _firstPin = _current;
        _current = '';
        _step = _Step.confirm;
      });
    } else {
      if (_current == _firstPin) {
        Navigator.of(context).pop(_current);
      } else {
        _shake.forward(from: 0);
        setState(() {
          _hasError = true;
          _current = '';
          _step = _Step.enter;
          _firstPin = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundBase,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.strokeStrong,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),

          // Lock icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: colors.accentDisabled,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_outline_rounded,
              color: colors.accentSub,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),

          // Title
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              _step == _Step.enter ? 'PIN kod o\'rnating' : 'Tasdiqlang',
              key: ValueKey(_step),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colors.textStrong,
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Subtitle / error
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _hasError
                ? Text(
                    'PIN kodlar mos kelmadi. Qayta urinib ko\'ring.',
                    key: const ValueKey('err'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: colors.errorSub),
                  )
                : Text(
                    _step == _Step.enter
                        ? '6 xonali PIN kod kiriting'
                        : 'PIN kodni yana bir bor kiriting',
                    key: ValueKey('hint${_step.name}'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: colors.textSoft),
                  ),
          ),

          const SizedBox(height: 36),

          // Dots — with shake animation on error
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
                  width: 14,
                  height: 14,
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

          const SizedBox(height: 36),

          // Numpad
          _Numpad(
            colors: colors,
            onDigit: _onDigit,
            onBackspace: _onBackspace,
          ),
        ],
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
                return const SizedBox(width: 84, height: 58);
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
                    fontSize: 24,
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
        width: 84,
        height: 58,
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

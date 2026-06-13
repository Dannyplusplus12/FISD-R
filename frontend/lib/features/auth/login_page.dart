import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onDigit(String d) {
    if (_pin.length >= 4) return;
    final next = _pin + d;
    setState(() => _pin = next);
    if (next.length == 4) _submit();
  }

  void _onBack() {
    if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    final ok = await ref.read(authProvider.notifier).loginWithPin(pin: _pin);
    if (!ok && mounted) {
      _shakeController.forward(from: 0);
      setState(() => _pin = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 360, minHeight: size.height * 0.8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Logo(),
                    const SizedBox(height: 48),
                    _PinDisplay(pin: _pin, shakeAnimation: _shakeAnimation),
                    const SizedBox(height: 40),
                    if (isLoading)
                      const SizedBox(
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.white54),
                        ),
                      )
                    else
                      _Keypad(onDigit: _onDigit, onBack: _onBack),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Logo ──────────────────────────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
          ),
          child: const Icon(Icons.warehouse_rounded, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 16),
        const Text(
          'FISD',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Quản lý kho hàng',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 13,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

// ── PIN Display ───────────────────────────────────────────────────────────────

class _PinDisplay extends StatelessWidget {
  final String pin;
  final Animation<double> shakeAnimation;

  const _PinDisplay({required this.pin, required this.shakeAnimation});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Nhập mã PIN',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 20),
        AnimatedBuilder(
          animation: shakeAnimation,
          builder: (_, child) {
            final dx = shakeAnimation.value == 0
                ? 0.0
                : 8.0 * (0.5 - shakeAnimation.value).abs() * (shakeAnimation.value < 0.5 ? 1 : -1);
            return Transform.translate(offset: Offset(dx * 4, 0), child: child);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final filled = i < pin.length;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: filled ? 20 : 16,
                height: filled ? 20 : 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled
                      ? Colors.white
                      : Colors.white.withOpacity(0.2),
                  border: filled
                      ? null
                      : Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ── Keypad ────────────────────────────────────────────────────────────────────

class _Keypad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onBack;

  const _Keypad({required this.onDigit, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['', '0', '⌫'],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((k) {
                if (k.isEmpty) return const SizedBox(width: 80, height: 80);
                return _Key(
                  label: k,
                  isBack: k == '⌫',
                  onTap: () => k == '⌫' ? onBack() : onDigit(k),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _Key extends StatefulWidget {
  final String label;
  final bool isBack;
  final VoidCallback onTap;

  const _Key({required this.label, required this.onTap, this.isBack = false});

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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _pressed
                ? Colors.white.withOpacity(0.25)
                : Colors.white.withOpacity(0.08),
            border: Border.all(
              color: Colors.white.withOpacity(_pressed ? 0.5 : 0.15),
              width: 1,
            ),
          ),
          child: Center(
            child: widget.isBack
                ? Icon(Icons.backspace_outlined,
                    color: Colors.white.withOpacity(0.8), size: 22)
                : Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

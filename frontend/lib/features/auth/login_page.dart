import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import 'auth_provider.dart';

// ── Login Page ────────────────────────────────────────────────────────────────
//
// PIN-based login screen.  The user selects their role (orderer / picker /
// manager) and types their 4-8 digit PIN using the on-screen keypad.
//
// The page is a ConsumerStatefulWidget because it owns text controllers and
// the selected role state, while also watching the authProvider for loading
// and error states.

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  String _pin = '';
  String _selectedRole = 'orderer';

  static const _roles = [
    {'value': 'orderer', 'label': 'Đặt hàng'},
    {'value': 'picker', 'label': 'Giao hàng'},
    {'value': 'manager', 'label': 'Quản lý'},
  ];

  // Add a digit to the PIN (max 8 digits)
  void _onDigit(String digit) {
    if (_pin.length < 8) setState(() => _pin += digit);
  }

  // Remove the last digit
  void _onBackspace() {
    if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _onLogin() async {
    if (_pin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN cần ít nhất 4 số')),
      );
      return;
    }
    final ok = await ref.read(authProvider.notifier).loginWithPin(
          pin: _pin,
          role: _selectedRole,
        );
    if (!ok && mounted) {
      // Error message comes from authProvider state
      final errorMsg = ref.read(authProvider).error?.toString() ?? 'Lỗi đăng nhập';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
      setState(() => _pin = ''); // clear PIN on failure
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo / title
                const Text(
                  'FISD',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Quản lý kho hàng',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 32),

                // Role selector
                _RoleSelector(
                  selected: _selectedRole,
                  roles: _roles,
                  onChanged: (v) => setState(() {
                    _selectedRole = v;
                    _pin = '';
                  }),
                ),
                const SizedBox(height: 24),

                // PIN dots display
                _PinDots(pin: _pin),
                const SizedBox(height: 24),

                // Numeric keypad
                _NumericKeypad(
                  onDigit: _onDigit,
                  onBackspace: _onBackspace,
                  onConfirm: isLoading ? null : _onLogin,
                ),

                if (isLoading) ...[
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Role Selector ─────────────────────────────────────────────────────────────
class _RoleSelector extends StatelessWidget {
  final String selected;
  final List<Map<String, String>> roles;
  final ValueChanged<String> onChanged;

  const _RoleSelector({
    required this.selected,
    required this.roles,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: roles.map((r) {
        final isSelected = r['value'] == selected;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ChoiceChip(
            label: Text(r['label']!),
            selected: isSelected,
            onSelected: (_) => onChanged(r['value']!),
            selectedColor: AppColors.navSelected,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── PIN Dots ──────────────────────────────────────────────────────────────────
class _PinDots extends StatelessWidget {
  final String pin;

  const _PinDots({required this.pin});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(8, (i) {
        final filled = i < pin.length;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Container(
            width: filled ? 16 : 12,
            height: filled ? 16 : 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? AppColors.navSelected : AppColors.navUnselected,
            ),
          ),
        );
      }),
    );
  }
}

// ── Numeric Keypad ────────────────────────────────────────────────────────────
class _NumericKeypad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onConfirm;

  const _NumericKeypad({
    required this.onDigit,
    required this.onBackspace,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['⌫', '0', '✓'],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((key) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _KeyButton(
                    label: key,
                    onTap: () {
                      if (key == '⌫') onBackspace();
                      else if (key == '✓') onConfirm?.call();
                      else onDigit(key);
                    },
                    isAction: key == '⌫' || key == '✓',
                    isPrimary: key == '✓',
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isAction;
  final bool isPrimary;

  const _KeyButton({
    required this.label,
    required this.onTap,
    this.isAction = false,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.navSelected
              : isAction
                  ? AppColors.navUnselected
                  : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: AppColors.cardShadow, blurRadius: 6, offset: Offset(0, 3)),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: isPrimary ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

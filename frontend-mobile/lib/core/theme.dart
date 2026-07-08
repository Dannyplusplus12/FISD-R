import 'package:flutter/material.dart';

const _kPrimary = Color(0xFF1A1A2E);
const _kBackground = Color(0xFFF5F5F7);
const _kSecondary = Color(0xFF8E8E93);

class AppColors {
  static const primary = _kPrimary;
  static const background = _kBackground;
  static const surface = Colors.white;
  static const textSecondary = _kSecondary;
  static const divider = Color(0xFFE5E5EA);
  static const success = Color(0xFF34C759);
  static const warning = Color(0xFFFF9500);
  static const danger = Color(0xFFFF3B30);
  static const info = Color(0xFF007AFF);
}

class AppDeco {
  static InputDecoration input(String hint, {IconData? icon}) => InputDecoration(
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, size: 20, color: AppColors.textSecondary) : null,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      );

  static BoxDecoration card({double radius = 14}) => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))
        ],
      );

  static ButtonStyle primaryBtn = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 0,
  );
}

Widget emptyState(IconData icon, String msg, {String? sub}) => Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 56, color: AppColors.textSecondary.withOpacity(0.4)),
        const SizedBox(height: 12),
        Text(msg, style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
        if (sub != null) ...[
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ]),
    );

Widget errorState(VoidCallback onRetry) => Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_outlined, size: 48, color: AppColors.textSecondary),
        const SizedBox(height: 8),
        const Text('Không tải được dữ liệu', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        TextButton(onPressed: onRetry, child: const Text('Thử lại')),
      ]),
    );

String fmtTien(dynamic v) {
  final n = (v is int) ? v : int.tryParse(v.toString()) ?? 0;
  return n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

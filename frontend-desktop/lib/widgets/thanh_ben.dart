import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/muc_dieu_huong.dart';

class ThanhBen extends StatelessWidget {
  final List<MucDieuHuong> mucMenu;
  final int chiSoChon;
  final ValueChanged<int> onChon;
  final VoidCallback onDong;

  const ThanhBen({
    super.key,
    required this.mucMenu,
    required this.chiSoChon,
    required this.onChon,
    required this.onDong,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(color: AppColors.sidebarShadow, blurRadius: 20, offset: Offset(6, 0)),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.navUnselected, width: 1.5),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 36,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Text(
                      'FISD',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textPrimary),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: mucMenu.length,
                itemBuilder: (context, index) => _OBanMenu(
                  muc: mucMenu[index],
                  daChon: index == chiSoChon,
                  onNhan: () => onChon(index),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: InkWell(
                onTap: onDong,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.navUnselected,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Icon(Icons.menu, color: AppColors.textSecondary, size: 22)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OBanMenu extends StatelessWidget {
  final MucDieuHuong muc;
  final bool daChon;
  final VoidCallback onNhan;

  const _OBanMenu({required this.muc, required this.daChon, required this.onNhan});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onNhan,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: daChon ? AppColors.navSelected : AppColors.navUnselected,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Icon(muc.bieu_tuong, color: daChon ? Colors.white : AppColors.textSecondary, size: 20),
            const SizedBox(width: 12),
            Text(
              muc.nhan,
              style: TextStyle(
                color: daChon ? Colors.white : AppColors.textPrimary,
                fontWeight: daChon ? FontWeight.w600 : FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

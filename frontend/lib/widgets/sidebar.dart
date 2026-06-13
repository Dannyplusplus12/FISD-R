import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/nav_item.dart';

// ── Sidebar ───────────────────────────────────────────────────────────────────
//
// The collapsible left navigation panel.
//
// Parameters:
//   navItems      — the list of pages to show in the menu
//   selectedIndex — which item is currently active (highlighted)
//   onItemSelected — called when the user taps a nav item
//   onClose       — called when the user taps the hamburger to collapse
//   onLogout      — called when the user taps "Đăng xuất"
//   employeeName  — shown at the bottom above the logout button

class Sidebar extends StatelessWidget {
  final List<NavItem> navItems;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onClose;
  final VoidCallback? onLogout;
  final String employeeName;

  const Sidebar({
    super.key,
    required this.navItems,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onClose,
    this.onLogout,
    this.employeeName = '',
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
            // ── Logo ──────────────────────────────────────────────
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
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Nav items ─────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: navItems.length,
                itemBuilder: (context, index) => _NavTile(
                  item: navItems[index],
                  isSelected: index == selectedIndex,
                  onTap: () => onItemSelected(index),
                ),
              ),
            ),

            // ── Footer: user info + logout ─────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (employeeName.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.navUnselected,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: [
                        const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            employeeName,
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Logout button
                  if (onLogout != null)
                    InkWell(
                      onTap: onLogout,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.logout, size: 16, color: Colors.red),
                              SizedBox(width: 6),
                              Text('Đăng xuất',
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    InkWell(
                      onTap: onClose,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Internal nav tile ─────────────────────────────────────────────────────────
class _NavTile extends StatelessWidget {
  final NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavTile({required this.item, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.navSelected : AppColors.navUnselected,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Icon(
              item.icon,
              color: isSelected ? Colors.white : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              item.label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

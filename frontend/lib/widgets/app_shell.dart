import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/session/session.dart';
import '../models/nav_item.dart';
import '../features/auth/login_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/products/products_page.dart';
import '../features/orders/orders_page.dart';
import '../features/customers/customers_page.dart';
import '../features/employees/employees_page.dart';
import 'sidebar.dart';

// ── App Shell ─────────────────────────────────────────────────────────────────
//
// The root widget after login.  Layout: sidebar (left) + content area (right).
//
// HOW TO ADD A NEW PAGE:
//   1. Create your page in lib/features/<name>/<name>_page.dart
//   2. Import it at the top of this file
//   3. Add a new NavItem to _buildNavItems() below
//
// This widget is a ConsumerStatefulWidget instead of StatefulWidget so it can
// read Riverpod providers (specifically, the session provider for logout).

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _isNavOpen = true;
  int _selectedIndex = 0;

  // ── Navigation items ──────────────────────────────────────────────────────
  // Each entry maps to one page.  To add a new section, add a NavItem here.
  List<NavItem> _buildNavItems(Session session) {
    return [
      const NavItem(
        label: 'Tổng Quan',
        icon: Icons.dashboard_outlined,
        page: DashboardPage(),
      ),
      const NavItem(
        label: 'Sản Phẩm',
        icon: Icons.inventory_2_outlined,
        page: ProductsPage(),
      ),
      const NavItem(
        label: 'Đơn Hàng',
        icon: Icons.shopping_cart_outlined,
        page: OrdersPage(),
      ),
      const NavItem(
        label: 'Khách Hàng',
        icon: Icons.people_outline,
        page: CustomersPage(),
      ),
      // Only show Employees page to managers
      if (session.isManager)
        const NavItem(
          label: 'Nhân Viên',
          icon: Icons.badge_outlined,
          page: EmployeesPage(),
        ),
    ];
  }

  void _navigateTo(int index) {
    setState(() {
      _selectedIndex = index;
      _isNavOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final navItems = _buildNavItems(session);

    // Clamp selected index in case nav items changed (e.g., after logout)
    final safeIndex = _selectedIndex.clamp(0, navItems.length - 1);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Side-by-side layout ──────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Animated sidebar — width 0 when collapsed, 260 when open
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOut,
                width: _isNavOpen ? 260.0 : 0.0,
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(),
                child: SizedBox(
                  width: 260,
                  child: Sidebar(
                    navItems: navItems,
                    selectedIndex: safeIndex,
                    onItemSelected: _navigateTo,
                    onClose: () => setState(() => _isNavOpen = false),
                    onLogout: () => ref.read(sessionProvider.notifier).logout(),
                    employeeName: session.employeeName,
                  ),
                ),
              ),

              // Main content area
              Expanded(
                child: navItems[safeIndex].page,
              ),
            ],
          ),

          // ── Hamburger FAB (slides in when sidebar closes) ─────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            bottom: 24,
            left: _isNavOpen ? -64.0 : 16.0,
            child: GestureDetector(
              onTap: () => setState(() => _isNavOpen = true),
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.navSelected,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.sidebarShadow,
                        blurRadius: 10,
                        offset: Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.menu, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Auth Gate ─────────────────────────────────────────────────────────────────
//
// Shows LoginPage when not logged in, AppShell when logged in.
// Riverpod rebuilds this automatically when the session changes.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    return session.isLoggedIn ? const AppShell() : const LoginPage();
  }
}

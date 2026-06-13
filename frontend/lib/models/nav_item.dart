import 'package:flutter/material.dart';

/// Represents one item in the sidebar navigation.
///
/// To add a new page:
///   1. Create your page widget in lib/pages/
///   2. Add a new NavItem in app_shell.dart's _navItems list
class NavItem {
  final String label;
  final IconData icon;
  final Widget page;

  const NavItem({
    required this.label,
    required this.icon,
    required this.page,
  });
}

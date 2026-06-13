import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── User Roles ────────────────────────────────────────────────────────────────
// Must match the roles defined in the backend employees table.
enum UserRole {
  none,      // not logged in
  orderer,   // tạo đơn hàng
  picker,    // nhận và giao đơn
  manager,   // quản lý toàn bộ
}

// ── Session ───────────────────────────────────────────────────────────────────
// Holds the currently logged-in employee's info.
// This is read by the UI to show the user's name, and by the API calls
// to send the employee ID with orders/deliveries.
class Session {
  final UserRole role;
  final int? employeeId;
  final String employeeName;

  const Session({
    this.role = UserRole.none,
    this.employeeId,
    this.employeeName = '',
  });

  bool get isLoggedIn => role != UserRole.none;
  bool get isManager => role == UserRole.manager;
  bool get isPicker => role == UserRole.picker;
  bool get isOrderer => role == UserRole.orderer;

  Session copyWith({UserRole? role, int? employeeId, String? employeeName}) {
    return Session(
      role: role ?? this.role,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
    );
  }

  @override
  String toString() => 'Session(role: $role, id: $employeeId, name: $employeeName)';
}

// ── Session Notifier ──────────────────────────────────────────────────────────
// Manages login/logout and persists the session in SharedPreferences
// so the user stays logged in when they reopen the app.
class SessionNotifier extends StateNotifier<Session> {
  SessionNotifier() : super(const Session());

  // Called once at app startup to restore a saved session.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final roleStr = prefs.getString('_role') ?? 'none';
    final employeeId = prefs.getInt('_employee_id');
    final employeeName = prefs.getString('_employee_name') ?? '';

    final role = UserRole.values.firstWhere(
      (r) => r.name == roleStr,
      orElse: () => UserRole.none,
    );

    state = Session(role: role, employeeId: employeeId, employeeName: employeeName);
  }

  // Called after a successful PIN login.
  Future<void> login({
    required int employeeId,
    required String employeeName,
    required String roleStr,
  }) async {
    final role = UserRole.values.firstWhere(
      (r) => r.name == roleStr,
      orElse: () => UserRole.orderer,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('_role', role.name);
    await prefs.setInt('_employee_id', employeeId);
    await prefs.setString('_employee_name', employeeName);

    state = Session(role: role, employeeId: employeeId, employeeName: employeeName);
  }

  // Called when the user taps "Đăng xuất".
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('_role');
    await prefs.remove('_employee_id');
    await prefs.remove('_employee_name');
    state = const Session();
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────
// Use `ref.watch(sessionProvider)` in any widget to read the current session.
// Use `ref.read(sessionProvider.notifier).login(...)` to log in.
final sessionProvider = StateNotifierProvider<SessionNotifier, Session>((ref) {
  return SessionNotifier();
});

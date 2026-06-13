import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/session/session.dart';

// ── Auth Provider ─────────────────────────────────────────────────────────────
//
// Wraps SessionNotifier with a PIN-login action that calls the backend.
//
// HOW TO USE FROM A PAGE:
//
//   // Read current session (rebuild when it changes):
//   final session = ref.watch(sessionProvider);
//
//   // Log in with a PIN:
//   await ref.read(authProvider.notifier).loginWithPin(pin: '1234', role: 'orderer');
//
//   // Log out:
//   await ref.read(authProvider.notifier).logout();

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AsyncValue.data(null));

  // Sends the PIN to the backend.  On success, saves the session.
  // On failure, sets state to AsyncError so the UI can show the message.
  Future<bool> loginWithPin({required String pin}) async {
    state = const AsyncValue.loading();
    try {
      final dio = _ref.read(apiClientProvider);
      final response = await dio.post(
        ApiEndpoints.dangNhapPin,
        data: {'pin': pin},
      );
      final data = response.data as Map<String, dynamic>;
      await _ref.read(sessionProvider.notifier).login(
            employeeId: data['id'] as int,
            employeeName: (data['name'] ?? '').toString(),
            roleStr: (data['role'] ?? 'orderer').toString(),
          );
      state = const AsyncValue.data(null);
      return true;
    } on DioException catch (e) {
      final msg = _extractError(e);
      state = AsyncValue.error(msg, StackTrace.current);
      return false;
    }
  }

  Future<void> logout() async {
    await _ref.read(sessionProvider.notifier).logout();
    state = const AsyncValue.data(null);
  }

  // Pulls the human-readable error from a Dio response body.
  static String _extractError(DioException e) {
    try {
      final data = e.response?.data;
      if (data is Map) return (data['detail'] ?? 'Đăng nhập thất bại').toString();
    } catch (_) {}
    return 'Không thể kết nối đến máy chủ';
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier(ref);
});

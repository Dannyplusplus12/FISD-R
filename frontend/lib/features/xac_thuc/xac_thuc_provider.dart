import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/session/session.dart';

class XacThucNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  XacThucNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<bool> dangNhapPin({required String pin}) async {
    state = const AsyncValue.loading();
    try {
      final dio = _ref.read(apiClientProvider);
      final phanHoi = await dio.post(
        ApiEndpoints.dangNhapPin,
        data: {'pin': pin},
      );
      final duLieu = phanHoi.data as Map<String, dynamic>;
      await _ref.read(sessionProvider.notifier).login(
            employeeId: duLieu['id'] as int,
            employeeName: (duLieu['name'] ?? '').toString(),
            roleStr: (duLieu['role'] ?? '').toString(),
          );
      state = const AsyncValue.data(null);
      return true;
    } on DioException catch (e) {
      final loi = _trichXuatLoi(e);
      state = AsyncValue.error(loi, StackTrace.current);
      return false;
    }
  }

  Future<void> dangXuat() async {
    await _ref.read(sessionProvider.notifier).logout();
    state = const AsyncValue.data(null);
  }

  static String _trichXuatLoi(DioException e) {
    try {
      final duLieu = e.response?.data;
      if (duLieu is Map) return (duLieu['detail'] ?? 'Đăng nhập thất bại').toString();
    } catch (_) {}
    return 'Không thể kết nối đến máy chủ';
  }
}

final xacThucProvider = StateNotifierProvider<XacThucNotifier, AsyncValue<void>>((ref) {
  return XacThucNotifier(ref);
});

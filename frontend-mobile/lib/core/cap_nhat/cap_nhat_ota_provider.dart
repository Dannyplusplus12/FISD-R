import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

/// Trạng thái cập nhật OTA (Shorebird code push) của app trên Android.
enum TrangThaiCapNhatOta {
  khongCoGi,
  sanSangKhoiDongLai,
  loi,
}

final capNhatOtaProvider =
    AsyncNotifierProvider<CapNhatOtaNotifier, TrangThaiCapNhatOta>(
  CapNhatOtaNotifier.new,
);

class CapNhatOtaNotifier extends AsyncNotifier<TrangThaiCapNhatOta> {
  final _updater = ShorebirdUpdater();

  @override
  Future<TrangThaiCapNhatOta> build() async {
    if (!_updater.isAvailable) return TrangThaiCapNhatOta.khongCoGi;

    try {
      final trangThai = await _updater.checkForUpdate();

      if (trangThai == UpdateStatus.restartRequired) {
        return TrangThaiCapNhatOta.sanSangKhoiDongLai;
      }

      if (trangThai == UpdateStatus.outdated) {
        await _updater.update();
        return TrangThaiCapNhatOta.sanSangKhoiDongLai;
      }

      return TrangThaiCapNhatOta.khongCoGi;
    } catch (_) {
      return TrangThaiCapNhatOta.loi;
    }
  }

  /// Gọi lại khi app quay về foreground, để phát hiện bản vá mới.
  Future<void> kiemTraLai() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}

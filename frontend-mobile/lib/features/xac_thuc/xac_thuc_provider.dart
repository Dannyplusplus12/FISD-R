import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session/phien_lam_viec.dart';
import 'xac_thuc_repository.dart';

final xacThucRepositoryProvider = Provider((_) => XacThucRepository());

class XacThucNotifier extends AsyncNotifier<PhienLamViec?> {
  @override
  Future<PhienLamViec?> build() async {
    return PhienLamViec.tai();
  }

  Future<void> dangKyHoacDangNhap({
    required String ten,
    required String soDienThoai,
    required String pin,
  }) async {
    state = const AsyncLoading();
    try {
      final data = await ref.read(xacThucRepositoryProvider).dangKyHoacDangNhap(
        ten: ten,
        soDienThoai: soDienThoai,
        pin: pin,
      );
      final phien = _tuJson(data, pin: pin);
      await PhienLamViec.luu(
        id: phien.id,
        ten: phien.ten,
        soDienThoai: phien.soDienThoai,
        vaiTro: phien.vaiTro,
        pin: phien.pin,
      );
      state = AsyncData(phien);
    } catch (e) {
      state = const AsyncData(null);
      rethrow;
    }
  }

  Future<void> dangNhapBangPin(String pin) async {
    state = const AsyncLoading();
    try {
      final data = await ref.read(xacThucRepositoryProvider).dangNhapPin(pin);
      final phien = _tuJson(data, pin: pin);
      await PhienLamViec.luu(
        id: phien.id,
        ten: phien.ten,
        soDienThoai: phien.soDienThoai,
        vaiTro: phien.vaiTro,
        pin: phien.pin,
      );
      state = AsyncData(phien);
    } catch (e) {
      state = const AsyncData(null);
      rethrow;
    }
  }

  Future<void> dangXuat() async {
    await PhienLamViec.xoa();
    state = const AsyncData(null);
  }

  PhienLamViec _tuJson(Map<String, dynamic> data, {required String pin}) {
    return PhienLamViec(
      id: data['id'] as int,
      ten: (data['name'] ?? '').toString(),
      soDienThoai: (data['phone'] ?? '').toString(),
      vaiTro: (data['role'] ?? '').toString(),
      pin: (data['pin'] ?? pin).toString(),
    );
  }
}

final xacThucProvider = AsyncNotifierProvider<XacThucNotifier, PhienLamViec?>(
  XacThucNotifier.new,
);

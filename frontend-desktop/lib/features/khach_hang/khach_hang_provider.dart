import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fisd_shared/models/khach_hang.dart';
import 'khach_hang_repository.dart';

class KhachHangNotifier extends AsyncNotifier<List<KhachHang>> {
  @override
  Future<List<KhachHang>> build() {
    return ref.read(khachHangRepositoryProvider).layTatCa();
  }

  Future<void> lamMoi() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(khachHangRepositoryProvider).layTatCa());
  }

  Future<void> tao({required String ten, String soDienThoai = '', int no = 0, required int khuVucId}) async {
    await ref.read(khachHangRepositoryProvider).tao(ten: ten, soDienThoai: soDienThoai, no: no, khuVucId: khuVucId);
    await lamMoi();
  }

  Future<void> xoa(int id) async {
    await ref.read(khachHangRepositoryProvider).xoa(id);
    await lamMoi();
  }
}

final khachHangProvider = AsyncNotifierProvider<KhachHangNotifier, List<KhachHang>>(KhachHangNotifier.new);

class KhuVucNotifier extends AsyncNotifier<List<TomTatKhuVuc>> {
  @override
  Future<List<TomTatKhuVuc>> build() {
    return ref.read(khachHangRepositoryProvider).layKhuVucs();
  }

  Future<void> lamMoi() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(khachHangRepositoryProvider).layKhuVucs());
  }

  Future<void> tao(String ten) async {
    await ref.read(khachHangRepositoryProvider).taoKhuVuc(ten);
    await lamMoi();
  }

  Future<void> sua(int id, String ten) async {
    await ref.read(khachHangRepositoryProvider).suaKhuVuc(id, ten);
    await lamMoi();
  }

  Future<void> xoa(int id) async {
    await ref.read(khachHangRepositoryProvider).xoaKhuVuc(id);
    await lamMoi();
  }
}

final khuVucProvider = AsyncNotifierProvider<KhuVucNotifier, List<TomTatKhuVuc>>(KhuVucNotifier.new);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/san_pham.dart';
import 'san_pham_repository.dart';

class SanPhamNotifier extends AsyncNotifier<List<SanPham>> {
  @override
  Future<List<SanPham>> build() {
    return ref.read(sanPhamRepositoryProvider).layTatCa();
  }

  Future<void> lamMoi() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(sanPhamRepositoryProvider).layTatCa());
  }

  Future<void> timKiem(String tuKhoa) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(sanPhamRepositoryProvider).layTatCa(timKiem: tuKhoa));
  }
}

final sanPhamProvider = AsyncNotifierProvider<SanPhamNotifier, List<SanPham>>(SanPhamNotifier.new);

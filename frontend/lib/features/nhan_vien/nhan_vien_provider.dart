import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/nhan_vien.dart';
import 'nhan_vien_repository.dart';

class NhanVienNotifier extends AsyncNotifier<List<NhanVien>> {
  @override
  Future<List<NhanVien>> build() {
    return ref.read(nhanVienRepositoryProvider).layTatCa();
  }

  Future<void> lamMoi() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(nhanVienRepositoryProvider).layTatCa());
  }

  Future<void> xoa(int id) async {
    await ref.read(nhanVienRepositoryProvider).xoa(id);
    await lamMoi();
  }
}

final nhanVienProvider = AsyncNotifierProvider<NhanVienNotifier, List<NhanVien>>(NhanVienNotifier.new);

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
    state = await AsyncValue.guard(
      () => ref.read(sanPhamRepositoryProvider).layTatCa(),
    );
  }

  Future<void> timKiem(String tuKhoa) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(sanPhamRepositoryProvider).layTatCa(timKiem: tuKhoa),
    );
  }

  Future<void> themSanPhamMoi({
    required String ten,
    required String ma,
    required int giaMacDinh,
  }) async {
    await ref
        .read(sanPhamRepositoryProvider)
        .tao(
          ma: ma,
          ten: ten,
          bienThes: [
            {'color': '', 'size': '', 'price': giaMacDinh, 'stock': 0},
          ],
        );
    await lamMoi();
  }

  Future<void> taoSanPham({
    required String ten,
    required String ma,
    String duongDanAnh = '',
    required List<BienThe> bienThes,
  }) async {
    await ref
        .read(sanPhamRepositoryProvider)
        .tao(
          ma: ma,
          ten: ten,
          duongDanAnh: duongDanAnh,
          bienThes: bienThes.map((bt) => bt.toJson()).toList(),
        );
    await lamMoi();
  }

  Future<void> capNhatSanPham({
    required int id,
    required String ten,
    required String ma,
    String duongDanAnh = '',
    required List<BienThe> bienThes,
  }) async {
    await ref
        .read(sanPhamRepositoryProvider)
        .capNhat(
          id,
          ma: ma,
          ten: ten,
          duongDanAnh: duongDanAnh,
          bienThes: bienThes.map((bt) => bt.toJson()).toList(),
        );
    await lamMoi();
  }

  Future<void> xoaSanPham(int id) async {
    final repo = ref.read(sanPhamRepositoryProvider);
    await repo.xoa(id);
    await lamMoi();
  }

  Future<void> capNhatTonKho(int variantId, int tonKhoMoi) async {
    final danhSach = state.valueOrNull;
    if (danhSach == null) return;

    final sanPham = danhSach
        .where((sp) => sp.bienThes.any((bt) => bt.id == variantId))
        .firstOrNull;
    if (sanPham == null) return;

    final bienThesMoi = sanPham.bienThes.map((bt) {
      if (bt.id != variantId) return bt;
      return BienThe(
        id: bt.id,
        mauSac: bt.mauSac,
        kichCo: bt.kichCo,
        gia: bt.gia,
        tonKho: tonKhoMoi < 0 ? 0 : tonKhoMoi,
      );
    }).toList();

    await ref
        .read(sanPhamRepositoryProvider)
        .capNhat(
          sanPham.id,
          ma: sanPham.ma,
          ten: sanPham.ten,
          bienThes: bienThesMoi.map((bt) => bt.toJson()).toList(),
        );
    await lamMoi();
  }
}

final sanPhamProvider = AsyncNotifierProvider<SanPhamNotifier, List<SanPham>>(
  SanPhamNotifier.new,
);

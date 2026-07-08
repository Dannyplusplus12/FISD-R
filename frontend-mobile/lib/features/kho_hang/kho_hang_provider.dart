import 'package:fisd_shared/fisd_shared.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'kho_hang_repository.dart';

final khoHangRepoProvider = Provider((_) => KhoHangRepository());

final danhSachKhoProvider = FutureProvider.autoDispose<List<KhoHang>>((ref) async {
  return ref.read(khoHangRepoProvider).layKhos();
});

final sanPhamTrongKhoProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, int>((ref, khoId) async {
  return ref.read(khoHangRepoProvider).laySanPhamTrongKho(khoId);
});

class KhoHangNotifier extends StateNotifier<AsyncValue<void>> {
  KhoHangNotifier(this._repo) : super(const AsyncData(null));
  final KhoHangRepository _repo;

  Future<bool> taoKho(String ten, String viTri, String ghiChu) async {
    try { await _repo.taoKho(ten, viTri, ghiChu); return true; } catch (_) { return false; }
  }

  Future<bool> capNhatKho(int id, String ten, String viTri, String ghiChu) async {
    try { await _repo.capNhatKho(id, ten, viTri, ghiChu); return true; } catch (_) { return false; }
  }

  Future<bool> xoaKho(int id) async {
    try { await _repo.xoaKho(id); return true; } catch (_) { return false; }
  }
}

final khoHangActionProvider = StateNotifierProvider<KhoHangNotifier, AsyncValue<void>>(
  (ref) => KhoHangNotifier(ref.read(khoHangRepoProvider)),
);

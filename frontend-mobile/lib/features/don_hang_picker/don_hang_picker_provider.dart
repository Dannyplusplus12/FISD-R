import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'don_hang_picker_repository.dart';

final _repo = Provider((_) => DonHangPickerRepository());

// Đơn đã duyệt — chờ picker nhận
final donDaDuyetProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.read(_repo).layDonDaDuyet();
});

// Đơn picker đã nhận — đang giao
final donDaNhanProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, int>((ref, pickerId) async {
  return ref.read(_repo).layDonDaNhan(pickerId);
});

class DonHangPickerNotifier extends StateNotifier<AsyncValue<void>> {
  DonHangPickerNotifier(this._repo) : super(const AsyncData(null));
  final DonHangPickerRepository _repo;

  Future<bool> nhanDon(int donId, int pickerId) async {
    state = const AsyncLoading();
    try {
      await _repo.nhanDon(donId, pickerId);
      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> giaoHang({
    required int donId,
    required int pickerId,
    required List<MultipartFile> photos,
    required List<Map<String, dynamic>> items,
    String ghiChu = '',
  }) async {
    state = const AsyncLoading();
    try {
      await _repo.giaoHang(donId: donId, pickerId: pickerId, photos: photos, items: items, ghiChu: ghiChu);
      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }
}

final donHangPickerActionProvider = StateNotifierProvider<DonHangPickerNotifier, AsyncValue<void>>(
  (ref) => DonHangPickerNotifier(ref.read(_repo)),
);

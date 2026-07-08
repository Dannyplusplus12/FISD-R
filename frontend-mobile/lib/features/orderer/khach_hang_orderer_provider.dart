import 'package:fisd_shared/fisd_shared.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'khach_hang_orderer_repository.dart';

final khachHangOrdererRepoProvider = Provider((_) => KhachHangOrdererRepository());

final khachHangOrdererProvider = FutureProvider.autoDispose<List<KhachHang>>((ref) async {
  return ref.read(khachHangOrdererRepoProvider).layKhachHangs();
});

final khuVucOrdererProvider = FutureProvider.autoDispose<List<TomTatKhuVuc>>((ref) async {
  return ref.read(khachHangOrdererRepoProvider).layKhuVucs();
});

final lichSuNoProvider =
    FutureProvider.autoDispose.family<List<LichSuNoItem>, int>((ref, khId) async {
  return ref.read(khachHangOrdererRepoProvider).layLichSuNo(khId);
});

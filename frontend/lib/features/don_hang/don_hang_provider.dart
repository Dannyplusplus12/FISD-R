import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/don_hang.dart';
import 'don_hang_repository.dart';

class QuanLyDonHangNotifier extends AsyncNotifier<List<DonHang>> {
  @override
  Future<List<DonHang>> build() {
    return ref.read(donHangRepositoryProvider).layQuanLy();
  }

  Future<void> lamMoi() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(donHangRepositoryProvider).layQuanLy());
  }

  Future<void> duyet(int donId) async {
    await ref.read(donHangRepositoryProvider).duyet(donId);
    await lamMoi();
  }

  Future<void> tuChoi(int donId) async {
    await ref.read(donHangRepositoryProvider).tuChoi(donId);
    await lamMoi();
  }

  Future<void> huy(int donId) async {
    await ref.read(donHangRepositoryProvider).huy(donId);
    await lamMoi();
  }
}

final quanLyDonHangProvider =
    AsyncNotifierProvider<QuanLyDonHangNotifier, List<DonHang>>(QuanLyDonHangNotifier.new);

class DonHangChoNotifier extends AsyncNotifier<List<DonHang>> {
  @override
  Future<List<DonHang>> build() {
    return ref.read(donHangRepositoryProvider).layChoXuLy();
  }

  Future<void> lamMoi() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(donHangRepositoryProvider).layChoXuLy());
  }

  Future<void> duyet(int donId) async {
    await ref.read(donHangRepositoryProvider).duyet(donId);
    await lamMoi();
  }

  Future<void> tuChoi(int donId) async {
    await ref.read(donHangRepositoryProvider).tuChoi(donId);
    await lamMoi();
  }
}

final donHangChoProvider =
    AsyncNotifierProvider<DonHangChoNotifier, List<DonHang>>(DonHangChoNotifier.new);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session/session.dart';
import 'lenh_nhanh_model.dart';
import 'lenh_nhanh_repository.dart';

enum TrangThaiLenh { rong, dangPhanTich, xemTruoc, dangTao, xong, loi }

class TrangThaiLenhNhanh {
  final TrangThaiLenh trangThai;
  final KetQuaLenhNhanh? ketQua;
  final String? thongBaoLoi;
  final int? donId;

  const TrangThaiLenhNhanh({
    required this.trangThai,
    this.ketQua,
    this.thongBaoLoi,
    this.donId,
  });

  factory TrangThaiLenhNhanh.khoi() =>
      const TrangThaiLenhNhanh(trangThai: TrangThaiLenh.rong);

  bool get dangTai =>
      trangThai == TrangThaiLenh.dangPhanTich ||
      trangThai == TrangThaiLenh.dangTao;
}

class LenhNhanhNotifier extends Notifier<TrangThaiLenhNhanh> {
  @override
  TrangThaiLenhNhanh build() => TrangThaiLenhNhanh.khoi();

  Future<void> phanTich(String lenh) async {
    state = const TrangThaiLenhNhanh(trangThai: TrangThaiLenh.dangPhanTich);
    try {
      final kq = await ref.read(lenhNhanhRepositoryProvider).phanTich(lenh);
      state = TrangThaiLenhNhanh(trangThai: TrangThaiLenh.xemTruoc, ketQua: kq);
    } catch (e) {
      state = TrangThaiLenhNhanh(
        trangThai: TrangThaiLenh.loi,
        thongBaoLoi: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> taoDon() async {
    final kq = state.ketQua;
    if (kq == null || kq.gio.isEmpty) return;
    final phien = ref.read(sessionProvider);
    state = TrangThaiLenhNhanh(trangThai: TrangThaiLenh.dangTao, ketQua: kq);
    try {
      final id = await ref.read(lenhNhanhRepositoryProvider).taoDon(
            tenKhach: kq.tenKhach,
            khachHangId: kq.khachHangId,
            gio: kq.gio,
            nhanVienId: phien.employeeId,
          );
      state = TrangThaiLenhNhanh(trangThai: TrangThaiLenh.xong, donId: id);
    } catch (e) {
      state = TrangThaiLenhNhanh(
        trangThai: TrangThaiLenh.loi,
        ketQua: kq,
        thongBaoLoi: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void datLai() => state = TrangThaiLenhNhanh.khoi();
}

final lenhNhanhProvider =
    NotifierProvider<LenhNhanhNotifier, TrangThaiLenhNhanh>(LenhNhanhNotifier.new);

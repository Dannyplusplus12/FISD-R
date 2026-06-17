import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session/session.dart';
import 'lenh_nhanh_model.dart';
import 'lenh_nhanh_repository.dart';

enum TrangThaiLenh { rong, dangGoiAI, dangTimDB, xemTruoc, dangTao, xong, loi }

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

  bool get dangTai => trangThai == TrangThaiLenh.dangGoiAI ||
      trangThai == TrangThaiLenh.dangTimDB ||
      trangThai == TrangThaiLenh.dangTao;

  String get nhanTrangThai {
    switch (trangThai) {
      case TrangThaiLenh.dangGoiAI: return 'AI đang phân tích...';
      case TrangThaiLenh.dangTimDB: return 'Đang tìm sản phẩm...';
      case TrangThaiLenh.dangTao: return 'Đang tạo đơn...';
      default: return '';
    }
  }
}

class LenhNhanhNotifier extends Notifier<TrangThaiLenhNhanh> {
  @override
  TrangThaiLenhNhanh build() => TrangThaiLenhNhanh.khoi();

  Future<void> phanTich(String lenh) async {
    final repo = ref.read(lenhNhanhRepositoryProvider);

    try {
      // Bước 1: Ollama parse text → JSON
      state = const TrangThaiLenhNhanh(trangThai: TrangThaiLenh.dangGoiAI);
      final intent = await repo.goiOllama(lenh);

      // Bước 2: Backend tìm DB
      state = const TrangThaiLenhNhanh(trangThai: TrangThaiLenh.dangTimDB);
      final kq = await repo.phanTichTuCauTruc(intent);

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

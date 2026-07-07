import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../don_hang/don_hang_provider.dart';
import 'lenh_nhanh_model.dart';
import 'lenh_nhanh_repository.dart';

// ── Provider cũ (one-shot) — dùng bởi xuat_hang_page & sua_don_dialog ────────

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
      final kq = await ref.read(lenhNhanhRepositoryProvider).phanTichOnShot(lenh);
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
    state = TrangThaiLenhNhanh(trangThai: TrangThaiLenh.dangTao, ketQua: kq);
    try {
      final id = await ref.read(lenhNhanhRepositoryProvider).taoDon(
            tenKhach: kq.tenKhach,
            khachHangId: kq.khachHangId,
            gio: kq.gio,
            nhanVienId: null,
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
    NotifierProvider<LenhNhanhNotifier, TrangThaiLenhNhanh>(
        LenhNhanhNotifier.new);

const int _maxUndo = 10;

class PhienLenhNhanhNotifier extends Notifier<PhienLenhNhanh> {
  @override
  PhienLenhNhanh build() => PhienLenhNhanh.khoi();

  Future<void> guiLenh(String lenh) async {
    lenh = lenh.trim();
    if (lenh.isEmpty || state.dangTai) return;

    final snapshot = UndoSnapshot(
      tenKhach: state.tenKhach,
      khachHangId: state.khachHangId,
      gio: List.from(state.gio),
    );

    final lichSuVoiUser = [
      ...state.lichSu,
      TinNhan(laNguoiDung: true, noiDung: lenh),
    ];

    state = state.copyWith(
      dangTai: true,
      loi: null,
      lichSu: lichSuVoiUser,
      sanSangTaoDon: false,
    );

    try {
      final kq = await ref.read(lenhNhanhRepositoryProvider).hoiThoai(
            lenh: lenh,
            tenKhach: state.tenKhach,
            khachHangId: state.khachHangId,
            gioHienTai: state.gio,
            lichSu: lichSuVoiUser,
          );

      final allUndo = [...state.undoStack, snapshot];
      final undoTrimmed =
          allUndo.length > _maxUndo ? allUndo.sublist(allUndo.length - _maxUndo) : allUndo;

      final lichSuVoiAI = [
        ...lichSuVoiUser,
        TinNhan(laNguoiDung: false, noiDung: kq.phanHoi),
      ];

      switch (kq.hanhDong) {
        case 'dat_lai':
          state = PhienLenhNhanh(
            lichSu: lichSuVoiAI,
            tenKhach: 'Khách lẻ',
            khachHangId: null,
            gio: [],
            canhBao: [],
            dangTai: false,
            loi: null,
            sanSangTaoDon: false,
            undoStack: undoTrimmed,
          );
        case 'xac_nhan':
          state = state.copyWith(
            lichSu: lichSuVoiAI,
            dangTai: false,
            sanSangTaoDon: true,
            undoStack: undoTrimmed,
          );
        default: // cap_nhat hoặc khong_ro
          state = PhienLenhNhanh(
            lichSu: lichSuVoiAI,
            tenKhach: kq.tenKhach,
            khachHangId: kq.khachHangId,
            gio: kq.gio,
            canhBao: kq.canhBao,
            dangTai: false,
            loi: null,
            sanSangTaoDon: false,
            undoStack: undoTrimmed,
          );
      }
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        dangTai: false,
        loi: msg,
        lichSu: [
          ...lichSuVoiUser,
          TinNhan(laNguoiDung: false, noiDung: '❌ Lỗi: $msg'),
        ],
      );
    }
  }

  void hoanTac() {
    if (state.undoStack.isEmpty) return;
    final snap = state.undoStack.last;
    state = state.copyWith(
      tenKhach: snap.tenKhach,
      khachHangId: snap.khachHangId,
      gio: snap.gio,
      canhBao: [],
      sanSangTaoDon: false,
      undoStack: state.undoStack.sublist(0, state.undoStack.length - 1),
    );
  }

  void suaSoLuong(int bienTheId, int soLuongMoi) {
    final gio = state.gio
        .map((m) => m.bienTheId == bienTheId ? m.withSoLuong(soLuongMoi) : m)
        .where((m) => m.soLuong > 0)
        .toList();
    state = state.copyWith(gio: gio, sanSangTaoDon: false);
  }

  void xoaMatHang(int bienTheId) {
    final gio = state.gio.where((m) => m.bienTheId != bienTheId).toList();
    state = state.copyWith(gio: gio, sanSangTaoDon: false);
  }

  void datLai() => state = PhienLenhNhanh.khoi();

  Future<int> taoDon() async {
    final id = await ref.read(lenhNhanhRepositoryProvider).taoDon(
          tenKhach: state.tenKhach,
          khachHangId: state.khachHangId,
          gio: state.gio,
          nhanVienId: null,
        );
    ref.read(quanLyDonHangProvider.notifier).lamMoi();
    ref.read(donHangChoProvider.notifier).lamMoi();
    return id;
  }
}

final phienLenhNhanhProvider =
    NotifierProvider<PhienLenhNhanhNotifier, PhienLenhNhanh>(
        PhienLenhNhanhNotifier.new);

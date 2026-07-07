import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fisd_shared/models/don_hang.dart';
import 'package:fisd_shared/models/san_pham.dart';
import '../don_hang/don_hang_provider.dart';
import '../don_hang/don_hang_repository.dart';
import '../lenh_nhanh/lenh_nhanh_model.dart';

class GioHangMuc {
  final int bienTheId;
  final String tenSanPham;
  final String mauSac;
  final String kichCo;
  final int donGia;
  final int soLuong;

  const GioHangMuc({
    required this.bienTheId,
    required this.tenSanPham,
    required this.mauSac,
    required this.kichCo,
    required this.donGia,
    required this.soLuong,
  });

  GioHangMuc copyWith({int? soLuong}) => GioHangMuc(
        bienTheId: bienTheId,
        tenSanPham: tenSanPham,
        mauSac: mauSac,
        kichCo: kichCo,
        donGia: donGia,
        soLuong: soLuong ?? this.soLuong,
      );

  int get thanhTien => donGia * soLuong;

  MatHangGio toMatHangGio() => MatHangGio(
        bienTheId: bienTheId,
        tenSanPham: tenSanPham,
        mauSac: mauSac,
        kichCo: kichCo,
        donGia: donGia,
        soLuong: soLuong,
      );
}

class XuatHangState {
  final List<GioHangMuc> gio;
  final String tenKhach;
  final String soDienThoai;
  final bool dangXuat;
  final String? loi;

  const XuatHangState({
    this.gio = const [],
    this.tenKhach = '',
    this.soDienThoai = '',
    this.dangXuat = false,
    this.loi,
  });

  int get tongTien => gio.fold(0, (s, m) => s + m.thanhTien);
  int get tongMuc => gio.fold(0, (s, m) => s + m.soLuong);
  bool get coHang => gio.isNotEmpty;

  XuatHangState copyWith({
    List<GioHangMuc>? gio,
    String? tenKhach,
    String? soDienThoai,
    bool? dangXuat,
    String? loi,
  }) =>
      XuatHangState(
        gio: gio ?? this.gio,
        tenKhach: tenKhach ?? this.tenKhach,
        soDienThoai: soDienThoai ?? this.soDienThoai,
        dangXuat: dangXuat ?? this.dangXuat,
        loi: loi,
      );
}

class XuatHangNotifier extends Notifier<XuatHangState> {
  @override
  XuatHangState build() => const XuatHangState();

  void themBienThe(BienThe bt, SanPham sp, {int soLuong = 1}) {
    final ds = List<GioHangMuc>.from(state.gio);
    final idx = ds.indexWhere((m) => m.bienTheId == bt.id);
    if (idx >= 0) {
      ds[idx] = ds[idx].copyWith(soLuong: ds[idx].soLuong + soLuong);
    } else {
      ds.add(GioHangMuc(
        bienTheId: bt.id!,
        tenSanPham: sp.ten,
        mauSac: bt.mauSac,
        kichCo: bt.kichCo,
        donGia: bt.gia,
        soLuong: soLuong,
      ));
    }
    state = state.copyWith(gio: ds, loi: null);
  }

  void capNhatSoLuong(int bienTheId, int soLuongMoi) {
    if (soLuongMoi <= 0) {
      xoaMuc(bienTheId);
      return;
    }
    final ds = state.gio
        .map((m) => m.bienTheId == bienTheId ? m.copyWith(soLuong: soLuongMoi) : m)
        .toList();
    state = state.copyWith(gio: ds);
  }

  void xoaMuc(int bienTheId) {
    state = state.copyWith(
      gio: state.gio.where((m) => m.bienTheId != bienTheId).toList(),
    );
  }

  void xoaTatCa() => state = state.copyWith(gio: []);

  void capNhatKhach({String? ten, String? soDienThoai}) => state = state.copyWith(
        tenKhach: ten ?? state.tenKhach,
        soDienThoai: soDienThoai ?? state.soDienThoai,
      );

  void nhanKetQuaLenhNhanh(KetQuaLenhNhanh kq) {
    final ds = List<GioHangMuc>.from(state.gio);
    for (final m in kq.gio) {
      final idx = ds.indexWhere((x) => x.bienTheId == m.bienTheId);
      if (idx >= 0) {
        ds[idx] = ds[idx].copyWith(soLuong: ds[idx].soLuong + m.soLuong);
      } else {
        ds.add(GioHangMuc(
          bienTheId: m.bienTheId,
          tenSanPham: m.tenSanPham,
          mauSac: m.mauSac,
          kichCo: m.kichCo,
          donGia: m.donGia,
          soLuong: m.soLuong,
        ));
      }
    }
    state = state.copyWith(
      gio: ds,
      tenKhach: kq.tenKhach != 'Khách lẻ' ? kq.tenKhach : state.tenKhach,
    );
  }

  Future<bool> xuatHang() async {
    if (state.gio.isEmpty) return false;
    state = state.copyWith(dangXuat: true, loi: null);
    try {
      await ref.read(donHangRepositoryProvider).thanhToanNhap(
            tenKhachHang: state.tenKhach.trim().isEmpty ? 'Khách lẻ' : state.tenKhach.trim(),
            soDienThoai: state.soDienThoai.trim(),
            gio: state.gio.map((m) => m.toMatHangGio()).toList(),
            nhanVienId: null,
          );
      ref.read(quanLyDonHangProvider.notifier).lamMoi();
      ref.read(donHangChoProvider.notifier).lamMoi();
      state = const XuatHangState();
      return true;
    } catch (e) {
      state = state.copyWith(dangXuat: false, loi: e.toString());
      return false;
    }
  }
}

final xuatHangProvider =
    NotifierProvider<XuatHangNotifier, XuatHangState>(XuatHangNotifier.new);

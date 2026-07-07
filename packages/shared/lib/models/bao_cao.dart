class DiemBieuDo {
  final String ngay;
  final int doanhThu;
  final int soDon;
  final int soSanPham;
  final int soKhach;

  const DiemBieuDo({
    required this.ngay,
    required this.doanhThu,
    required this.soDon,
    required this.soSanPham,
    required this.soKhach,
  });

  factory DiemBieuDo.fromJson(Map<String, dynamic> j) => DiemBieuDo(
        ngay: (j['ngay'] ?? '').toString(),
        doanhThu: (j['doanh_thu'] ?? 0) as int,
        soDon: (j['so_don'] ?? 0) as int,
        soSanPham: (j['so_sp'] ?? 0) as int,
        soKhach: (j['so_khach'] ?? 0) as int,
      );
}

class SanPhamBanChay {
  final String ten;
  final int soLuong;
  final int doanhThu;

  const SanPhamBanChay({required this.ten, required this.soLuong, required this.doanhThu});

  factory SanPhamBanChay.fromJson(Map<String, dynamic> j) => SanPhamBanChay(
        ten: (j['ten'] ?? '').toString(),
        soLuong: (j['so_luong'] ?? 0) as int,
        doanhThu: (j['doanh_thu'] ?? 0) as int,
      );
}

class KhachMuaNhieu {
  final String ten;
  final int soDon;
  final int tongChi;

  const KhachMuaNhieu({required this.ten, required this.soDon, required this.tongChi});

  factory KhachMuaNhieu.fromJson(Map<String, dynamic> j) => KhachMuaNhieu(
        ten: (j['ten'] ?? '').toString(),
        soDon: (j['so_don'] ?? 0) as int,
        tongChi: (j['tong_chi'] ?? 0) as int,
      );
}

class BaoCao {
  final int tongDoanhThu;
  final int soDonHang;
  final int sanPhamDaBan;
  final int soKhachHang;
  final List<DiemBieuDo> theoDiem;
  final List<SanPhamBanChay> sanPhamBanChay;
  final List<KhachMuaNhieu> khachMuaNhieu;

  const BaoCao({
    required this.tongDoanhThu,
    required this.soDonHang,
    required this.sanPhamDaBan,
    required this.soKhachHang,
    required this.theoDiem,
    required this.sanPhamBanChay,
    required this.khachMuaNhieu,
  });

  factory BaoCao.fromJson(Map<String, dynamic> j) => BaoCao(
        tongDoanhThu: (j['tong_doanh_thu'] ?? 0) as int,
        soDonHang: (j['so_don_hang'] ?? 0) as int,
        sanPhamDaBan: (j['san_pham_da_ban'] ?? 0) as int,
        soKhachHang: (j['so_khach_hang'] ?? 0) as int,
        theoDiem: (j['theo_ngay'] as List? ?? [])
            .map((e) => DiemBieuDo.fromJson(e as Map<String, dynamic>))
            .toList(),
        sanPhamBanChay: (j['san_pham_ban_chay'] as List? ?? [])
            .map((e) => SanPhamBanChay.fromJson(e as Map<String, dynamic>))
            .toList(),
        khachMuaNhieu: (j['khach_mua_nhieu'] as List? ?? [])
            .map((e) => KhachMuaNhieu.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class SanPhamTrongDon {
  final String ten;
  final int soLuong;
  final int donGia;
  final int thanhTien;

  const SanPhamTrongDon({
    required this.ten,
    required this.soLuong,
    required this.donGia,
    required this.thanhTien,
  });

  factory SanPhamTrongDon.fromJson(Map<String, dynamic> j) => SanPhamTrongDon(
        ten: (j['ten'] ?? '').toString(),
        soLuong: (j['so_luong'] ?? 0) as int,
        donGia: (j['don_gia'] ?? 0) as int,
        thanhTien: (j['thanh_tien'] ?? 0) as int,
      );
}

class HoaDonNgay {
  final int id;
  final String maHoaDon;
  final String tenKhachHang;
  final String thoiGian;
  final int tongTien;
  final List<SanPhamTrongDon> sanPham;

  const HoaDonNgay({
    required this.id,
    required this.maHoaDon,
    required this.tenKhachHang,
    required this.thoiGian,
    required this.tongTien,
    required this.sanPham,
  });

  factory HoaDonNgay.fromJson(Map<String, dynamic> j) => HoaDonNgay(
        id: (j['id'] ?? 0) as int,
        maHoaDon: (j['ma_hoa_don'] ?? '').toString(),
        tenKhachHang: (j['ten_khach_hang'] ?? 'Khách lẻ').toString(),
        thoiGian: (j['thoi_gian'] ?? '').toString(),
        tongTien: (j['tong_tien'] ?? 0) as int,
        sanPham: (j['san_pham'] as List? ?? [])
            .map((e) => SanPhamTrongDon.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class DonHangNgay {
  final String ngay;
  final List<HoaDonNgay> donHangs;

  const DonHangNgay({required this.ngay, required this.donHangs});

  factory DonHangNgay.fromJson(Map<String, dynamic> j) => DonHangNgay(
        ngay: (j['ngay'] ?? '').toString(),
        donHangs: (j['don_hangs'] as List? ?? [])
            .map((e) => HoaDonNgay.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

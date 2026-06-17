class MatHangXemTruoc {
  final int bienTheId;
  final String tenSanPham;
  final String mauSac;
  final String kichCo;
  final int donGia;
  int soLuong;

  MatHangXemTruoc({
    required this.bienTheId,
    required this.tenSanPham,
    required this.mauSac,
    required this.kichCo,
    required this.donGia,
    required this.soLuong,
  });

  factory MatHangXemTruoc.fromJson(Map<String, dynamic> j) => MatHangXemTruoc(
        bienTheId: j['bien_the_id'] as int,
        tenSanPham: (j['ten_san_pham'] ?? '').toString(),
        mauSac: (j['mau_sac'] ?? '').toString(),
        kichCo: (j['kich_co'] ?? '').toString(),
        donGia: (j['don_gia'] ?? 0) as int,
        soLuong: (j['so_luong'] ?? 1) as int,
      );

  int get thanhTien => donGia * soLuong;

  Map<String, dynamic> toGioJson() => {
        'variant_id': bienTheId,
        'product_name': tenSanPham,
        'color': mauSac,
        'size': kichCo,
        'price': donGia,
        'quantity': soLuong,
      };
}

class KetQuaLenhNhanh {
  final String tenKhach;
  final int? khachHangId;
  final List<MatHangXemTruoc> gio;
  final List<String> canhBao;
  final int tongTien;

  const KetQuaLenhNhanh({
    required this.tenKhach,
    this.khachHangId,
    required this.gio,
    required this.canhBao,
    required this.tongTien,
  });

  factory KetQuaLenhNhanh.fromJson(Map<String, dynamic> j) => KetQuaLenhNhanh(
        tenKhach: (j['ten_khach'] ?? 'Khách lẻ').toString(),
        khachHangId: j['khach_hang_id'] as int?,
        gio: (j['gio'] as List? ?? [])
            .map((e) => MatHangXemTruoc.fromJson(e as Map<String, dynamic>))
            .toList(),
        canhBao: (j['canh_bao'] as List? ?? []).map((e) => e.toString()).toList(),
        tongTien: (j['tong_tien'] ?? 0) as int,
      );
}

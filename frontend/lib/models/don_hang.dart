import 'dart:convert';

class ChiTietDon {
  final int? chiTietDonId;
  final String tenSanPham;
  final int? bienTheId;
  final String thongTinBienThe;
  final int soLuong;
  final int donGia;
  final int? tonKhoHienTai;
  final bool? duHang;

  const ChiTietDon({
    this.chiTietDonId,
    required this.tenSanPham,
    this.bienTheId,
    required this.thongTinBienThe,
    required this.soLuong,
    required this.donGia,
    this.tonKhoHienTai,
    this.duHang,
  });

  factory ChiTietDon.fromJson(Map<String, dynamic> j) => ChiTietDon(
        chiTietDonId: j['order_item_id'] as int?,
        tenSanPham: (j['product_name'] ?? '').toString(),
        bienTheId: j['variant_id'] as int?,
        thongTinBienThe: (j['variant_info'] ?? '').toString(),
        soLuong: (j['quantity'] ?? 0) as int,
        donGia: (j['price'] ?? 0) as int,
        tonKhoHienTai: j['current_stock'] as int?,
        duHang: j['enough_stock'] as bool?,
      );

  int get thanhTien => soLuong * donGia;
}

class DonHang {
  final int id;
  final String ngayTao;
  final String tenKhachHang;
  final int? khachHangId;
  final int tongTien;
  final int tongSoLuong;
  final String trangThai;
  final String ghiChuPicker;
  final int? nhanVienTaoId;
  final String tenNhanVienTao;
  final int? pickerId;
  final String tenPicker;
  final String ngayNhan;
  final int? nhanVienGiaoId;
  final String tenNhanVienGiao;
  final String ngayGiao;
  final List<String> anhGiaoHang;
  final List<ChiTietDon> chiTiets;

  const DonHang({
    required this.id,
    required this.ngayTao,
    required this.tenKhachHang,
    this.khachHangId,
    required this.tongTien,
    required this.tongSoLuong,
    required this.trangThai,
    this.ghiChuPicker = '',
    this.nhanVienTaoId,
    this.tenNhanVienTao = '',
    this.pickerId,
    this.tenPicker = '',
    this.ngayNhan = '',
    this.nhanVienGiaoId,
    this.tenNhanVienGiao = '',
    this.ngayGiao = '',
    this.anhGiaoHang = const [],
    required this.chiTiets,
  });

  factory DonHang.fromJson(Map<String, dynamic> j) => DonHang(
        id: j['id'] as int,
        ngayTao: (j['created_at'] ?? '').toString(),
        tenKhachHang: (j['customer_name'] ?? 'Khách lẻ').toString(),
        khachHangId: j['customer_id'] as int?,
        tongTien: ((j['total_amount'] ?? 0) as num).toInt(),
        tongSoLuong: ((j['total_qty'] ?? 0) as num).toInt(),
        trangThai: (j['status'] ?? 'completed').toString(),
        ghiChuPicker: (j['picker_note'] ?? '').toString(),
        nhanVienTaoId: j['created_by_employee_id'] as int?,
        tenNhanVienTao: (j['created_by_employee_name'] ?? '').toString(),
        pickerId: j['assigned_picker_id'] as int?,
        tenPicker: (j['assigned_picker_name'] ?? '').toString(),
        ngayNhan: (j['assigned_at'] ?? '').toString(),
        nhanVienGiaoId: j['delivered_by_id'] as int?,
        tenNhanVienGiao: (j['delivered_by_name'] ?? '').toString(),
        ngayGiao: (j['delivered_at'] ?? '').toString(),
        anhGiaoHang: _parseAnhPaths(j),
        chiTiets: (j['items'] as List? ?? [])
            .map((i) => ChiTietDon.fromJson(i as Map<String, dynamic>))
            .toList(),
      );

  static List<String> _parseAnhPaths(Map<String, dynamic> j) {
    final ds = j['delivery_photo_paths'];
    if (ds is List) return ds.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    final raw = (j['delivery_photo_path'] ?? '').toString().trim();
    if (raw.isEmpty) return const [];
    if (raw.startsWith('[')) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) return decoded.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      } catch (_) {}
    }
    return [raw];
  }

  bool get dangCho => trangThai == 'pending';
  bool get daDuyet => trangThai == 'approved';
  bool get dangGiao => trangThai == 'assigned';
  bool get hoanThanh => trangThai == 'completed';

  String get nhanTrangThai {
    switch (trangThai) {
      case 'pending': return 'Chờ duyệt';
      case 'approved': return 'Đã duyệt';
      case 'assigned': return 'Đang giao';
      case 'completed': return 'Hoàn thành';
      default: return trangThai;
    }
  }
}

class MatHangGio {
  final int bienTheId;
  final String tenSanPham;
  final String mauSac;
  final String kichCo;
  final int donGia;
  int soLuong;

  MatHangGio({
    required this.bienTheId,
    required this.tenSanPham,
    required this.mauSac,
    required this.kichCo,
    required this.donGia,
    required this.soLuong,
  });

  Map<String, dynamic> toJson() => {
        'variant_id': bienTheId,
        'product_name': tenSanPham,
        'color': mauSac,
        'size': kichCo,
        'price': donGia,
        'quantity': soLuong,
      };

  int get thanhTien => donGia * soLuong;
}

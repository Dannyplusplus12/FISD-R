class TomTatKhuVuc {
  final int id;
  final String ten;
  final int soKhachHang;
  final int tongNo;

  const TomTatKhuVuc({
    required this.id,
    required this.ten,
    this.soKhachHang = 0,
    this.tongNo = 0,
  });

  factory TomTatKhuVuc.fromJson(Map<String, dynamic> j) => TomTatKhuVuc(
        id: j['id'] as int,
        ten: (j['name'] ?? '').toString(),
        soKhachHang: (j['customer_count'] ?? 0) as int,
        tongNo: (j['total_debt'] ?? 0) as int,
      );
}

class KhachHang {
  final int id;
  final String ten;
  final String soDienThoai;
  final int no;
  final int? khuVucId;
  final String tenKhuVuc;

  const KhachHang({
    required this.id,
    required this.ten,
    required this.soDienThoai,
    required this.no,
    this.khuVucId,
    this.tenKhuVuc = '',
  });

  factory KhachHang.fromJson(Map<String, dynamic> j) => KhachHang(
        id: j['id'] as int,
        ten: (j['name'] ?? '').toString(),
        soDienThoai: (j['phone'] ?? '').toString(),
        no: ((j['debt'] ?? 0) as num).toInt(),
        khuVucId: j['area_id'] as int?,
        tenKhuVuc: (j['area_name'] ?? '').toString(),
      );
}

class LichSuNoItem {
  final int id;
  final String loai;
  final int thayDoi;
  final int? soDuMoi;
  final String ghiChu;
  final String ngayTao;
  final int? nhanVienId;
  final String tenNhanVien;
  final Map<String, dynamic>? orderData;

  const LichSuNoItem({
    required this.id,
    this.loai = 'LOG',
    required this.thayDoi,
    this.soDuMoi,
    required this.ghiChu,
    required this.ngayTao,
    this.nhanVienId,
    this.tenNhanVien = '',
    this.orderData,
  });

  factory LichSuNoItem.fromJson(Map<String, dynamic> j) {
    final loai = (j['type'] ?? 'LOG') as String;
    final rawData = j['data'] as Map<String, dynamic>?;
    final id = loai == 'LOG'
        ? (j['log_id'] as int? ?? 0)
        : (rawData?['id'] as int? ?? 0);
    return LichSuNoItem(
      id: id,
      loai: loai,
      thayDoi: ((j['amount'] ?? 0) as num).toInt(),
      soDuMoi: j['new_balance'] != null ? (j['new_balance'] as num).toInt() : null,
      ghiChu: (j['desc'] ?? '').toString(),
      ngayTao: (j['date'] ?? '').toString(),
      nhanVienId: j['actor_employee_id'] as int?,
      tenNhanVien: (j['actor_employee_name'] ?? '').toString(),
      orderData: loai == 'ORDER' ? rawData : null,
    );
  }
}

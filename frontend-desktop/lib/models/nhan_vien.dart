class NhanVien {
  final int id;
  final String ten;
  final String soDienThoai;
  final String email;
  final String diaChi;
  final String ghiChu;
  final String vaiTro;
  final String pin;
  final bool dangHoatDong;
  final String ngayTao;
  final int soDonGiao;
  final String lanGiaoGanNhat;

  const NhanVien({
    required this.id,
    required this.ten,
    required this.soDienThoai,
    this.email = '',
    this.diaChi = '',
    this.ghiChu = '',
    required this.vaiTro,
    required this.pin,
    this.dangHoatDong = true,
    this.ngayTao = '',
    this.soDonGiao = 0,
    this.lanGiaoGanNhat = '',
  });

  factory NhanVien.fromJson(Map<String, dynamic> j) => NhanVien(
        id: j['id'] as int,
        ten: (j['name'] ?? '').toString(),
        soDienThoai: (j['phone'] ?? '').toString(),
        email: (j['email'] ?? '').toString(),
        diaChi: (j['address'] ?? '').toString(),
        ghiChu: (j['notes'] ?? '').toString(),
        vaiTro: (j['role'] ?? '').toString(),
        pin: (j['pin'] ?? '').toString(),
        dangHoatDong: ((j['is_active'] ?? 1) as num).toInt() == 1,
        ngayTao: (j['created_at'] ?? '').toString(),
        soDonGiao: ((j['delivered_count'] ?? 0) as num).toInt(),
        lanGiaoGanNhat: (j['last_delivered_at'] ?? '').toString(),
      );

  String get nhanVaiTro {
    switch (vaiTro) {
      case 'manager': return 'Quản lý';
      case 'picker': return 'Nhân viên giao hàng';
      case 'orderer': return 'Nhân viên đặt hàng';
      default: return vaiTro;
    }
  }
}

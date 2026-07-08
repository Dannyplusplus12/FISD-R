class KhoHang {
  final int id;
  final String ten;
  final String viTri;
  final String ghiChu;

  const KhoHang({required this.id, required this.ten, this.viTri = '', this.ghiChu = ''});

  factory KhoHang.fromJson(Map<String, dynamic> j) => KhoHang(
        id: j['id'] as int,
        ten: (j['ten'] ?? '').toString(),
        viTri: (j['vi_tri'] ?? '').toString(),
        ghiChu: (j['ghi_chu'] ?? '').toString(),
      );
}

class ViTriKho {
  final int id;
  final String ten;
  final String viTri;

  const ViTriKho({required this.id, required this.ten, this.viTri = ''});

  factory ViTriKho.fromJson(Map<String, dynamic> j) => ViTriKho(
        id: j['id'] as int,
        ten: (j['ten'] ?? '').toString(),
        viTri: (j['vi_tri'] ?? '').toString(),
      );
}

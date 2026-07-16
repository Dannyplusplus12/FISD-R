class ThanhVienChat {
  final int id;
  final String ten;

  const ThanhVienChat({required this.id, required this.ten});

  factory ThanhVienChat.fromJson(Map<String, dynamic> j) =>
      ThanhVienChat(id: j['id'] as int, ten: (j['name'] ?? '').toString());
}

class KenhChat {
  final int id;
  final String ten;
  final String loai; // "kenh_tu_do" | "kenh_don_hang"
  final int? maDonHang;
  final int chuKenhId;
  final List<ThanhVienChat> thanhVien;

  const KenhChat({
    required this.id,
    required this.ten,
    required this.loai,
    this.maDonHang,
    required this.chuKenhId,
    this.thanhVien = const [],
  });

  bool get laKenhDonHang => loai == 'kenh_don_hang';

  factory KenhChat.fromJson(Map<String, dynamic> j) => KenhChat(
        id: j['id'] as int,
        ten: (j['ten'] ?? '').toString(),
        loai: (j['loai'] ?? 'kenh_tu_do').toString(),
        maDonHang: j['ma_don_hang'] as int?,
        chuKenhId: (j['chu_kenh_id'] ?? 0) as int,
        thanhVien: (j['thanh_vien'] as List? ?? [])
            .map((t) => ThanhVienChat.fromJson(t as Map<String, dynamic>))
            .toList(),
      );
}

class TepDinhKem {
  final String s3Key;
  final String tenGoc;
  final String loaiMime;
  final String url;

  const TepDinhKem({required this.s3Key, required this.tenGoc, required this.loaiMime, required this.url});

  bool get laAnh => loaiMime.startsWith('image/');

  factory TepDinhKem.fromJson(Map<String, dynamic> j) => TepDinhKem(
        s3Key: (j['s3_key'] ?? '').toString(),
        tenGoc: (j['ten_goc'] ?? '').toString(),
        loaiMime: (j['loai_mime'] ?? '').toString(),
        url: (j['url'] ?? '').toString(),
      );
}

class TinNhan {
  final int id;
  final int maKenh;
  final int nguoiGuiId;
  final String tenNguoiGui;
  final String noiDung;
  final String loaiTin; // "text" | "anh" | "tep" | "he_thong"
  final String thoiGianGui;
  final List<TepDinhKem> tepDinhKem;

  const TinNhan({
    required this.id,
    required this.maKenh,
    required this.nguoiGuiId,
    required this.tenNguoiGui,
    this.noiDung = '',
    required this.loaiTin,
    required this.thoiGianGui,
    this.tepDinhKem = const [],
  });

  factory TinNhan.fromJson(Map<String, dynamic> j) => TinNhan(
        id: j['id'] as int,
        maKenh: (j['ma_kenh'] ?? 0) as int,
        nguoiGuiId: (j['nguoi_gui_id'] ?? 0) as int,
        tenNguoiGui: (j['ten_nguoi_gui'] ?? '').toString(),
        noiDung: (j['noi_dung'] ?? '').toString(),
        loaiTin: (j['loai_tin'] ?? 'text').toString(),
        thoiGianGui: (j['thoi_gian_gui'] ?? '').toString(),
        tepDinhKem: (j['tep_dinh_kem'] as List? ?? [])
            .map((t) => TepDinhKem.fromJson(t as Map<String, dynamic>))
            .toList(),
      );
}

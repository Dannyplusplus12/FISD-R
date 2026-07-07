class TinNhan {
  final bool laNguoiDung;
  final String noiDung;

  const TinNhan({required this.laNguoiDung, required this.noiDung});
}

class UndoSnapshot {
  final String tenKhach;
  final int? khachHangId;
  final List<MatHangXemTruoc> gio;

  const UndoSnapshot({
    required this.tenKhach,
    this.khachHangId,
    required this.gio,
  });
}

class MatHangXemTruoc {
  final int bienTheId;
  final String tenSanPham;
  final String mauSac;
  final String kichCo;
  final int donGia;
  final int soLuong;

  const MatHangXemTruoc({
    required this.bienTheId,
    required this.tenSanPham,
    required this.mauSac,
    required this.kichCo,
    required this.donGia,
    required this.soLuong,
  });

  int get thanhTien => donGia * soLuong;

  factory MatHangXemTruoc.fromJson(Map<String, dynamic> j) => MatHangXemTruoc(
        bienTheId: (j['bien_the_id'] ?? 0) as int,
        tenSanPham: (j['ten_san_pham'] ?? '').toString(),
        mauSac: (j['mau_sac'] ?? '').toString(),
        kichCo: (j['kich_co'] ?? '').toString(),
        donGia: (j['don_gia'] ?? 0) as int,
        soLuong: (j['so_luong'] ?? 1) as int,
      );

  Map<String, dynamic> toGioJson() => {
        'variant_id': bienTheId,
        'product_name': tenSanPham,
        'color': mauSac,
        'size': kichCo,
        'price': donGia,
        'quantity': soLuong,
      };

  Map<String, dynamic> toGioHienTaiJson() => {
        'bien_the_id': bienTheId,
        'ten_san_pham': tenSanPham,
        'mau_sac': mauSac,
        'kich_co': kichCo,
        'don_gia': donGia,
        'so_luong': soLuong,
      };

  MatHangXemTruoc withSoLuong(int sl) => MatHangXemTruoc(
        bienTheId: bienTheId,
        tenSanPham: tenSanPham,
        mauSac: mauSac,
        kichCo: kichCo,
        donGia: donGia,
        soLuong: sl,
      );
}

class KetQuaHoiThoai {
  final String hanhDong; // cap_nhat | xac_nhan | dat_lai | khong_ro
  final String phanHoi;
  final String tenKhach;
  final int? khachHangId;
  final List<MatHangXemTruoc> gio;
  final List<String> canhBao;
  final int tongTien;

  const KetQuaHoiThoai({
    required this.hanhDong,
    required this.phanHoi,
    required this.tenKhach,
    this.khachHangId,
    required this.gio,
    required this.canhBao,
    required this.tongTien,
  });

  factory KetQuaHoiThoai.fromJson(Map<String, dynamic> j) => KetQuaHoiThoai(
        hanhDong: (j['hanh_dong'] ?? 'cap_nhat').toString(),
        phanHoi: (j['phan_hoi'] ?? '').toString(),
        tenKhach: (j['ten_khach'] ?? 'Khách lẻ').toString(),
        khachHangId: j['khach_hang_id'] as int?,
        gio: (j['gio'] as List? ?? [])
            .map((e) => MatHangXemTruoc.fromJson(e as Map<String, dynamic>))
            .toList(),
        canhBao: (j['canh_bao'] as List? ?? []).map((e) => e.toString()).toList(),
        tongTien: (j['tong_tien'] ?? 0) as int,
      );
}

class PhienLenhNhanh {
  final List<TinNhan> lichSu;
  final String tenKhach;
  final int? khachHangId;
  final List<MatHangXemTruoc> gio;
  final List<String> canhBao;
  final bool dangTai;
  final String? loi;
  final bool sanSangTaoDon;
  final List<UndoSnapshot> undoStack;

  const PhienLenhNhanh({
    required this.lichSu,
    required this.tenKhach,
    this.khachHangId,
    required this.gio,
    required this.canhBao,
    required this.dangTai,
    this.loi,
    required this.sanSangTaoDon,
    required this.undoStack,
  });

  static PhienLenhNhanh khoi() => const PhienLenhNhanh(
        lichSu: [],
        tenKhach: 'Khách lẻ',
        khachHangId: null,
        gio: [],
        canhBao: [],
        dangTai: false,
        loi: null,
        sanSangTaoDon: false,
        undoStack: [],
      );

  int get tongTien => gio.fold(0, (s, m) => s + m.thanhTien);
  bool get coTheHoanTac => undoStack.isNotEmpty;

  PhienLenhNhanh copyWith({
    List<TinNhan>? lichSu,
    String? tenKhach,
    Object? khachHangId = _sentinel,
    List<MatHangXemTruoc>? gio,
    List<String>? canhBao,
    bool? dangTai,
    Object? loi = _sentinel,
    bool? sanSangTaoDon,
    List<UndoSnapshot>? undoStack,
  }) =>
      PhienLenhNhanh(
        lichSu: lichSu ?? this.lichSu,
        tenKhach: tenKhach ?? this.tenKhach,
        khachHangId: khachHangId == _sentinel
            ? this.khachHangId
            : khachHangId as int?,
        gio: gio ?? this.gio,
        canhBao: canhBao ?? this.canhBao,
        dangTai: dangTai ?? this.dangTai,
        loi: loi == _sentinel ? this.loi : loi as String?,
        sanSangTaoDon: sanSangTaoDon ?? this.sanSangTaoDon,
        undoStack: undoStack ?? this.undoStack,
      );
}

const Object _sentinel = Object();

// ── Legacy models (dùng bởi endpoint /lenh-nhanh cũ, giữ cho tương thích) ──

class ItemAI {
  final String sp;
  final String? mau;
  final String? size;
  final int sl;

  const ItemAI({required this.sp, this.mau, this.size, required this.sl});

  factory ItemAI.fromJson(Map<String, dynamic> j) => ItemAI(
        sp: (j['sp'] ?? '').toString(),
        mau: j['mau']?.toString(),
        size: j['size']?.toString(),
        sl: (j['sl'] ?? 1) as int,
      );

  Map<String, dynamic> toJson() => {
        'sp': sp,
        if (mau != null) 'mau': mau,
        if (size != null) 'size': size,
        'sl': sl,
      };
}

class IntentAI {
  final String khach;
  final List<ItemAI> items;

  const IntentAI({required this.khach, required this.items});

  factory IntentAI.fromJson(Map<String, dynamic> j) => IntentAI(
        khach: (j['khach'] ?? 'Khách lẻ').toString(),
        items: (j['items'] as List? ?? [])
            .map((e) => ItemAI.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'khach': khach,
        'items': items.map((e) => e.toJson()).toList(),
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

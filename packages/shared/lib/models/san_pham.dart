class BienThe {
  final int? id;
  final String mauSac;
  final String kichCo;
  final int gia;
  final int tonKho;

  const BienThe({
    this.id,
    required this.mauSac,
    required this.kichCo,
    required this.gia,
    required this.tonKho,
  });

  factory BienThe.fromJson(Map<String, dynamic> j) => BienThe(
        id: j['id'] as int?,
        mauSac: (j['color'] ?? '').toString(),
        kichCo: (j['size'] ?? '').toString(),
        gia: (j['price'] ?? 0) as int,
        tonKho: (j['stock'] ?? 0) as int,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'color': mauSac,
        'size': kichCo,
        'price': gia,
        'stock': tonKho,
      };

  String get tenHienThi {
    final phan = [if (mauSac.isNotEmpty) mauSac, if (kichCo.isNotEmpty) kichCo];
    return phan.isEmpty ? 'Mặc định' : phan.join(' / ');
  }
}

class SanPham {
  final int id;
  final String ma;
  final String ten;
  final String anh;
  final String anhKey;
  final String khoangGia;
  final List<BienThe> bienThes;

  const SanPham({
    required this.id,
    required this.ma,
    required this.ten,
    required this.anh,
    required this.anhKey,
    required this.khoangGia,
    required this.bienThes,
  });

  factory SanPham.fromJson(Map<String, dynamic> j) => SanPham(
        id: j['id'] as int,
        ma: (j['code'] ?? '').toString(),
        ten: (j['name'] ?? '').toString(),
        anh: (j['image'] ?? '').toString(),
        anhKey: (j['image_key'] ?? '').toString(),
        khoangGia: (j['price_range'] ?? '').toString(),
        bienThes: (j['variants'] as List? ?? [])
            .map((v) => BienThe.fromJson(v as Map<String, dynamic>))
            .toList(),
      );

  int get tongTonKho => bienThes.fold(0, (tong, v) => tong + v.tonKho);
}

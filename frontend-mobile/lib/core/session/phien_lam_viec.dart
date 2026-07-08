import 'package:shared_preferences/shared_preferences.dart';

class PhienLamViec {
  static const _kId = 'nv_id';
  static const _kTen = 'nv_ten';
  static const _kSoDt = 'nv_so_dt';
  static const _kVaiTro = 'nv_vai_tro';
  static const _kPin = 'nv_pin';

  final int id;
  final String ten;
  final String soDienThoai;
  final String vaiTro;
  final String pin;

  const PhienLamViec({
    required this.id,
    required this.ten,
    required this.soDienThoai,
    required this.vaiTro,
    required this.pin,
  });

  bool get laPicker => vaiTro == 'picker';
  bool get laManager => vaiTro == 'manager';
  bool get laOrderer => vaiTro == 'orderer';

  static Future<PhienLamViec?> tai() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_kId);
    if (id == null) return null;
    return PhienLamViec(
      id: id,
      ten: prefs.getString(_kTen) ?? '',
      soDienThoai: prefs.getString(_kSoDt) ?? '',
      vaiTro: prefs.getString(_kVaiTro) ?? '',
      pin: prefs.getString(_kPin) ?? '',
    );
  }

  static Future<void> luu({
    required int id,
    required String ten,
    required String soDienThoai,
    required String vaiTro,
    required String pin,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kId, id);
    await prefs.setString(_kTen, ten);
    await prefs.setString(_kSoDt, soDienThoai);
    await prefs.setString(_kVaiTro, vaiTro);
    await prefs.setString(_kPin, pin);
  }

  static Future<void> xoa() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

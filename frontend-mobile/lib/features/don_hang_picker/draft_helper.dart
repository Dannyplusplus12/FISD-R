import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class DraftItem {
  final int orderItemId;
  final int? variantId;
  final String productName;
  final String variantInfo;
  final String image;
  final int maxQty;
  int pickedQty;
  int? selectedKhoId;
  String? selectedKhoTen;
  final List<Map<String, dynamic>> warehouses;

  DraftItem({
    required this.orderItemId,
    this.variantId,
    required this.productName,
    required this.variantInfo,
    required this.image,
    required this.maxQty,
    required this.pickedQty,
    this.selectedKhoId,
    this.selectedKhoTen,
    required this.warehouses,
  });

  // Kho/số lượng luôn lấy từ backend (SoanKhoTrangThai) — đồng bộ realtime giữa các picker,
  // không còn lưu local nữa.
  factory DraftItem.fromApi(Map<String, dynamic> j) {
    final warehouses = List<Map<String, dynamic>>.from(j['warehouses'] as List? ?? []);
    final khoId = j['selected_kho_id'] as int?;
    String? khoTen;
    if (khoId != null) {
      final match = warehouses.where((w) => w['id'] == khoId);
      if (match.isNotEmpty) khoTen = match.first['ten'] as String?;
    }
    final soLuongChon = (j['selected_qty'] as num?)?.toInt() ?? 0;
    final maxQty = (j['quantity'] as num).toInt();
    return DraftItem(
      orderItemId: j['order_item_id'] as int,
      variantId: j['variant_id'] as int?,
      productName: (j['product_name'] ?? '').toString(),
      variantInfo: (j['variant_info'] ?? '').toString(),
      image: (j['image'] ?? '').toString(),
      maxQty: maxQty,
      pickedQty: soLuongChon > 0 ? soLuongChon : maxQty,
      selectedKhoId: khoId,
      selectedKhoTen: khoTen,
      warehouses: warehouses,
    );
  }
}

class DraftSoanKho {
  final int orderId;
  final String customerName;
  final List<DraftItem> items;
  String ghiChu;
  List<String> anhPaths; // file paths, best-effort — chỉ lưu local trên máy

  DraftSoanKho({
    required this.orderId,
    required this.customerName,
    required this.items,
    this.ghiChu = '',
    List<String>? anhPaths,
  }) : anhPaths = anhPaths ?? [];

  static String _key(int orderId) => 'soan_kho_local_$orderId';

  /// Chỉ lưu local ghi chú + ảnh xác nhận (chưa gửi) — kho/số lượng đã đồng bộ backend ngay khi đổi.
  Future<void> luu() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(orderId), jsonEncode({'ghi_chu': ghiChu, 'anh_paths': anhPaths}));
  }

  static Future<Map<String, dynamic>?> taiLocal(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(orderId));
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final paths = List<String>.from(j['anh_paths'] as List? ?? []);
      return {
        'ghi_chu': (j['ghi_chu'] ?? '').toString(),
        'anh_paths': paths.where((p) => File(p).existsSync()).toList(),
      };
    } catch (_) {
      return null;
    }
  }

  static Future<void> xoa(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(orderId));
  }
}

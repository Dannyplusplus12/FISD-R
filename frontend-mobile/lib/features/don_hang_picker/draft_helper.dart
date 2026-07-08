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

  Map<String, dynamic> toJson() => {
        'order_item_id': orderItemId,
        'variant_id': variantId,
        'product_name': productName,
        'variant_info': variantInfo,
        'image': image,
        'max_qty': maxQty,
        'picked_qty': pickedQty,
        'selected_kho_id': selectedKhoId,
        'selected_kho_ten': selectedKhoTen,
        'warehouses': warehouses,
      };

  factory DraftItem.fromJson(Map<String, dynamic> j) => DraftItem(
        orderItemId: j['order_item_id'] as int,
        variantId: j['variant_id'] as int?,
        productName: (j['product_name'] ?? '').toString(),
        variantInfo: (j['variant_info'] ?? '').toString(),
        image: (j['image'] ?? '').toString(),
        maxQty: (j['max_qty'] as num).toInt(),
        pickedQty: (j['picked_qty'] as num).toInt(),
        selectedKhoId: j['selected_kho_id'] as int?,
        selectedKhoTen: j['selected_kho_ten'] as String?,
        warehouses: List<Map<String, dynamic>>.from(j['warehouses'] as List? ?? []),
      );

  factory DraftItem.fromApi(Map<String, dynamic> j) => DraftItem(
        orderItemId: j['order_item_id'] as int,
        variantId: j['variant_id'] as int?,
        productName: (j['product_name'] ?? '').toString(),
        variantInfo: (j['variant_info'] ?? '').toString(),
        image: (j['image'] ?? '').toString(),
        maxQty: (j['quantity'] as num).toInt(),
        pickedQty: (j['quantity'] as num).toInt(),
        warehouses: List<Map<String, dynamic>>.from(j['warehouses'] as List? ?? []),
      );
}

class DraftSoanKho {
  final int orderId;
  final String customerName;
  final List<DraftItem> items;
  String ghiChu;
  List<String> anhPaths; // file paths, best-effort

  DraftSoanKho({
    required this.orderId,
    required this.customerName,
    required this.items,
    this.ghiChu = '',
    List<String>? anhPaths,
  }) : anhPaths = anhPaths ?? [];

  static String _key(int orderId) => 'soan_kho_don_$orderId';

  Future<void> luu() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'order_id': orderId,
      'customer_name': customerName,
      'items': items.map((i) => i.toJson()).toList(),
      'ghi_chu': ghiChu,
      'anh_paths': anhPaths,
    };
    await prefs.setString(_key(orderId), jsonEncode(data));
  }

  static Future<DraftSoanKho?> tai(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(orderId));
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final paths = List<String>.from(j['anh_paths'] as List? ?? []);
      // Lọc path không còn tồn tại
      final validPaths = paths.where((p) => File(p).existsSync()).toList();
      return DraftSoanKho(
        orderId: orderId,
        customerName: (j['customer_name'] ?? '').toString(),
        items: (j['items'] as List).map((i) => DraftItem.fromJson(i as Map<String, dynamic>)).toList(),
        ghiChu: (j['ghi_chu'] ?? '').toString(),
        anhPaths: validPaths,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> xoa(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(orderId));
  }
}

import 'dart:convert';

// ── Order Models ──────────────────────────────────────────────────────────────
//
// Order status flow:
//   pending → approved → assigned → completed
//
// pending  = orderer created a draft, waiting for manager to approve
// approved = manager approved, waiting for picker to accept
// assigned = picker accepted, preparing to deliver
// completed = picker delivered with photo proof

class OrderItem {
  final int? orderItemId;
  final String productName;
  final int? variantId;
  final String variantInfo;
  final int quantity;
  final int price;          // VND
  final int? currentStock;
  final bool? enoughStock;

  const OrderItem({
    this.orderItemId,
    required this.productName,
    this.variantId,
    required this.variantInfo,
    required this.quantity,
    required this.price,
    this.currentStock,
    this.enoughStock,
  });

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        orderItemId: j['order_item_id'] as int?,
        productName: (j['product_name'] ?? '').toString(),
        variantId: j['variant_id'] as int?,
        variantInfo: (j['variant_info'] ?? '').toString(),
        quantity: (j['quantity'] ?? 0) as int,
        price: (j['price'] ?? 0) as int,
        currentStock: j['current_stock'] as int?,
        enoughStock: j['enough_stock'] as bool?,
      );

  int get subtotal => quantity * price;
}

class Order {
  final int id;
  final String createdAt;
  final String customerName;
  final int? customerId;
  final int totalAmount;    // VND
  final int totalQty;
  final String status;      // 'pending' | 'approved' | 'assigned' | 'completed'
  final String pickerNote;
  final int? createdByEmployeeId;
  final String createdByEmployeeName;
  final int? assignedPickerId;
  final String assignedPickerName;
  final String assignedAt;
  final int? deliveredById;
  final String deliveredByName;
  final String deliveredAt;
  final List<String> deliveryPhotoPaths;
  final List<OrderItem> items;

  const Order({
    required this.id,
    required this.createdAt,
    required this.customerName,
    this.customerId,
    required this.totalAmount,
    required this.totalQty,
    required this.status,
    this.pickerNote = '',
    this.createdByEmployeeId,
    this.createdByEmployeeName = '',
    this.assignedPickerId,
    this.assignedPickerName = '',
    this.assignedAt = '',
    this.deliveredById,
    this.deliveredByName = '',
    this.deliveredAt = '',
    this.deliveryPhotoPaths = const [],
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: j['id'] as int,
        createdAt: (j['created_at'] ?? '').toString(),
        customerName: (j['customer_name'] ?? 'Khách lẻ').toString(),
        customerId: j['customer_id'] as int?,
        totalAmount: ((j['total_amount'] ?? 0) as num).toInt(),
        totalQty: ((j['total_qty'] ?? 0) as num).toInt(),
        status: (j['status'] ?? 'completed').toString(),
        pickerNote: (j['picker_note'] ?? '').toString(),
        createdByEmployeeId: j['created_by_employee_id'] as int?,
        createdByEmployeeName: (j['created_by_employee_name'] ?? '').toString(),
        assignedPickerId: j['assigned_picker_id'] as int?,
        assignedPickerName: (j['assigned_picker_name'] ?? '').toString(),
        assignedAt: (j['assigned_at'] ?? '').toString(),
        deliveredById: j['delivered_by_id'] as int?,
        deliveredByName: (j['delivered_by_name'] ?? '').toString(),
        deliveredAt: (j['delivered_at'] ?? '').toString(),
        deliveryPhotoPaths: _parsePhotoPaths(j),
        items: (j['items'] as List? ?? [])
            .map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
            .toList(),
      );

  // Helper: backend may return photos as a JSON array string, pipe-separated, or a list.
  static List<String> _parsePhotoPaths(Map<String, dynamic> j) {
    final rawList = j['delivery_photo_paths'];
    if (rawList is List) {
      return rawList.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    final raw = (j['delivery_photo_path'] ?? '').toString().trim();
    if (raw.isEmpty) return const [];
    if (raw.startsWith('[')) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) return decoded.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      } catch (_) {}
    }
    if (raw.contains('|')) return raw.split('|').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    return [raw];
  }

  // Convenience getters
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isAssigned => status == 'assigned';
  bool get isCompleted => status == 'completed';

  String get statusLabel {
    switch (status) {
      case 'pending': return 'Chờ duyệt';
      case 'approved': return 'Đã duyệt';
      case 'assigned': return 'Đang giao';
      case 'completed': return 'Hoàn thành';
      default: return status;
    }
  }
}

// ── CartItem ──────────────────────────────────────────────────────────────────
// Used when creating or editing an order in the POS screen.
class CartItem {
  final int variantId;
  final String productName;
  final String color;
  final String size;
  final int price;
  int quantity;

  CartItem({
    required this.variantId,
    required this.productName,
    required this.color,
    required this.size,
    required this.price,
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
        'variant_id': variantId,
        'product_name': productName,
        'color': color,
        'size': size,
        'price': price,
        'quantity': quantity,
      };

  int get subtotal => price * quantity;
}

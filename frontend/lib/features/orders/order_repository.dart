import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../models/order.dart';

class OrderRepository {
  final Dio _dio;

  const OrderRepository(this._dio);

  // ── Read ──────────────────────────────────────────────────────────────────

  Future<List<Order>> getPending() async {
    final r = await _dio.get(ApiEndpoints.pendingOrders);
    return _parseOrderList(r.data);
  }

  Future<List<Order>> getApproved() async {
    final r = await _dio.get(ApiEndpoints.approvedOrders);
    return _parseOrderList(r.data);
  }

  Future<List<Order>> getManagement({int limit = 200}) async {
    final r = await _dio.get(ApiEndpoints.managementOrders, queryParameters: {'limit': limit});
    return _parseOrderList(r.data);
  }

  Future<Map<String, dynamic>> getPage({int page = 1, int limit = 20}) async {
    final r = await _dio.get(ApiEndpoints.orders, queryParameters: {'page': page, 'limit': limit});
    final j = r.data as Map<String, dynamic>;
    return {
      'data': (j['data'] as List).map((e) => Order.fromJson(e as Map<String, dynamic>)).toList(),
      'total': j['total'],
      'page': j['page'],
      'limit': j['limit'],
    };
  }

  // ── Order lifecycle ───────────────────────────────────────────────────────

  Future<void> checkout({
    required String customerName,
    String customerPhone = '',
    required List<CartItem> cart,
    int? employeeId,
  }) async {
    await _dio.post(ApiEndpoints.checkout, data: {
      'customer_name': customerName,
      'customer_phone': customerPhone,
      if (employeeId != null) 'employee_id': employeeId,
      'cart': cart.map((e) => e.toJson()).toList(),
    });
  }

  Future<void> checkoutDraft({
    required String customerName,
    String customerPhone = '',
    required List<CartItem> cart,
    int? employeeId,
  }) async {
    await _dio.post(ApiEndpoints.checkoutDraft, data: {
      'customer_name': customerName,
      'customer_phone': customerPhone,
      if (employeeId != null) 'employee_id': employeeId,
      'cart': cart.map((e) => e.toJson()).toList(),
    });
  }

  Future<Map<String, dynamic>> approve(int orderId) async {
    final r = await _dio.put(ApiEndpoints.approveOrder(orderId));
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> reject(int orderId) async {
    final r = await _dio.delete(ApiEndpoints.rejectOrder(orderId));
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> cancel(int orderId) async {
    final r = await _dio.delete(ApiEndpoints.cancelOrder(orderId));
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> receive(int orderId, {required int pickerId}) async {
    final r = await _dio.put(ApiEndpoints.receiveOrder(orderId), data: {'picker_id': pickerId});
    return r.data as Map<String, dynamic>;
  }

  Future<void> delete(int orderId) async {
    await _dio.delete(ApiEndpoints.order(orderId));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static List<Order> _parseOrderList(dynamic data) {
    final list = data is Map ? (data['data'] as List? ?? []) : (data as List? ?? []);
    return list.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.watch(apiClientProvider));
});

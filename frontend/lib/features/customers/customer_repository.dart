import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../models/customer.dart';

class CustomerRepository {
  final Dio _dio;

  const CustomerRepository(this._dio);

  // ── Areas ────────────────────────────────────────────────────────────────

  Future<List<AreaSummary>> getAreas() async {
    final r = await _dio.get(ApiEndpoints.areas);
    return (r.data as List)
        .map((e) => AreaSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createArea(String name) async {
    await _dio.post(ApiEndpoints.areas, data: {'name': name});
  }

  Future<void> updateArea(int id, String name) async {
    await _dio.put(ApiEndpoints.area(id), data: {'name': name});
  }

  Future<void> deleteArea(int id) async {
    await _dio.delete(ApiEndpoints.area(id));
  }

  // ── Customers ────────────────────────────────────────────────────────────

  Future<List<Customer>> getAll() async {
    final r = await _dio.get(ApiEndpoints.customers);
    return (r.data as List)
        .map((e) => Customer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> create({
    required String name,
    String phone = '',
    int debt = 0,
    required int areaId,
  }) async {
    final r = await _dio.post(ApiEndpoints.customers, data: {
      'name': name,
      'phone': phone,
      'debt': debt,
      'area_id': areaId,
    });
    return r.data as Map<String, dynamic>;
  }

  Future<void> update(
    int id, {
    required String name,
    required String phone,
    required int debt,
    required int areaId,
  }) async {
    await _dio.put(ApiEndpoints.customer(id), data: {
      'name': name,
      'phone': phone,
      'debt': debt,
      'area_id': areaId,
    });
  }

  Future<void> delete(int id) async {
    await _dio.delete(ApiEndpoints.customer(id));
  }

  // ── Debt history ────────────────────────────────────────────────────────

  Future<List<HistoryItem>> getHistory(int customerId) async {
    final r = await _dio.get(ApiEndpoints.customerHistory(customerId));
    return (r.data as List)
        .map((e) => HistoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addDebtLog(
    int customerId, {
    required int changeAmount,
    required String note,
    String? createdAt,
    int? actorEmployeeId,
  }) async {
    await _dio.post(ApiEndpoints.customerHistory(customerId), data: {
      'change_amount': changeAmount,
      'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (actorEmployeeId != null) 'actor_employee_id': actorEmployeeId,
    });
  }
}

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository(ref.watch(apiClientProvider));
});

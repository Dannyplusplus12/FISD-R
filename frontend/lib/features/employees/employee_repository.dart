import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../models/employee.dart';

class EmployeeRepository {
  final Dio _dio;

  const EmployeeRepository(this._dio);

  Future<List<Employee>> getAll() async {
    final r = await _dio.get(ApiEndpoints.employees);
    return (r.data as List)
        .map((e) => Employee.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> create({
    required String name,
    required String phone,
    required String role,
    String email = '',
    String address = '',
    String notes = '',
  }) async {
    final r = await _dio.post(ApiEndpoints.employees, data: {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'notes': notes,
      'role': role,
    });
    return r.data as Map<String, dynamic>;
  }

  Future<void> update(
    int id, {
    required String name,
    required String phone,
    required String role,
    String email = '',
    String address = '',
    String notes = '',
    String? pin,
    bool isActive = true,
  }) async {
    await _dio.put(ApiEndpoints.employee(id), data: {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'notes': notes,
      'role': role,
      if (pin != null) 'pin': pin,
      'is_active': isActive ? 1 : 0,
    });
  }

  Future<void> delete(int id) async {
    await _dio.delete(ApiEndpoints.employee(id));
  }
}

final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  return EmployeeRepository(ref.watch(apiClientProvider));
});

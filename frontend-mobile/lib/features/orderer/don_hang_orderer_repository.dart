import 'package:fisd_shared/fisd_shared.dart';
import '../../core/api/api_client.dart';

class DonHangOrdererRepository {
  Future<List<Map<String, dynamic>>> layDonCuaOrderer(int ordererId) async {
    final res = await ApiClient.dio.get(ApiEndpoints.donHangQuanLy);
    final all = List<Map<String, dynamic>>.from((res.data['data'] as List? ?? []));
    return all.where((d) => d['created_by_employee_id'] == ordererId).toList();
  }

  Future<int> taoDon({
    required int employeeId,
    required String customerName,
    required String customerPhone,
    required List<Map<String, dynamic>> cart,
  }) async {
    final res = await ApiClient.dio.post(ApiEndpoints.thanhToanNhap, data: {
      'employee_id': employeeId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'cart': cart,
    });
    return (res.data['order_id'] as num).toInt();
  }

  Future<List<Map<String, dynamic>>> layKhachHangs() async {
    final res = await ApiClient.dio.get(ApiEndpoints.khachHangs);
    return List<Map<String, dynamic>>.from(res.data as List? ?? []);
  }

  Future<List<Map<String, dynamic>>> laySanPhams({String search = ''}) async {
    final res = await ApiClient.dio.get(ApiEndpoints.sanPhams,
        queryParameters: search.isNotEmpty ? {'search': search} : null);
    return List<Map<String, dynamic>>.from(res.data as List? ?? []);
  }

  Future<void> huyDon(int donId) async {
    await ApiClient.dio.delete(ApiEndpoints.huyDon(donId));
  }
}

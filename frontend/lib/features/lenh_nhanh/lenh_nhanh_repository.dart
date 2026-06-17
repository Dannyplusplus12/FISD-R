import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import 'lenh_nhanh_model.dart';

class LenhNhanhRepository {
  final Dio _dio;
  const LenhNhanhRepository(this._dio);

  Future<KetQuaLenhNhanh> phanTich(String lenh) async {
    final r = await _dio.post(ApiEndpoints.lenhNhanh, data: {'lenh': lenh});
    return KetQuaLenhNhanh.fromJson(r.data as Map<String, dynamic>);
  }

  Future<int> taoDon({
    required String tenKhach,
    int? khachHangId,
    required List<MatHangXemTruoc> gio,
    int? nhanVienId,
  }) async {
    final r = await _dio.post(ApiEndpoints.thanhToanNhap, data: {
      'customer_name': tenKhach,
      if (nhanVienId != null) 'employee_id': nhanVienId,
      'cart': gio.map((e) => e.toGioJson()).toList(),
    });
    return (r.data['order_id'] ?? 0) as int;
  }
}

final lenhNhanhRepositoryProvider = Provider<LenhNhanhRepository>(
  (ref) => LenhNhanhRepository(ref.watch(apiClientProvider)),
);

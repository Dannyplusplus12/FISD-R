import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../models/nhan_vien.dart';

class NhanVienRepository {
  final Dio _dio;

  const NhanVienRepository(this._dio);

  Future<List<NhanVien>> layTatCa() async {
    final r = await _dio.get(ApiEndpoints.nhanViens);
    return (r.data as List).map((e) => NhanVien.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> tao({
    required String ten,
    required String soDienThoai,
    required String vaiTro,
    String email = '',
    String diaChi = '',
    String ghiChu = '',
  }) async {
    final r = await _dio.post(ApiEndpoints.nhanViens, data: {
      'name': ten, 'phone': soDienThoai, 'email': email,
      'address': diaChi, 'notes': ghiChu, 'role': vaiTro,
    });
    return r.data as Map<String, dynamic>;
  }

  Future<void> capNhat(int id, {
    required String ten,
    required String soDienThoai,
    required String vaiTro,
    String email = '',
    String diaChi = '',
    String ghiChu = '',
    String? pin,
    bool dangHoatDong = true,
  }) async {
    await _dio.put(ApiEndpoints.nhanVien(id), data: {
      'name': ten, 'phone': soDienThoai, 'email': email,
      'address': diaChi, 'notes': ghiChu, 'role': vaiTro,
      if (pin != null) 'pin': pin,
      'is_active': dangHoatDong ? 1 : 0,
    });
  }

  Future<void> xoa(int id) async {
    await _dio.delete(ApiEndpoints.nhanVien(id));
  }
}

final nhanVienRepositoryProvider = Provider<NhanVienRepository>((ref) {
  return NhanVienRepository(ref.watch(apiClientProvider));
});

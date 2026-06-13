import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../models/khach_hang.dart';

class KhachHangRepository {
  final Dio _dio;

  const KhachHangRepository(this._dio);

  Future<List<TomTatKhuVuc>> layKhuVucs() async {
    final r = await _dio.get(ApiEndpoints.khuVucs);
    return (r.data as List).map((e) => TomTatKhuVuc.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> taoKhuVuc(String ten) async {
    await _dio.post(ApiEndpoints.khuVucs, data: {'name': ten});
  }

  Future<void> suaKhuVuc(int id, String ten) async {
    await _dio.put(ApiEndpoints.khuVuc(id), data: {'name': ten});
  }

  Future<void> xoaKhuVuc(int id) async {
    await _dio.delete(ApiEndpoints.khuVuc(id));
  }

  Future<List<KhachHang>> layTatCa() async {
    final r = await _dio.get(ApiEndpoints.khachHangs);
    return (r.data as List).map((e) => KhachHang.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> tao({
    required String ten,
    String soDienThoai = '',
    int no = 0,
    required int khuVucId,
  }) async {
    final r = await _dio.post(ApiEndpoints.khachHangs, data: {
      'name': ten, 'phone': soDienThoai, 'debt': no, 'area_id': khuVucId,
    });
    return r.data as Map<String, dynamic>;
  }

  Future<void> capNhat(int id, {
    required String ten,
    required String soDienThoai,
    required int no,
    required int khuVucId,
  }) async {
    await _dio.put(ApiEndpoints.khachHang(id), data: {
      'name': ten, 'phone': soDienThoai, 'debt': no, 'area_id': khuVucId,
    });
  }

  Future<void> xoa(int id) async {
    await _dio.delete(ApiEndpoints.khachHang(id));
  }

  Future<List<LichSuNoItem>> layLichSuNo(int khachHangId) async {
    final r = await _dio.get(ApiEndpoints.lichSuNo(khachHangId));
    return (r.data as List).map((e) => LichSuNoItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> themLichSuNo(int khachHangId, {
    required int thayDoi,
    required String ghiChu,
    String? ngayTao,
    int? nhanVienId,
  }) async {
    await _dio.post(ApiEndpoints.lichSuNo(khachHangId), data: {
      'change_amount': thayDoi, 'note': ghiChu,
      if (ngayTao != null) 'created_at': ngayTao,
      if (nhanVienId != null) 'actor_employee_id': nhanVienId,
    });
  }
}

final khachHangRepositoryProvider = Provider<KhachHangRepository>((ref) {
  return KhachHangRepository(ref.watch(apiClientProvider));
});

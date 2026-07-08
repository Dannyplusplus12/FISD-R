import 'package:fisd_shared/fisd_shared.dart';
import '../../core/api/api_client.dart';

class KhachHangOrdererRepository {
  Future<List<KhachHang>> layKhachHangs() async {
    final res = await ApiClient.dio.get(ApiEndpoints.khachHangs);
    return (res.data as List)
        .map((j) => KhachHang.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<TomTatKhuVuc>> layKhuVucs() async {
    final res = await ApiClient.dio.get(ApiEndpoints.khuVucs);
    return (res.data as List)
        .map((j) => TomTatKhuVuc.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<KhachHang> taoKhachHang({
    required String ten,
    required String soDt,
    int? khuVucId,
  }) async {
    final res = await ApiClient.dio.post(ApiEndpoints.khachHangs, data: {
      'name': ten,
      'phone': soDt,
      if (khuVucId != null) 'area_id': khuVucId,
    });
    return KhachHang.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> capNhatKhachHang({
    required int id,
    required String ten,
    required String soDt,
    int? khuVucId,
  }) async {
    await ApiClient.dio.put(ApiEndpoints.khachHang(id), data: {
      'name': ten,
      'phone': soDt,
      if (khuVucId != null) 'area_id': khuVucId,
    });
  }

  Future<void> xoaKhachHang(int id) async {
    await ApiClient.dio.delete(ApiEndpoints.khachHang(id));
  }

  Future<List<LichSuNoItem>> layLichSuNo(int khId) async {
    final res = await ApiClient.dio.get(ApiEndpoints.lichSuNo(khId));
    return (res.data as List)
        .map((j) => LichSuNoItem.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> themNoItem({
    required int khId,
    required int nhanVienId,
    required int soTien,
    required String ghiChu,
  }) async {
    await ApiClient.dio.post(ApiEndpoints.lichSuNo(khId), data: {
      'change_amount': soTien,
      'note': ghiChu,
      'actor_employee_id': nhanVienId,
    });
  }

  Future<void> xoaNoItem(int khId, int logId) async {
    await ApiClient.dio.delete(ApiEndpoints.lichSuNoItem(khId, logId));
  }
}

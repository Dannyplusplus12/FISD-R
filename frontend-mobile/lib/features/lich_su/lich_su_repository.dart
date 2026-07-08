import 'package:dio/dio.dart';
import 'package:fisd_shared/fisd_shared.dart';
import '../../core/api/api_client.dart';

class LichSuRepository {
  Future<List<Map<String, dynamic>>> layLichSuGiao(int pickerId, {int days = 0}) async {
    final res = await ApiClient.dio.get(
      ApiEndpoints.giaoDongNhanVien(pickerId),
      queryParameters: {'days': days, 'limit': 500},
    );
    final data = res.data['data'] as List? ?? [];
    return data.where((x) => x['type'] == 'ORDER').map((x) => x['order'] as Map<String, dynamic>).toList();
  }

  Future<void> suaGhiChu(int donId, int pickerId, String ghiChu) async {
    await ApiClient.dio.put(ApiEndpoints.ghiChuPickerDon(donId), data: {'picker_id': pickerId, 'ghi_chu': ghiChu});
  }

  Future<Map<String, dynamic>> themAnh(int donId, int pickerId, MultipartFile photo) async {
    final form = FormData.fromMap({'picker_id': pickerId, 'photo': photo});
    final res = await ApiClient.dio.post(ApiEndpoints.themAnhDon(donId), data: form);
    return res.data as Map<String, dynamic>;
  }

  Future<void> xoaAnh(int donId, int pickerId, String key) async {
    await ApiClient.dio.delete(
      ApiEndpoints.xoaAnhDon(donId),
      queryParameters: {'picker_id': pickerId, 'key': key},
    );
  }
}

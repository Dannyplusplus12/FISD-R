import 'package:dio/dio.dart';
import 'package:fisd_shared/fisd_shared.dart';
import '../../core/api/api_client.dart';

class DonHangPickerRepository {
  Future<List<Map<String, dynamic>>> layDonDaDuyet() async {
    final res = await ApiClient.dio.get(ApiEndpoints.donHangDaDuyet);
    return List<Map<String, dynamic>>.from((res.data['data'] as List? ?? []));
  }

  Future<List<Map<String, dynamic>>> layDonDaNhan(int pickerId) async {
    final res = await ApiClient.dio.get(ApiEndpoints.donHangDaNhan(pickerId));
    return List<Map<String, dynamic>>.from((res.data['data'] as List? ?? []));
  }

  Future<void> nhanDon(int donId, int pickerId) async {
    await ApiClient.dio.put(ApiEndpoints.nhanDon(donId), data: {'picker_id': pickerId});
  }

  Future<void> giaoHang({
    required int donId,
    required int pickerId,
    required List<MultipartFile> photos,
    required List<Map<String, dynamic>> items,
    String ghiChu = '',
  }) async {
    final formData = FormData.fromMap({
      'picker_id': pickerId,
      'items_json': items.isEmpty ? '[]' : _encodeItems(items),
      'picker_note': ghiChu,
      'photos': photos,
    });
    await ApiClient.dio.put(ApiEndpoints.giaoKemAnh(donId), data: formData);
  }

  String _encodeItems(List<Map<String, dynamic>> items) {
    return '[${items.map((i) => '{"order_item_id":${i["order_item_id"]},"variant_id":${i["variant_id"]},"picked_qty":${i["picked_qty"]}}').join(',')}]';
  }
}

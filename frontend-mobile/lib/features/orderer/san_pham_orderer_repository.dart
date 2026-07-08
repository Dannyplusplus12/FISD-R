import 'package:dio/dio.dart';
import 'package:fisd_shared/fisd_shared.dart';
import '../../core/api/api_client.dart';

class SanPhamOrdererRepository {
  Future<List<SanPham>> laySanPhams({String search = ''}) async {
    final res = await ApiClient.dio.get(ApiEndpoints.sanPhams,
        queryParameters: search.isNotEmpty ? {'search': search} : null);
    return (res.data as List)
        .map((j) => SanPham.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> taoSanPham({
    required String ten,
    required String ma,
    String imagePath = '',
    List<Map<String, dynamic>> bienThes = const [],
  }) async {
    await ApiClient.dio.post(ApiEndpoints.sanPhams, data: {
      'name': ten,
      'code': ma,
      'image_path': imagePath,
      'variants': bienThes,
    });
  }

  Future<void> capNhatSanPham({
    required int id,
    required String ten,
    required String ma,
    required String imagePath,
    required List<Map<String, dynamic>> bienThes,
  }) async {
    await ApiClient.dio.put(ApiEndpoints.sanPham(id), data: {
      'name': ten,
      'code': ma,
      'image_path': imagePath,
      'variants': bienThes,
    });
  }

  Future<void> xoaSanPham(int id) async {
    await ApiClient.dio.delete(ApiEndpoints.sanPham(id));
  }

  Future<String> uploadAnh(String filePath, String fileName) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final res = await ApiClient.dio.post(ApiEndpoints.uploadAnhSanPham, data: formData);
    return (res.data['path'] ?? '') as String;
  }
}

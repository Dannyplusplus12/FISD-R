import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import 'package:fisd_shared/api/endpoints.dart';
import 'package:fisd_shared/models/san_pham.dart';

class SanPhamRepository {
  final Dio _dio;

  const SanPhamRepository(this._dio);

  Future<List<SanPham>> layTatCa({String timKiem = ''}) async {
    final phanHoi = await _dio.get(
      ApiEndpoints.sanPhams,
      queryParameters: timKiem.isNotEmpty ? {'search': timKiem} : null,
    );
    return (phanHoi.data as List)
        .map((e) => SanPham.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> tao({
    required String ma,
    required String ten,
    String moTa = '',
    String duongDanAnh = '',
    required List<Map<String, dynamic>> bienThes,
  }) async {
    await _dio.post(ApiEndpoints.sanPhams, data: {
      'code': ma, 'name': ten, 'description': moTa,
      'image_path': duongDanAnh, 'variants': bienThes,
    });
  }

  Future<void> capNhat(int id, {
    required String ma,
    required String ten,
    String duongDanAnh = '',
    required List<Map<String, dynamic>> bienThes,
  }) async {
    await _dio.put(ApiEndpoints.sanPham(id), data: {
      'code': ma, 'name': ten, 'image_path': duongDanAnh, 'variants': bienThes,
    });
  }

  Future<void> xoa(int id) async {
    await _dio.delete(ApiEndpoints.sanPham(id));
  }

  Future<String> taiAnhLen(File anhFile) async {
    final formData = FormData.fromMap({'file': await MultipartFile.fromFile(anhFile.path)});
    final phanHoi = await _dio.post(ApiEndpoints.uploadAnhSanPham, data: formData);
    return (phanHoi.data['path'] ?? '').toString();
  }
}

final sanPhamRepositoryProvider = Provider<SanPhamRepository>((ref) {
  return SanPhamRepository(ref.watch(apiClientProvider));
});

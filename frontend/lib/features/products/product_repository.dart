import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../models/product.dart';

// ── Product Repository ────────────────────────────────────────────────────────
//
// All Product-related API calls live here.
// The provider (products_provider.dart) calls these methods;
// the UI never calls the repository directly.
//
// PATTERN: repository → provider → page
//   repository  = talks to the server (knows about Dio / HTTP)
//   provider    = holds and updates state (knows about Riverpod)
//   page        = shows data to the user (knows about Flutter widgets)

class ProductRepository {
  final Dio _dio;

  const ProductRepository(this._dio);

  Future<List<Product>> getAll({String search = ''}) async {
    final response = await _dio.get(
      ApiEndpoints.products,
      queryParameters: search.isNotEmpty ? {'search': search} : null,
    );
    return (response.data as List)
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> create({
    required String code,
    required String name,
    String description = '',
    String imagePath = '',
    required List<Map<String, dynamic>> variants,
  }) async {
    await _dio.post(ApiEndpoints.products, data: {
      'code': code,
      'name': name,
      'description': description,
      'image_path': imagePath,
      'variants': variants,
    });
  }

  Future<void> update(
    int id, {
    required String code,
    required String name,
    String imagePath = '',
    required List<Map<String, dynamic>> variants,
  }) async {
    await _dio.put(ApiEndpoints.product(id), data: {
      'code': code,
      'name': name,
      'image_path': imagePath,
      'variants': variants,
    });
  }

  Future<void> delete(int id) async {
    await _dio.delete(ApiEndpoints.product(id));
  }

  // Upload an image file and return the server-side path.
  Future<String> uploadImage(File imageFile) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(imageFile.path),
    });
    final response = await _dio.post(ApiEndpoints.productImageUpload, data: formData);
    return (response.data['path'] ?? '').toString();
  }
}

// Provider — use `ref.watch(productRepositoryProvider)` in other providers.
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(apiClientProvider));
});

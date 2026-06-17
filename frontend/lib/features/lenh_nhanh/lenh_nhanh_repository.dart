import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import 'lenh_nhanh_model.dart';

const _ollamaUrl = 'http://localhost:11434';
const _ollamaModel = 'qwen2.5:7b';

const _promptTemplate = '''Trích xuất thông tin đặt hàng từ lệnh sau. Chỉ trả về JSON thuần, không giải thích, không dùng markdown hay code block.

Lệnh: "{lenh}"

Format bắt buộc:
{{"khach": "tên khách giữ nguyên hoặc Khách lẻ", "items": [{{"sp": "tên sản phẩm", "mau": "màu hoặc null", "size": "kích cỡ hoặc null", "sl": số_lượng}}]}}''';

class LenhNhanhRepository {
  final Dio _dio;
  final Dio _ollamaDio = Dio(BaseOptions(
    baseUrl: _ollamaUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 30),
  ));

  LenhNhanhRepository(this._dio);

  Future<IntentAI> goiOllama(String lenh) async {
    final prompt = _promptTemplate.replaceAll('{lenh}', lenh);
    try {
      final r = await _ollamaDio.post('/api/generate', data: {
        'model': _ollamaModel,
        'prompt': prompt,
        'stream': false,
      });
      final raw = (r.data['response'] ?? '').toString().trim();
      // Bỏ markdown code block nếu model thêm vào
      final jsonStr = raw
          .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
          .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
          .trim();
      return IntentAI.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Ollama chưa chạy. Hãy mở Ollama trước khi dùng tính năng này.');
      }
      rethrow;
    } catch (e) {
      throw Exception('AI trả về kết quả không hợp lệ: $e');
    }
  }

  Future<KetQuaLenhNhanh> phanTichTuCauTruc(IntentAI intent) async {
    final r = await _dio.post(
      ApiEndpoints.lenhNhanhTuCauTruc,
      data: intent.toJson(),
    );
    return KetQuaLenhNhanh.fromJson(r.data as Map<String, dynamic>);
  }

  Future<KetQuaLenhNhanh> phanTichThuan(String lenh) async {
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

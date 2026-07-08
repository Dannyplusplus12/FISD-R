import 'package:fisd_shared/fisd_shared.dart';
import '../../core/api/api_client.dart';

class XacThucRepository {
  Future<Map<String, dynamic>> dangKyHoacDangNhap({
    required String ten,
    required String soDienThoai,
    required String pin,
  }) async {
    final res = await ApiClient.dio.post(
      ApiEndpoints.dangKyHoacDangNhap,
      data: {'ten': ten, 'so_dien_thoai': soDienThoai, 'pin': pin},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> dangNhapPin(String pin) async {
    final res = await ApiClient.dio.post(
      ApiEndpoints.dangNhapPin,
      data: {'pin': pin},
    );
    return res.data as Map<String, dynamic>;
  }
}

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../models/don_hang.dart';

class DonHangRepository {
  final Dio _dio;

  const DonHangRepository(this._dio);

  Future<List<DonHang>> layChoXuLy() async {
    final r = await _dio.get(ApiEndpoints.donHangChoDuyet);
    return _phanTichDanhSach(r.data);
  }

  Future<List<DonHang>> layDaDuyet() async {
    final r = await _dio.get(ApiEndpoints.donHangDaDuyet);
    return _phanTichDanhSach(r.data);
  }

  Future<List<DonHang>> layQuanLy({int gioiHan = 200}) async {
    final r = await _dio.get(ApiEndpoints.donHangQuanLy, queryParameters: {'limit': gioiHan});
    return _phanTichDanhSach(r.data);
  }

  Future<void> thanhToanNhap({
    required String tenKhachHang,
    String soDienThoai = '',
    required List<MatHangGio> gio,
    int? nhanVienId,
  }) async {
    await _dio.post(ApiEndpoints.thanhToanNhap, data: {
      'customer_name': tenKhachHang,
      'customer_phone': soDienThoai,
      if (nhanVienId != null) 'employee_id': nhanVienId,
      'cart': gio.map((e) => e.toJson()).toList(),
    });
  }

  Future<Map<String, dynamic>> duyet(int donId) async {
    final r = await _dio.put(ApiEndpoints.duyetDon(donId));
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> tuChoi(int donId) async {
    final r = await _dio.delete(ApiEndpoints.tuChoiDon(donId));
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> huy(int donId) async {
    final r = await _dio.delete(ApiEndpoints.huyDon(donId));
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> nhanDon(int donId, {required int pickerId}) async {
    final r = await _dio.put(ApiEndpoints.nhanDon(donId), data: {'picker_id': pickerId});
    return r.data as Map<String, dynamic>;
  }

  Future<void> suaDon({
    required int donId,
    required String tenKhachHang,
    String soDienThoai = '',
    required List<MatHangGio> gio,
  }) async {
    await _dio.put(ApiEndpoints.suaDon(donId), data: {
      'customer_name': tenKhachHang,
      'customer_phone': soDienThoai,
      'cart': gio.map((e) => e.toJson()).toList(),
    });
  }

  Future<void> xoa(int donId) async {
    await _dio.delete(ApiEndpoints.donHang(donId));
  }

  static List<DonHang> _phanTichDanhSach(dynamic duLieu) {
    final ds = duLieu is Map ? (duLieu['data'] as List? ?? []) : (duLieu as List? ?? []);
    return ds.map((e) => DonHang.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final donHangRepositoryProvider = Provider<DonHangRepository>((ref) {
  return DonHangRepository(ref.watch(apiClientProvider));
});

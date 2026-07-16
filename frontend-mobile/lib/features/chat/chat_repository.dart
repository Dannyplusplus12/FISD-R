import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fisd_shared/fisd_shared.dart';
import '../../core/api/api_client.dart';

class ChatRepository {
  Future<List<KenhChat>> layDanhSachKenh(int nhanVienId) async {
    final res = await ApiClient.dio
        .get(ApiEndpoints.kenhChats, queryParameters: {'nhan_vien_id': nhanVienId});
    return (res.data as List)
        .map((e) => KenhChat.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<KenhChat> taoKenh({
    required String ten,
    required List<int> thanhVienIds,
    required int chuKenhId,
  }) async {
    final res = await ApiClient.dio.post(ApiEndpoints.kenhChats, data: {
      'ten': ten,
      'thanh_vien_ids': thanhVienIds,
      'chu_kenh_id': chuKenhId,
    });
    return KenhChat.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> themThanhVien(int kenhId, {required int nhanVienId, required int nguoiThemId}) async {
    await ApiClient.dio.post(ApiEndpoints.thanhVienKenh(kenhId), data: {
      'nhan_vien_id': nhanVienId,
      'nguoi_them_id': nguoiThemId,
    });
  }

  Future<void> xoaThanhVien(int kenhId, int nvId, int nguoiXoaId) async {
    await ApiClient.dio.delete(
      ApiEndpoints.xoaThanhVienKenh(kenhId, nvId),
      queryParameters: {'nguoi_xoa_id': nguoiXoaId},
    );
  }

  Future<List<TinNhan>> layTinNhan(int kenhId, {int? beforeId, int limit = 50}) async {
    final res = await ApiClient.dio.get(ApiEndpoints.tinNhanKenh(kenhId), queryParameters: {
      if (beforeId != null) 'before_id': beforeId,
      'limit': limit,
    });
    final data = (res.data['data'] as List).cast<Map<String, dynamic>>();
    return data.map(TinNhan.fromJson).toList();
  }

  Future<TinNhan> guiTinNhan(
    int kenhId, {
    required int nguoiGuiId,
    String noiDung = '',
    List<MultipartFile> files = const [],
  }) async {
    final form = FormData.fromMap({
      'nguoi_gui_id': nguoiGuiId,
      'noi_dung': noiDung,
      if (files.isNotEmpty) 'files': files,
    });
    final res = await ApiClient.dio.post(ApiEndpoints.tinNhanKenh(kenhId), data: form);
    return TinNhan.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<NhanVien>> layDanhSachNhanVien() async {
    final res = await ApiClient.dio.get(ApiEndpoints.nhanViens);
    return (res.data as List).map((e) => NhanVien.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) => ChatRepository());

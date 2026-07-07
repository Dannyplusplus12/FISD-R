import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import 'package:fisd_shared/api/endpoints.dart';
import 'package:fisd_shared/models/bao_cao.dart';

class BaoCaoRepository {
  final Dio _dio;

  const BaoCaoRepository(this._dio);

  Future<BaoCao> layBaoCao({
    String? tuNgay,
    String? denNgay,
    int? khuVucId,
  }) async {
    final params = <String, dynamic>{};
    if (tuNgay != null) params['tu_ngay'] = tuNgay;
    if (denNgay != null) params['den_ngay'] = denNgay;
    if (khuVucId != null) params['khu_vuc_id'] = khuVucId;
    final r = await _dio.get(ApiEndpoints.baoCao, queryParameters: params);
    return BaoCao.fromJson(r.data as Map<String, dynamic>);
  }

  Future<DonHangNgay> layDonHangNgay(String ngay, {int? khuVucId}) async {
    final params = <String, dynamic>{'ngay': ngay};
    if (khuVucId != null) params['khu_vuc_id'] = khuVucId;
    final r = await _dio.get(ApiEndpoints.baoCaoDonHangNgay, queryParameters: params);
    return DonHangNgay.fromJson(r.data as Map<String, dynamic>);
  }
}

final baoCaoRepositoryProvider = Provider<BaoCaoRepository>((ref) {
  return BaoCaoRepository(ref.watch(apiClientProvider));
});

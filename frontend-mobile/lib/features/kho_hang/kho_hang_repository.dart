import 'package:fisd_shared/fisd_shared.dart';
import '../../core/api/api_client.dart';

class KhoHangRepository {
  Future<List<SanPham>> laySanPhams({String search = ''}) async {
    final res = await ApiClient.dio.get(ApiEndpoints.sanPhams,
        queryParameters: search.isNotEmpty ? {'search': search} : null);
    return (res.data as List).map((j) => SanPham.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<List<KhoHang>> layKhos() async {
    final res = await ApiClient.dio.get(ApiEndpoints.khoHangs);
    return (res.data as List).map((j) => KhoHang.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<List<Map<String, dynamic>>> laySanPhamTrongKho(int khoId) async {
    final res = await ApiClient.dio.get(ApiEndpoints.sanPhamTrongKho(khoId));
    return List<Map<String, dynamic>>.from(res.data as List);
  }

  Future<KhoHang> taoKho(String ten, String viTri, String ghiChu) async {
    final res = await ApiClient.dio.post(ApiEndpoints.khoHangs,
        data: {'ten': ten, 'vi_tri': viTri, 'ghi_chu': ghiChu});
    return KhoHang.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> capNhatKho(int id, String ten, String viTri, String ghiChu) async {
    await ApiClient.dio.put(ApiEndpoints.khoHang(id),
        data: {'ten': ten, 'vi_tri': viTri, 'ghi_chu': ghiChu});
  }

  Future<void> xoaKho(int id) async {
    await ApiClient.dio.delete(ApiEndpoints.khoHang(id));
  }

  // Biến thể ↔ kho (warehouse-centric)
  Future<void> themBienTheVaoKho(int khoId, int btId, int soLuong) async {
    await ApiClient.dio.post(ApiEndpoints.bienTheVaoKho(khoId, btId), data: {'bt_id': btId, 'so_luong': soLuong});
  }

  Future<void> capNhatSoLuongBienTheKho(int khoId, int btId, int soLuong) async {
    await ApiClient.dio.put(ApiEndpoints.soLuongBienTheKho(khoId, btId), data: {'so_luong': soLuong});
  }

  Future<void> xoaBienTheKhoiKho(int khoId, int btId) async {
    await ApiClient.dio.delete(ApiEndpoints.bienTheVaoKho(khoId, btId));
  }

  // Biến thể CRUD
  Future<Map<String, dynamic>> themBienTheSanPham(
      int productId, String color, String size, int price) async {
    final res = await ApiClient.dio.post(ApiEndpoints.bienThes,
        data: {'product_id': productId, 'color': color, 'size': size, 'price': price, 'stock': 0});
    return res.data as Map<String, dynamic>;
  }

  Future<void> capNhatBienThe(int id, String color, String size, int price) async {
    await ApiClient.dio.put(ApiEndpoints.bienThe(id),
        data: {'color': color, 'size': size, 'price': price});
  }

  Future<void> xoaBienThe(int id) async {
    await ApiClient.dio.delete(ApiEndpoints.bienThe(id));
  }
}

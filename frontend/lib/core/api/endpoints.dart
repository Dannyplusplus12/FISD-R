class ApiEndpoints {
  ApiEndpoints._();

  // Sản phẩm
  static const String sanPhams = '/san-pham';
  static String sanPham(int id) => '/san-pham/$id';
  static const String uploadAnhSanPham = '/anh-san-pham/upload';
  static String anhSanPham(String tenFile) => '/anh-san-pham/$tenFile';

  // Khu vực
  static const String khuVucs = '/khu-vuc';
  static String khuVuc(int id) => '/khu-vuc/$id';

  // Khách hàng
  static const String khachHangs = '/khach-hang';
  static String khachHang(int id) => '/khach-hang/$id';
  static String lichSuNo(int id) => '/khach-hang/$id/lich-su-no';
  static String lichSuNoItem(int khId, int logId) => '/khach-hang/$khId/lich-su-no/$logId';

  // Nhân viên
  static const String nhanViens = '/nhan-vien';
  static String nhanVien(int id) => '/nhan-vien/$id';
  static String giaoDongNhanVien(int id) => '/nhan-vien/$id/giao-hang';
  static String hoatDongNhanVien(int id) => '/nhan-vien/$id/hoat-dong';

  // Xác thực
  static const String dangNhapPin = '/xac-thuc/dang-nhap-pin';

  // Đơn hàng
  static const String donHangs = '/don-hang';
  static String donHang(int id) => '/don-hang/$id';
  static String ngayDonHang(int id) => '/don-hang/$id/ngay';
  static String trangThaiDonHang(int id) => '/don-hang/$id/trang-thai';

  static const String donHangChoDuyet = '/don-hang/cho-duyet';
  static const String donHangDaDuyet = '/don-hang/da-duyet';
  static const String donHangQuanLy = '/don-hang/quan-ly';
  static String donHangDaNhan(int pickerId) => '/don-hang/da-nhan?picker_id=$pickerId';

  static String suaDon(int id) => '/don-hang/$id/sua';
  static String duyetDon(int id) => '/don-hang/$id/duyet';
  static String tuChoiDon(int id) => '/don-hang/$id/tu-choi';
  static String huyDon(int id) => '/don-hang/$id/huy';
  static String nhanDon(int id) => '/don-hang/$id/nhan';
  static String giaoKemAnh(int id) => '/don-hang/$id/giao-kem-anh';
  static String xacNhanDon(int id) => '/don-hang/$id/xac-nhan';

  static const String thanhToan = '/thanh-toan';
  static const String thanhToanNhap = '/thanh-toan/nhap';
  static const String thanhToanDesktop = '/thanh-toan/desktop';

  // Ảnh bằng chứng giao hàng
  static String bangChungGiao(String tenFile) => '/bang-chung-giao/$tenFile';

  // Dashboard
  static const String thongKe = '/thong-ke';

  // Lệnh nhanh
  static const String lenhNhanh = '/lenh-nhanh';
  static const String lenhNhanhTuCauTruc = '/lenh-nhanh/tu-cau-truc';

  // Báo cáo / phân tích
  static const String baoCao = '/bao-cao';
  static const String baoCaoDonHangNgay = '/bao-cao/don-hang-ngay';
}

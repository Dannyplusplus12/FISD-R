import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../models/muc_dieu_huong.dart';
import '../features/tong_quan/tong_quan_page.dart';
import '../features/san_pham/san_pham_page.dart';
import '../features/don_hang/don_hang_page.dart';
import '../features/khach_hang/khach_hang_page.dart';
import '../features/nhan_vien/nhan_vien_page.dart';
import '../features/phan_tich/phan_tich_page.dart';
import '../features/xuat_hang/xuat_hang_page.dart';
import '../features/chat/danh_sach_kenh_page.dart';
import 'thanh_ben.dart';

const _mucMenu = <MucDieuHuong>[
  MucDieuHuong(nhan: 'Tổng Quan', bieu_tuong: Icons.dashboard_outlined, trang: TongQuanPage()),
  MucDieuHuong(nhan: 'Xuất Hàng', bieu_tuong: Icons.storefront_outlined, trang: XuatHangPage()),
  MucDieuHuong(nhan: 'Sản Phẩm', bieu_tuong: Icons.inventory_2_outlined, trang: SanPhamPage()),
  MucDieuHuong(nhan: 'Đơn Hàng', bieu_tuong: Icons.shopping_cart_outlined, trang: DonHangPage()),
  MucDieuHuong(nhan: 'Khách Hàng', bieu_tuong: Icons.people_outline, trang: KhachHangPage()),
  MucDieuHuong(nhan: 'Nhân Viên', bieu_tuong: Icons.badge_outlined, trang: NhanVienPage()),
  MucDieuHuong(nhan: 'Phân tích', bieu_tuong: Icons.bar_chart_outlined, trang: PhanTichPage()),
  MucDieuHuong(nhan: 'Chat', bieu_tuong: Icons.chat_bubble_outline, trang: DanhSachKenhPage()),
];

class KhungApp extends ConsumerStatefulWidget {
  const KhungApp({super.key});

  @override
  ConsumerState<KhungApp> createState() => _KhungAppState();
}

class _KhungAppState extends ConsumerState<KhungApp> {
  bool _moThanhBen = true;
  int _chiSoChon = 0;

  void _diDen(int chiSo) {
    setState(() {
      _chiSoChon = chiSo;
      _moThanhBen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final chiSoAnToan = _chiSoChon.clamp(0, _mucMenu.length - 1);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOut,
                width: _moThanhBen ? 260.0 : 0.0,
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(),
                child: SizedBox(
                  width: 260,
                  child: ThanhBen(
                    mucMenu: _mucMenu,
                    chiSoChon: chiSoAnToan,
                    onChon: _diDen,
                    onDong: () => setState(() => _moThanhBen = false),
                  ),
                ),
              ),
              Expanded(child: _mucMenu[chiSoAnToan].trang),
            ],
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            bottom: 24,
            left: _moThanhBen ? -64.0 : 16.0,
            child: GestureDetector(
              onTap: () => setState(() => _moThanhBen = true),
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.navSelected,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  boxShadow: [BoxShadow(color: AppColors.sidebarShadow, blurRadius: 10, offset: Offset(0, 4))],
                ),
                child: const Icon(Icons.menu, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

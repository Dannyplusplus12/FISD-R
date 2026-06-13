import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/session/session.dart';
import '../models/muc_dieu_huong.dart';
import '../features/xac_thuc/dang_nhap_page.dart';
import '../features/tong_quan/tong_quan_page.dart';
import '../features/san_pham/san_pham_page.dart';
import '../features/don_hang/don_hang_page.dart';
import '../features/khach_hang/khach_hang_page.dart';
import '../features/nhan_vien/nhan_vien_page.dart';
import 'thanh_ben.dart';

class KhungApp extends ConsumerStatefulWidget {
  const KhungApp({super.key});

  @override
  ConsumerState<KhungApp> createState() => _KhungAppState();
}

class _KhungAppState extends ConsumerState<KhungApp> {
  bool _moThanhBen = true;
  int _chiSoChon = 0;

  List<MucDieuHuong> _xayDungMenu(Session phienLam) {
    return [
      const MucDieuHuong(nhan: 'Tổng Quan', bieu_tuong: Icons.dashboard_outlined, trang: TongQuanPage()),
      const MucDieuHuong(nhan: 'Sản Phẩm', bieu_tuong: Icons.inventory_2_outlined, trang: SanPhamPage()),
      const MucDieuHuong(nhan: 'Đơn Hàng', bieu_tuong: Icons.shopping_cart_outlined, trang: DonHangPage()),
      const MucDieuHuong(nhan: 'Khách Hàng', bieu_tuong: Icons.people_outline, trang: KhachHangPage()),
      if (phienLam.isManager)
        const MucDieuHuong(nhan: 'Nhân Viên', bieu_tuong: Icons.badge_outlined, trang: NhanVienPage()),
    ];
  }

  void _diDen(int chiSo) {
    setState(() {
      _chiSoChon = chiSo;
      _moThanhBen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final phienLam = ref.watch(sessionProvider);
    final mucMenu = _xayDungMenu(phienLam);
    final chiSoAnToan = _chiSoChon.clamp(0, mucMenu.length - 1);

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
                    mucMenu: mucMenu,
                    chiSoChon: chiSoAnToan,
                    onChon: _diDen,
                    onDong: () => setState(() => _moThanhBen = false),
                    onDangXuat: () => ref.read(sessionProvider.notifier).logout(),
                    tenNhanVien: phienLam.employeeName,
                  ),
                ),
              ),
              Expanded(child: mucMenu[chiSoAnToan].trang),
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
                width: 48, height: 48,
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

class CongXacThuc extends ConsumerWidget {
  const CongXacThuc({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phienLam = ref.watch(sessionProvider);
    return phienLam.isLoggedIn ? const KhungApp() : const DangNhapPage();
  }
}

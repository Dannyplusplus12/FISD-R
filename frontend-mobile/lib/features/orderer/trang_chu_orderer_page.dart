import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session/phien_lam_viec.dart';
import '../../core/theme.dart';
import '../chat/danh_sach_kenh_page.dart';
import 'don_hang_orderer_page.dart';
import 'kho_orderer_page.dart';
import 'khach_hang_orderer_page.dart';
import 'phan_tich_page.dart';

class TrangChuOrdererPage extends ConsumerStatefulWidget {
  final PhienLamViec phien;
  const TrangChuOrdererPage({super.key, required this.phien});

  @override
  ConsumerState<TrangChuOrdererPage> createState() => _TrangChuOrdererPageState();
}

class _TrangChuOrdererPageState extends ConsumerState<TrangChuOrdererPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final trang = [
      DonHangOrdererPage(phien: widget.phien),
      const KhoOrdererPage(),
      KhachHangOrdererPage(phien: widget.phien),
      PhanTichPage(phien: widget.phien),
      DanhSachKenhPage(phien: widget.phien),
    ];

    return Scaffold(
      body: IndexedStack(index: _tab, children: trang),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withOpacity(0.1),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: AppColors.primary),
            label: 'Đơn hàng',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2, color: AppColors.primary),
            label: 'Kho',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: AppColors.primary),
            label: 'Khách hàng',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: AppColors.primary),
            label: 'Phân tích',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble, color: AppColors.primary),
            label: 'Chat',
          ),
        ],
      ),
    );
  }
}

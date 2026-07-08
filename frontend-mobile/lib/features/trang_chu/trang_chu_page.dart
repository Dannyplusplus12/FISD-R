import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session/phien_lam_viec.dart';
import '../don_hang_picker/don_hang_picker_page.dart';
import '../kho_hang/kho_hang_page.dart';
import '../lich_su/lich_su_page.dart';
import '../xac_thuc/xac_thuc_provider.dart';

class TrangChuPage extends ConsumerStatefulWidget {
  const TrangChuPage({super.key});

  @override
  ConsumerState<TrangChuPage> createState() => _TrangChuPageState();
}

class _TrangChuPageState extends ConsumerState<TrangChuPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final phien = ref.watch(xacThucProvider).value;
    if (phien == null) return const SizedBox();

    final trang = [
      DonHangPickerPage(phien: phien),
      const KhoHangPage(),
      LichSuPage(phien: phien),
    ];

    return Scaffold(
      body: IndexedStack(index: _tab, children: trang),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Đơn hàng'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Kho hàng'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'Lịch sử'),
        ],
      ),
    );
  }
}

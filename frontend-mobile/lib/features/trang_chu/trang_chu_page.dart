import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session/phien_lam_viec.dart';
import '../don_hang_picker/don_hang_picker_page.dart';
import '../kho_hang/kho_hang_page.dart';
import '../lich_su/lich_su_page.dart';
import '../orderer/trang_chu_orderer_page.dart';
import '../xac_thuc/xac_thuc_provider.dart';

class TrangChuPage extends ConsumerWidget {
  const TrangChuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phien = ref.watch(xacThucProvider).value;
    if (phien == null) return const SizedBox();

    if (phien.laOrderer || phien.laManager) {
      return TrangChuOrdererPage(phien: phien);
    }
    return _PickerShell(phien: phien);
  }
}

class _PickerShell extends StatefulWidget {
  final PhienLamViec phien;
  const _PickerShell({required this.phien});

  @override
  State<_PickerShell> createState() => _PickerShellState();
}

class _PickerShellState extends State<_PickerShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final trang = [
      DonHangPickerPage(phien: widget.phien),
      const KhoHangPage(),
      LichSuPage(phien: widget.phien),
    ];

    return Scaffold(
      body: IndexedStack(index: _tab, children: trang),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF1A1A2E).withOpacity(0.1),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: Color(0xFF1A1A2E)),
            label: 'Đơn hàng',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2, color: Color(0xFF1A1A2E)),
            label: 'Kho hàng',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: Color(0xFF1A1A2E)),
            label: 'Lịch sử',
          ),
        ],
      ),
    );
  }
}

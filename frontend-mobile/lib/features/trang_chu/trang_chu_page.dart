import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session/phien_lam_viec.dart';
import '../../core/thong_bao/da_xem_provider.dart';
import '../../core/thong_bao/dem_chua_doc_provider.dart';
import '../../core/thong_bao/nut_thong_bao.dart';
import '../chat/danh_sach_kenh_page.dart';
import '../don_hang_picker/don_hang_picker_page.dart';
import '../don_hang_picker/don_hang_picker_provider.dart';
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

class _PickerShell extends ConsumerStatefulWidget {
  final PhienLamViec phien;
  const _PickerShell({required this.phien});

  @override
  ConsumerState<_PickerShell> createState() => _PickerShellState();
}

class _PickerShellState extends ConsumerState<_PickerShell> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(demChuaDocProvider.notifier).init(widget.phien.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final trang = [
      DonHangPickerPage(phien: widget.phien),
      const KhoHangPage(),
      LichSuPage(phien: widget.phien),
      DanhSachKenhPage(phien: widget.phien),
    ];

    final coDonChoNhan = ref.watch(donDaDuyetProvider).valueOrNull?.isNotEmpty ?? false;
    final coDonDangGiao =
        ref.watch(donDaNhanProvider(widget.phien.id)).valueOrNull?.isNotEmpty ?? false;
    final coTinNhanChuaDoc = ref.watch(demChuaDocProvider.select((m) => m.isNotEmpty));
    final daXem = ref.watch(daXemProvider);

    return Scaffold(
      body: IndexedStack(index: _tab, children: trang),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) {
          setState(() => _tab = i);
          if (i == 0) ref.read(daXemProvider.notifier).danhDauDaXem('nav_don_hang');
          if (i == 3) ref.read(daXemProvider.notifier).danhDauDaXem('nav_chat');
        },
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF1A1A2E).withOpacity(0.1),
        destinations: [
          NavigationDestination(
            icon: NutThongBao(
              coThongBao: coDonChoNhan || coDonDangGiao,
              daXem: daXem.contains('nav_don_hang'),
              child: const Icon(Icons.receipt_long_outlined),
            ),
            selectedIcon: NutThongBao(
              coThongBao: coDonChoNhan || coDonDangGiao,
              daXem: daXem.contains('nav_don_hang'),
              child: const Icon(Icons.receipt_long, color: Color(0xFF1A1A2E)),
            ),
            label: 'Đơn hàng',
          ),
          const NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2, color: Color(0xFF1A1A2E)),
            label: 'Kho hàng',
          ),
          const NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: Color(0xFF1A1A2E)),
            label: 'Lịch sử',
          ),
          NavigationDestination(
            icon: NutThongBao(
              coThongBao: coTinNhanChuaDoc,
              daXem: daXem.contains('nav_chat'),
              child: const Icon(Icons.chat_bubble_outline),
            ),
            selectedIcon: NutThongBao(
              coThongBao: coTinNhanChuaDoc,
              daXem: daXem.contains('nav_chat'),
              child: const Icon(Icons.chat_bubble, color: Color(0xFF1A1A2E)),
            ),
            label: 'Chat',
          ),
        ],
      ),
    );
  }
}

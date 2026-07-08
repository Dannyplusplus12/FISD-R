import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session/phien_lam_viec.dart';
import 'don_hang_picker_provider.dart';
import 'soan_kho_page.dart';

class DonHangPickerPage extends ConsumerStatefulWidget {
  final PhienLamViec phien;
  const DonHangPickerPage({super.key, required this.phien});

  @override
  ConsumerState<DonHangPickerPage> createState() => _DonHangPickerPageState();
}

class _DonHangPickerPageState extends ConsumerState<DonHangPickerPage> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn hàng'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [Tab(text: 'Chờ nhận'), Tab(text: 'Đang giao')],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _DonChoDuyet(phien: widget.phien),
          _DonDaNhan(phien: widget.phien),
        ],
      ),
    );
  }
}

// ── Tab: Đơn chờ nhận ────────────────────────────────────────────────────────

class _DonChoDuyet extends ConsumerWidget {
  final PhienLamViec phien;
  const _DonChoDuyet({required this.phien});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(donDaDuyetProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _loi(e, () => ref.invalidate(donDaDuyetProvider)),
      data: (list) {
        if (list.isEmpty) return _trong('Không có đơn chờ nhận');
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(donDaDuyetProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (_, i) => _DonCard(
              don: list[i],
              nutChinh: 'Nhận đơn',
              mauNut: Colors.blue,
              onTap: () => _nhanDon(context, ref, list[i]),
            ),
          ),
        );
      },
    );
  }

  Future<void> _nhanDon(BuildContext ctx, WidgetRef ref, Map don) async {
    final ok = await ref.read(donHangPickerActionProvider.notifier).nhanDon(don['id'], phien.id);
    if (!ctx.mounted) return;
    if (ok) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Đã nhận đơn #${don["id"]}')));
      ref.invalidate(donDaDuyetProvider);
      ref.invalidate(donDaNhanProvider(phien.id));
    } else {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Lỗi nhận đơn'), backgroundColor: Colors.red));
    }
  }
}

// ── Tab: Đơn đang giao ───────────────────────────────────────────────────────

class _DonDaNhan extends ConsumerWidget {
  final PhienLamViec phien;
  const _DonDaNhan({required this.phien});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(donDaNhanProvider(phien.id));
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _loi(e, () => ref.invalidate(donDaNhanProvider(phien.id))),
      data: (list) {
        if (list.isEmpty) return _trong('Chưa nhận đơn nào');
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(donDaNhanProvider(phien.id)),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (_, i) => _DonCard(
              don: list[i],
              nutChinh: 'Giao hàng',
              mauNut: Colors.green,
              onTap: () => _moGiaoHang(context, ref, list[i]),
            ),
          ),
        );
      },
    );
  }

  Future<void> _moGiaoHang(BuildContext ctx, WidgetRef ref, Map don) async {
    await Navigator.push(ctx, MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => SoanKhoPage(donId: don['id'] as int, phien: phien),
    ));
    ref.invalidate(donDaNhanProvider(phien.id));
    ref.invalidate(donDaDuyetProvider);
  }
}

// ── Card đơn hàng ─────────────────────────────────────────────────────────────

class _DonCard extends StatelessWidget {
  final Map don;
  final String nutChinh;
  final Color mauNut;
  final VoidCallback onTap;

  const _DonCard({required this.don, required this.nutChinh, required this.mauNut, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = (don['items'] as List? ?? []);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Đơn #${don["id"]}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(don['created_at'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            Text(don['customer_name'] ?? 'Khách lẻ', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 6, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(child: Text('${item["product_name"]} ${item["variant_info"] ?? ""}', style: const TextStyle(fontSize: 13))),
                  Text('x${item["quantity"]}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            )),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_formatTien(don["total_amount"])} đ', style: const TextStyle(fontWeight: FontWeight.bold)),
                ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(backgroundColor: mauNut, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: Text(nutChinh),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _trong(String msg) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
  const Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
  const SizedBox(height: 8),
  Text(msg, style: const TextStyle(color: Colors.grey)),
]));

Widget _loi(Object e, VoidCallback retry) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
  const Icon(Icons.error_outline, color: Colors.red),
  const SizedBox(height: 8),
  const Text('Lỗi tải dữ liệu'),
  TextButton(onPressed: retry, child: const Text('Thử lại')),
]));

String _formatTien(dynamic v) {
  final n = (v is int) ? v : int.tryParse(v.toString()) ?? 0;
  return n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

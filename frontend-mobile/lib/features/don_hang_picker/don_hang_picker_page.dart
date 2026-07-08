import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session/phien_lam_viec.dart';
import '../../core/theme.dart';
import 'don_hang_picker_provider.dart';
import 'soan_kho_page.dart';

class DonHangPickerPage extends ConsumerStatefulWidget {
  final PhienLamViec phien;
  const DonHangPickerPage({super.key, required this.phien});

  @override
  ConsumerState<DonHangPickerPage> createState() => _DonHangPickerPageState();
}

class _DonHangPickerPageState extends ConsumerState<DonHangPickerPage>
    with SingleTickerProviderStateMixin {
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Đơn hàng', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(children: [
            Container(height: 1, color: AppColors.divider),
            TabBar(
              controller: _tab,
              tabs: const [Tab(text: 'Chờ nhận'), Tab(text: 'Đang giao')],
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.label,
            ),
          ]),
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

class _DonChoDuyet extends ConsumerWidget {
  final PhienLamViec phien;
  const _DonChoDuyet({required this.phien});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(donDaDuyetProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => errorState(() => ref.invalidate(donDaDuyetProvider)),
      data: (list) {
        if (list.isEmpty) {
          return emptyState(Icons.inbox_outlined, 'Không có đơn chờ nhận');
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(donDaDuyetProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) => _DonCard(
              don: list[i],
              label: 'Nhận đơn',
              mauNhan: AppColors.info,
              onTap: () => _nhanDon(context, ref, list[i]),
            ),
          ),
        );
      },
    );
  }

  Future<void> _nhanDon(BuildContext ctx, WidgetRef ref, Map don) async {
    final ok =
        await ref.read(donHangPickerActionProvider.notifier).nhanDon(don['id'], phien.id);
    if (!ctx.mounted) return;
    if (ok) {
      ScaffoldMessenger.of(ctx)
          .showSnackBar(SnackBar(content: Text('Đã nhận đơn #${don["id"]}')));
      ref.invalidate(donDaDuyetProvider);
      ref.invalidate(donDaNhanProvider(phien.id));
    } else {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
          content: Text('Lỗi nhận đơn'), backgroundColor: AppColors.danger));
    }
  }
}

class _DonDaNhan extends ConsumerWidget {
  final PhienLamViec phien;
  const _DonDaNhan({required this.phien});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(donDaNhanProvider(phien.id));
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => errorState(() => ref.invalidate(donDaNhanProvider(phien.id))),
      data: (list) {
        if (list.isEmpty) {
          return emptyState(Icons.local_shipping_outlined, 'Chưa nhận đơn nào');
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(donDaNhanProvider(phien.id)),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) => _DonCard(
              don: list[i],
              label: 'Giao hàng',
              mauNhan: AppColors.success,
              onTap: () => _moGiaoHang(context, ref, list[i]),
            ),
          ),
        );
      },
    );
  }

  Future<void> _moGiaoHang(BuildContext ctx, WidgetRef ref, Map don) async {
    await Navigator.push(
        ctx,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => SoanKhoPage(donId: don['id'] as int, phien: phien),
        ));
    ref.invalidate(donDaNhanProvider(phien.id));
    ref.invalidate(donDaDuyetProvider);
  }
}

class _DonCard extends StatelessWidget {
  final Map don;
  final String label;
  final Color mauNhan;
  final VoidCallback onTap;

  const _DonCard({required this.don, required this.label, required this.mauNhan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = (don['items'] as List? ?? []);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppDeco.card(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Text('Đơn #${don["id"]}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: mauNhan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(label == 'Nhận đơn' ? 'Chờ nhận' : 'Đang giao',
                    style: TextStyle(
                        color: mauNhan, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ]),
            Text(don['created_at'] ?? '',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ]),
          const SizedBox(height: 4),
          Text(don['customer_name'] ?? 'Khách lẻ',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),
          ...items.take(3).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(children: [
                  const Icon(Icons.circle, size: 5, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(
                          '${item["product_name"]} ${item["variant_info"] ?? ""}',
                          style: const TextStyle(fontSize: 13))),
                  Text('×${item["quantity"]}',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                ]),
              )),
          if (items.length > 3)
            Text('+${items.length - 3} mặt hàng khác',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${fmtTien(don["total_amount"])} đ',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: mauNhan,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(label, style: const TextStyle(fontSize: 14)),
            ),
          ]),
        ]),
      ),
    );
  }
}

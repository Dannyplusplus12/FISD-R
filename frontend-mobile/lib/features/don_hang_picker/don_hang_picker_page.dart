import 'package:fisd_shared/fisd_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/session/phien_lam_viec.dart';
import '../../core/theme.dart';
import '../xac_thuc/xac_thuc_provider.dart';
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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Đăng xuất',
            onPressed: () => ref.read(xacThucProvider.notifier).dangXuat(),
          ),
        ],
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

// ── Tab Chờ nhận ──────────────────────────────────────────────────────────────

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
            itemBuilder: (_, i) => _DonChoDuyetCard(
              don: list[i],
              onNhan: () => _nhanDon(context, ref, list[i]),
            ),
          ),
        );
      },
    );
  }

  Future<void> _nhanDon(BuildContext ctx, WidgetRef ref, Map don) async {
    final ok = await ref
        .read(donHangPickerActionProvider.notifier)
        .nhanDon(don['id'], phien.id);
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

// ── Card expandable "Chờ nhận" ────────────────────────────────────────────────

class _DonChoDuyetCard extends StatefulWidget {
  final Map don;
  final VoidCallback onNhan;
  const _DonChoDuyetCard({required this.don, required this.onNhan});

  @override
  State<_DonChoDuyetCard> createState() => _DonChoDuyetCardState();
}

class _DonChoDuyetCardState extends State<_DonChoDuyetCard> {
  bool _expanded = false;
  bool _loading = false;
  bool _fetchError = false;
  List<Map<String, dynamic>>? _detailItems;

  Future<void> _loadDetail() async {
    if (!mounted) return;
    setState(() { _loading = true; _fetchError = false; });
    try {
      final res = await ApiClient.dio
          .get(ApiEndpoints.soanKho(widget.don['id'] as int));
      final items = (res.data['items'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      if (mounted) setState(() { _detailItems = items; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _fetchError = true; });
    }
  }

  Future<void> _toggleExpand() async {
    if (_expanded) {
      setState(() => _expanded = false);
      return;
    }
    setState(() => _expanded = true);
    if (_detailItems == null && !_fetchError) {
      await _loadDetail();
    }
  }

  @override
  Widget build(BuildContext context) {
    final don = widget.don;
    final items = (don['items'] as List? ?? []);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppDeco.card(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header — tap để expand
        InkWell(
          onTap: _toggleExpand,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('Đơn #${don["id"]}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Chờ nhận',
                      style: TextStyle(
                          color: AppColors.info,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
                const Spacer(),
                Text(don['created_at'] ?? '',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.expand_more,
                      color: AppColors.textSecondary, size: 20),
                ),
              ]),
              const SizedBox(height: 4),
              Text(don['customer_name'] ?? 'Khách lẻ',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 10),
            ]),
          ),
        ),

        // Preview items (luôn hiện, collapsed)
        if (!_expanded) ...[
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Column(children: [
              ...items.take(3).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      const Icon(Icons.circle,
                          size: 5, color: AppColors.textSecondary),
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('+${items.length - 3} mặt hàng khác',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ),
            ]),
          ),
        ],

        // Detail expanded — warehouse info
        if (_expanded) ...[
          const Divider(height: 1, color: AppColors.divider),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_fetchError)
            InkWell(
              onTap: _loadDetail,
              child: const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(children: [
                  Icon(Icons.error_outline, color: AppColors.danger, size: 16),
                  SizedBox(width: 8),
                  Text('Không tải được kho — Nhấn để thử lại',
                      style: TextStyle(color: AppColors.danger, fontSize: 13)),
                ]),
              ),
            )
          else if (_detailItems != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Column(
                children: _detailItems!
                    .map((item) => _ItemKhoRow(item: item))
                    .toList(),
              ),
            ),
        ],

        // Footer
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(fmtTien(don['total_amount']),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                FilledButton(
                  onPressed: widget.onNhan,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.info,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Nhận đơn',
                      style: TextStyle(fontSize: 14)),
                ),
              ]),
        ),
      ]),
    );
  }
}

// ── Row từng mặt hàng + kho ───────────────────────────────────────────────────

class _ItemKhoRow extends StatelessWidget {
  final Map<String, dynamic> item;
  const _ItemKhoRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final khos = (item['warehouses'] as List? ?? []).cast<Map<String, dynamic>>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              '${item["product_name"]} ${item["variant_info"] ?? ""}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            if (khos.isEmpty)
              const Text('Không có trong kho nào',
                  style: TextStyle(color: AppColors.danger, fontSize: 12))
            else
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: khos.map((k) {
                  final soLuong = (k['so_luong'] as num?)?.toInt() ?? 0;
                  final isEmpty = soLuong == 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isEmpty
                          ? AppColors.textSecondary.withOpacity(0.08)
                          : AppColors.info.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: isEmpty
                              ? AppColors.textSecondary.withOpacity(0.25)
                              : AppColors.info.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${k["ten"]}  ×$soLuong',
                      style: TextStyle(
                          color: isEmpty
                              ? AppColors.textSecondary
                              : AppColors.info,
                          fontSize: 11),
                    ),
                  );
                }).toList(),
              ),
          ]),
        ),
        const SizedBox(width: 12),
        Text('×${item["quantity"] ?? item["max_qty"] ?? ""}',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13)),
      ]),
    );
  }
}

// ── Tab Đang giao ─────────────────────────────────────────────────────────────

class _DonDaNhan extends ConsumerWidget {
  final PhienLamViec phien;
  const _DonDaNhan({required this.phien});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(donDaNhanProvider(phien.id));
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          errorState(() => ref.invalidate(donDaNhanProvider(phien.id))),
      data: (list) {
        if (list.isEmpty) {
          return emptyState(
              Icons.local_shipping_outlined, 'Chưa nhận đơn nào');
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(donDaNhanProvider(phien.id)),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) => _DonDangGiaoCard(
              don: list[i],
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
          builder: (_) =>
              SoanKhoPage(donId: don['id'] as int, phien: phien),
        ));
    ref.invalidate(donDaNhanProvider(phien.id));
    ref.invalidate(donDaDuyetProvider);
  }
}

// ── Card đơn đang giao — toàn bộ card ấn được ────────────────────────────────

class _DonDangGiaoCard extends StatelessWidget {
  final Map don;
  final VoidCallback onTap;

  const _DonDangGiaoCard({required this.don, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = (don['items'] as List? ?? []);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppDeco.card(),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  Text('Đơn #${don["id"]}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Đang giao',
                        style: TextStyle(
                            color: AppColors.warning,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
                Text(don['created_at'] ?? '',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ]),
              const SizedBox(height: 4),
              Text(don['customer_name'] ?? 'Khách lẻ',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 10),
              ...items.take(3).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      const Icon(Icons.circle,
                          size: 5, color: AppColors.textSecondary),
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
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(fmtTien(don['total_amount']),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                Row(children: [
                  const Text('Xem chi tiết',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right,
                      color: AppColors.textSecondary, size: 18),
                ]),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session/phien_lam_viec.dart';
import '../../core/theme.dart';
import 'don_hang_orderer_provider.dart';
import 'tao_don_page.dart';

class DonHangOrdererPage extends ConsumerWidget {
  final PhienLamViec phien;
  const DonHangOrdererPage({super.key, required this.phien});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(donHangOrdererProvider(phien.id));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Đơn hàng', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => ref.invalidate(donHangOrdererProvider(phien.id)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _taoDon(context, ref),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tạo đơn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => errorState(() => ref.invalidate(donHangOrdererProvider(phien.id))),
        data: (list) {
          if (list.isEmpty) {
            return emptyState(Icons.receipt_long_outlined, 'Chưa có đơn nào',
                sub: 'Nhấn + để tạo đơn mới');
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(donHangOrdererProvider(phien.id)),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: list.length,
              itemBuilder: (_, i) => _DonOrdererCard(don: list[i]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _taoDon(BuildContext ctx, WidgetRef ref) async {
    final ok = await Navigator.push<bool>(
        ctx, MaterialPageRoute(builder: (_) => TaoDonPage(phien: phien)));
    if (ok == true) {
      ref.invalidate(donHangOrdererProvider(phien.id));
    }
  }
}

class _DonOrdererCard extends StatelessWidget {
  final Map don;
  const _DonOrdererCard({required this.don});

  @override
  Widget build(BuildContext context) {
    final status = don['status'] as String? ?? '';
    final items = (don['items'] as List? ?? []);
    final (label, mau) = _statusInfo(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppDeco.card(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('Đơn #${don["id"]}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(width: 8),
                  _Badge(label: label, color: mau),
                ]),
                const SizedBox(height: 2),
                Text(don['customer_name'] ?? 'Khách lẻ',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              ]),
            ),
            Text(don['created_at'] ?? '',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ]),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 8),
          ...items.take(2).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(children: [
                  const Icon(Icons.circle, size: 5, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(
                          '${item["product_name"]} ${item["variant_info"] ?? ""}',
                          style: const TextStyle(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis)),
                  Text('×${item["quantity"]}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ]),
              )),
          if (items.length > 2)
            Text('+${items.length - 2} mặt hàng khác',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${fmtTien(don["total_amount"])} đ',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            if (status == 'assigned' && (don['assigned_picker_name'] ?? '').isNotEmpty)
              Text('Picker: ${don["assigned_picker_name"]}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ]),
          if (status == 'completed' && (don['delivered_at'] ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Giao lúc ${don["delivered_at"]}',
                  style: const TextStyle(color: AppColors.success, fontSize: 12)),
            ),
        ]),
      ),
    );
  }

  (String, Color) _statusInfo(String status) => switch (status) {
        'approved' => ('Chờ picker', AppColors.info),
        'assigned' => ('Đang giao', AppColors.warning),
        'completed' => ('Hoàn thành', AppColors.success),
        _ => ('Chờ duyệt', AppColors.textSecondary),
      };
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

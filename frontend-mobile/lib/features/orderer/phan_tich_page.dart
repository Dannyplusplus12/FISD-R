import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/session/phien_lam_viec.dart';
import '../../core/theme.dart';
import '../xac_thuc/xac_thuc_provider.dart';
import 'package:fisd_shared/fisd_shared.dart';

final _thongKeProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await ApiClient.dio.get(ApiEndpoints.thongKe);
  return res.data as Map<String, dynamic>;
});

class PhanTichPage extends ConsumerWidget {
  final PhienLamViec phien;
  const PhanTichPage({super.key, required this.phien});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_thongKeProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Phân tích', style: TextStyle(fontWeight: FontWeight.bold)),
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
            onPressed: () => ref.invalidate(_thongKeProvider),
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Đăng xuất',
            onPressed: () => ref.read(xacThucProvider.notifier).dangXuat(),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => errorState(() => ref.invalidate(_thongKeProvider)),
        data: (data) => _buildBody(data),
      ),
    );
  }

  Widget _buildBody(Map<String, dynamic> data) {
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(padding: const EdgeInsets.all(16), children: [
        // Tổng quan
        const _SectionHeader('Tổng quan'),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              child: _MetricCard(
            icon: Icons.receipt_long_outlined,
            label: 'Tổng đơn',
            value: '${data["total_orders"] ?? data["total_completed"] ?? "—"}',
            color: AppColors.info,
          )),
          const SizedBox(width: 10),
          Expanded(
              child: _MetricCard(
            icon: Icons.attach_money_outlined,
            label: 'Doanh thu',
            value: data["total_revenue"] != null ? fmtTien(data["total_revenue"]) : '—',
            color: AppColors.success,
          )),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: _MetricCard(
            icon: Icons.people_outline,
            label: 'Khách hàng',
            value: '${data["total_customers"] ?? "—"}',
            color: AppColors.warning,
          )),
          const SizedBox(width: 10),
          Expanded(
              child: _MetricCard(
            icon: Icons.inventory_2_outlined,
            label: 'Sản phẩm',
            value: '${data["total_products"] ?? "—"}',
            color: AppColors.primary,
          )),
        ]),

        // Top sản phẩm
        if ((data["top_products"] as List? ?? []).isNotEmpty) ...[
          const SizedBox(height: 20),
          const _SectionHeader('Sản phẩm bán chạy'),
          const SizedBox(height: 8),
          Container(
            decoration: AppDeco.card(),
            child: Column(
              children: (data["top_products"] as List).asMap().entries.map((e) {
                final item = e.value as Map;
                return ListTile(
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text('${e.key + 1}',
                        style: const TextStyle(
                            color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  title: Text(item['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                  trailing: Text('×${item["qty"] ?? item["count"] ?? 0}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                );
              }).toList(),
            ),
          ),
        ],

        // Placeholder chart
        const SizedBox(height: 20),
        const _SectionHeader('Doanh thu theo thời gian'),
        const SizedBox(height: 8),
        Container(
          height: 160,
          decoration: AppDeco.card(),
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.bar_chart_outlined, size: 48,
                  color: AppColors.textSecondary.withOpacity(0.4)),
              const SizedBox(height: 8),
              const Text('Biểu đồ doanh thu sẽ có ở đây',
                  style: TextStyle(color: AppColors.textSecondary)),
              const Text('(Đang phát triển)',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ]),
          ),
        ),

        const SizedBox(height: 40),
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Text(title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15));
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDeco.card(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 12),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ]),
    );
  }
}

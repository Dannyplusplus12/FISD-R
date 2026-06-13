import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/session/session.dart';
import '../../models/order.dart';
import 'orders_provider.dart';

// ── Orders Page ───────────────────────────────────────────────────────────────
//
// Shows order lists.  The content differs by role:
//   manager  → sees all management orders + can approve/reject pending ones
//   orderer  → sees their own pending orders
//   picker   → sees assigned orders (handled in a separate page)

class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);

    return SafeArea(
      child: Column(
        children: [
          // ── Title bar ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                const Text(
                  'Đơn Hàng',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
                  onPressed: () {
                    ref.read(managementOrdersProvider.notifier).refresh();
                    ref.read(pendingOrdersProvider.notifier).refresh();
                  },
                ),
              ],
            ),
          ),

          // ── Tab bar ───────────────────────────────────────────
          TabBar(
            controller: _tabs,
            labelColor: AppColors.navSelected,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.navSelected,
            tabs: const [
              Tab(text: 'Lịch sử'),
              Tab(text: 'Chờ duyệt'),
            ],
          ),

          // ── Tab content ───────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _OrdersHistoryTab(isManager: session.isManager),
                _PendingOrdersTab(isManager: session.isManager),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── History Tab ───────────────────────────────────────────────────────────────
class _OrdersHistoryTab extends ConsumerWidget {
  final bool isManager;

  const _OrdersHistoryTab({required this.isManager});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(managementOrdersProvider);

    return ordersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(
        message: e.toString(),
        onRetry: () => ref.read(managementOrdersProvider.notifier).refresh(),
      ),
      data: (orders) => orders.isEmpty
          ? const Center(child: Text('Chưa có đơn hàng nào', style: TextStyle(color: AppColors.textSecondary)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _OrderCard(
                order: orders[i],
                onCancel: isManager ? () => ref.read(managementOrdersProvider.notifier).cancel(orders[i].id) : null,
              ),
            ),
    );
  }
}

// ── Pending Tab ───────────────────────────────────────────────────────────────
class _PendingOrdersTab extends ConsumerWidget {
  final bool isManager;

  const _PendingOrdersTab({required this.isManager});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(pendingOrdersProvider);

    return ordersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(
        message: e.toString(),
        onRetry: () => ref.read(pendingOrdersProvider.notifier).refresh(),
      ),
      data: (orders) => orders.isEmpty
          ? const Center(child: Text('Không có đơn chờ duyệt', style: TextStyle(color: AppColors.textSecondary)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _OrderCard(
                order: orders[i],
                onApprove: isManager ? () => ref.read(pendingOrdersProvider.notifier).approve(orders[i].id) : null,
                onReject: isManager ? () => ref.read(pendingOrdersProvider.notifier).reject(orders[i].id) : null,
              ),
            ),
    );
  }
}

// ── Order Card ────────────────────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onCancel;

  const _OrderCard({required this.order, this.onApprove, this.onReject, this.onCancel});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'vi_VN');
    final statusColor = _statusColor(order.status);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '#${order.id} — ${order.customerName}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  order.statusLabel,
                  style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${fmt.format(order.totalAmount)} ₫  •  ${order.totalQty} sản phẩm',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          Text(
            order.createdAt,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          if (onApprove != null || onReject != null || onCancel != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (onApprove != null)
                  _ActionButton(label: 'Duyệt', color: AppColors.activeGreen, onTap: onApprove!),
                if (onReject != null) ...[
                  const SizedBox(width: 8),
                  _ActionButton(label: 'Từ chối', color: Colors.red, onTap: onReject!),
                ],
                if (onCancel != null) ...[
                  const SizedBox(width: 8),
                  _ActionButton(label: 'Hủy', color: Colors.orange, onTap: onCancel!),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'approved': return Colors.blue;
      case 'assigned': return Colors.purple;
      case 'completed': return AppColors.activeGreen;
      default: return AppColors.textSecondary;
    }
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}

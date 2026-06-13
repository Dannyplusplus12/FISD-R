import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/session/session.dart';
import '../../models/order.dart';
import '../products/products_provider.dart';
import '../customers/customers_provider.dart';
import '../orders/orders_provider.dart';

// ── Dashboard Page ────────────────────────────────────────────────────────────
//
// Shows a summary of key stats fetched live from the backend.
// Each stat card watches a different provider — they load in parallel.
//
// This replaces tong_quan_page.dart which had hardcoded dummy data.

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    // Watch all three data sources — they fetch in parallel.
    final productsAsync = ref.watch(productsProvider);
    final customersAsync = ref.watch(customersProvider);
    final ordersAsync = ref.watch(managementOrdersProvider);
    final pendingAsync = ref.watch(pendingOrdersProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Greeting ─────────────────────────────────────────
            Text(
              session.isLoggedIn ? 'Xin chào, ${session.employeeName}' : 'Tổng Quan',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Dữ liệu thời gian thực từ máy chủ',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            // ── Stats grid — 2 columns ────────────────────────────
            Expanded(
              flex: 50,
              child: Column(
                children: [
                  Expanded(
                    child: Row(children: [
                      // Total products
                      Expanded(
                        child: _AsyncStatCard(
                          title: 'Sản Phẩm',
                          icon: Icons.inventory_2_outlined,
                          asyncValue: productsAsync,
                          valueBuilder: (products) => '${products.length}',
                          subBuilder: (products) {
                            final total = products.fold<int>(0, (s, p) => s + p.totalStock);
                            return 'Tổng tồn: $total';
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Total customers
                      Expanded(
                        child: _AsyncStatCard(
                          title: 'Khách Hàng',
                          icon: Icons.people_outline,
                          asyncValue: customersAsync,
                          valueBuilder: (customers) => '${customers.length}',
                          subBuilder: (customers) {
                            final debt = customers.fold<int>(0, (s, c) => s + c.debt);
                            final fmt = NumberFormat('#,###', 'vi_VN');
                            return 'Nợ: ${fmt.format(debt)} ₫';
                          },
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Row(children: [
                      // Total completed orders
                      Expanded(
                        child: _AsyncStatCard(
                          title: 'Đơn Hoàn Thành',
                          icon: Icons.check_circle_outline,
                          asyncValue: ordersAsync,
                          valueBuilder: (orders) =>
                              '${orders.where((o) => o.isCompleted).length}',
                          subBuilder: (orders) {
                            final completed = orders.where((o) => o.isCompleted).toList();
                            final revenue = completed.fold<int>(0, (s, o) => s + o.totalAmount);
                            final fmt = NumberFormat('#,###', 'vi_VN');
                            return '${fmt.format(revenue)} ₫';
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Pending orders badge
                      Expanded(
                        child: _AsyncStatCard(
                          title: 'Chờ Duyệt',
                          icon: Icons.pending_outlined,
                          asyncValue: pendingAsync,
                          valueBuilder: (pending) => '${pending.length}',
                          subBuilder: (pending) => pending.isEmpty ? 'Không có đơn nào' : 'Cần xét duyệt',
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ── Recent orders ─────────────────────────────────────
            Expanded(
              flex: 50,
              child: _RecentOrdersSection(ordersAsync: ordersAsync),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
// Generic card that shows a spinner while loading, then the stat value.
class _AsyncStatCard<T> extends StatelessWidget {
  final String title;
  final IconData icon;
  final AsyncValue<T> asyncValue;
  final String Function(T data) valueBuilder;
  final String Function(T data) subBuilder;

  const _AsyncStatCard({
    required this.title,
    required this.icon,
    required this.asyncValue,
    required this.valueBuilder,
    required this.subBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 18),
          asyncValue.when(
            loading: () => const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, __) => const Icon(Icons.error_outline, size: 20, color: Colors.red),
            data: (data) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  valueBuilder(data),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 1),
                Text(title,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(subBuilder(data),
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.activeGreen, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recent Orders ─────────────────────────────────────────────────────────────
class _RecentOrdersSection extends StatelessWidget {
  final AsyncValue<List<Order>> ordersAsync;

  const _RecentOrdersSection({required this.ordersAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Đơn Hàng Gần Đây',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ordersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text(e.toString())),
                data: (orders) {
                  final recent = orders.take(10).toList();
                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: recent.length,
                    itemBuilder: (_, i) {
                      final order = recent[i];
                      final fmt = NumberFormat('#,###', 'vi_VN');
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _statusDot(order.status),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '#${order.id} ${order.customerName}',
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${fmt.format(order.totalAmount)} ₫',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ]),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusDot(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'approved': return Colors.blue;
      case 'assigned': return Colors.purple;
      case 'completed': return AppColors.activeGreen;
      default: return AppColors.textSecondary;
    }
  }
}

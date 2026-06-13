import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/customer.dart';
import 'customers_provider.dart';

// ── Customers Page ────────────────────────────────────────────────────────────

class CustomersPage extends ConsumerStatefulWidget {
  const CustomersPage({super.key});

  @override
  ConsumerState<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends ConsumerState<CustomersPage>
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
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                const Text('Khách Hàng', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
                  onPressed: () {
                    ref.read(customersProvider.notifier).refresh();
                    ref.read(areasProvider.notifier).refresh();
                  },
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabs,
            labelColor: AppColors.navSelected,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.navSelected,
            tabs: const [Tab(text: 'Khách hàng'), Tab(text: 'Khu vực')],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _CustomersTab(),
                _AreasTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Customers Tab ─────────────────────────────────────────────────────────────
class _CustomersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customersProvider);
    final fmt = NumberFormat('#,###', 'vi_VN');

    return customersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(e.toString(), style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => ref.read(customersProvider.notifier).refresh(),
            child: const Text('Thử lại'),
          ),
        ]),
      ),
      data: (customers) {
        final totalDebt = customers.fold<int>(0, (s, c) => s + c.debt);
        return Column(
          children: [
            // Summary banner
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  Text('${customers.length} khách hàng',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const Spacer(),
                  Text('Tổng nợ: ${fmt.format(totalDebt)} ₫',
                      style: TextStyle(
                        color: totalDebt > 0 ? Colors.red : AppColors.activeGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      )),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: customers.isEmpty
                  ? const Center(child: Text('Chưa có khách hàng', style: TextStyle(color: AppColors.textSecondary)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: customers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _CustomerCard(customer: customers[i], fmt: fmt),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final NumberFormat fmt;

  const _CustomerCard({required this.customer, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.navUnselected,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            if (customer.phone.isNotEmpty)
              Text(customer.phone, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            if (customer.areaName.isNotEmpty)
              Text(customer.areaName, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ]),
        ),
        Text(
          '${fmt.format(customer.debt)} ₫',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: customer.debt > 0 ? Colors.red : (customer.debt < 0 ? AppColors.activeGreen : AppColors.textSecondary),
          ),
        ),
      ]),
    );
  }
}

// ── Areas Tab ─────────────────────────────────────────────────────────────────
class _AreasTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final areasAsync = ref.watch(areasProvider);

    return areasAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (areas) => areas.isEmpty
          ? const Center(child: Text('Chưa có khu vực', style: TextStyle(color: AppColors.textSecondary)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: areas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _AreaCard(area: areas[i]),
            ),
    );
  }
}

class _AreaCard extends StatelessWidget {
  final AreaSummary area;

  const _AreaCard({required this.area});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Row(children: [
        const Icon(Icons.location_on_outlined, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(area.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
        Text('${area.customerCount} KH', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ]),
    );
  }
}

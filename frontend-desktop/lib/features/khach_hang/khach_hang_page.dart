import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import 'package:fisd_shared/core/format_tien.dart';
import 'package:fisd_shared/models/khach_hang.dart';
import 'khach_hang_provider.dart';

class KhachHangPage extends ConsumerStatefulWidget {
  const KhachHangPage({super.key});

  @override
  ConsumerState<KhachHangPage> createState() => _KhachHangPageState();
}

class _KhachHangPageState extends ConsumerState<KhachHangPage> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() { super.initState(); _tabs = TabController(length: 2, vsync: this); }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(children: [
              const Text('Khách Hàng', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
                onPressed: () {
                  ref.read(khachHangProvider.notifier).lamMoi();
                  ref.read(khuVucProvider.notifier).lamMoi();
                },
              ),
            ]),
          ),
          TabBar(
            controller: _tabs,
            labelColor: AppColors.navSelected,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.navSelected,
            tabs: const [Tab(text: 'Khách hàng'), Tab(text: 'Khu vực')],
          ),
          Expanded(
            child: TabBarView(controller: _tabs, children: [_TabKhachHang(), _TabKhuVuc()]),
          ),
        ],
      ),
    );
  }
}

class _TabKhachHang extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final khachHangAsync = ref.watch(khachHangProvider);

    return khachHangAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(e.toString(), style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: () => ref.read(khachHangProvider.notifier).lamMoi(), child: const Text('Thử lại')),
      ])),
      data: (ds) {
        final tongNo = ds.fold<int>(0, (t, k) => t + k.no);
        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Text('${ds.length} khách hàng', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const Spacer(),
                Text('Tổng nợ: ${dinhDangTien(tongNo)}',
                    style: TextStyle(
                      color: tongNo > 0 ? Colors.red : AppColors.activeGreen,
                      fontSize: 12, fontWeight: FontWeight.w600,
                    )),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ds.isEmpty
                ? const Center(child: Text('Chưa có khách hàng', style: TextStyle(color: AppColors.textSecondary)))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: ds.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _TheKhachHang(khachHang: ds[i]),
                  ),
          ),
        ]);
      },
    );
  }
}

class _TheKhachHang extends StatelessWidget {
  final KhachHang khachHang;

  const _TheKhachHang({required this.khachHang});

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
          width: 40, height: 40,
          decoration: BoxDecoration(color: AppColors.navUnselected, borderRadius: BorderRadius.circular(20)),
          child: Center(child: Text(
            khachHang.ten.isNotEmpty ? khachHang.ten[0].toUpperCase() : '?',
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          )),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(khachHang.ten, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          if (khachHang.soDienThoai.isNotEmpty)
            Text(khachHang.soDienThoai, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          if (khachHang.tenKhuVuc.isNotEmpty)
            Text(khachHang.tenKhuVuc, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ])),
        Text(dinhDangTien(khachHang.no),
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: khachHang.no > 0 ? Colors.red : (khachHang.no < 0 ? AppColors.activeGreen : AppColors.textSecondary),
            )),
      ]),
    );
  }
}

class _TabKhuVuc extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final khuVucAsync = ref.watch(khuVucProvider);
    return khuVucAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (ds) => ds.isEmpty
          ? const Center(child: Text('Chưa có khu vực', style: TextStyle(color: AppColors.textSecondary)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: ds.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _TheKhuVuc(khuVuc: ds[i]),
            ),
    );
  }
}

class _TheKhuVuc extends StatelessWidget {
  final TomTatKhuVuc khuVuc;

  const _TheKhuVuc({required this.khuVuc});

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
        Expanded(child: Text(khuVuc.ten, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
        Text('${khuVuc.soKhachHang} KH', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ]),
    );
  }
}

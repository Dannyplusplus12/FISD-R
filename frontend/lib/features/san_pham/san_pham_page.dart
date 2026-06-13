import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/san_pham.dart';
import 'san_pham_provider.dart';

class SanPhamPage extends ConsumerStatefulWidget {
  const SanPhamPage({super.key});

  @override
  ConsumerState<SanPhamPage> createState() => _SanPhamPageState();
}

class _SanPhamPageState extends ConsumerState<SanPhamPage> {
  final _timKiemCtrl = TextEditingController();

  @override
  void dispose() { _timKiemCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final sanPhamAsync = ref.watch(sanPhamProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('Sản Phẩm',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
                onPressed: () => ref.read(sanPhamProvider.notifier).lamMoi(),
              ),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: _timKiemCtrl,
              decoration: InputDecoration(
                hintText: 'Tìm sản phẩm…',
                prefixIcon: const Icon(Icons.search, size: 18),
                filled: true, fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (q) => ref.read(sanPhamProvider.notifier).timKiem(q),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: sanPhamAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (loi, _) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 8),
                  Text(loi.toString(), textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.read(sanPhamProvider.notifier).lamMoi(),
                    child: const Text('Thử lại'),
                  ),
                ])),
                data: (dsSanPham) => dsSanPham.isEmpty
                    ? const Center(child: Text('Chưa có sản phẩm nào',
                        style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.separated(
                        itemCount: dsSanPham.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _TheSanPham(sanPham: dsSanPham[i]),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TheSanPham extends StatelessWidget {
  final SanPham sanPham;

  const _TheSanPham({required this.sanPham});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'vi_VN');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: AppColors.navUnselected, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.inventory_2_outlined, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(sanPham.ten,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
              if (sanPham.ma.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text('Mã: ${sanPham.ma}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
              const SizedBox(height: 4),
              Wrap(
                spacing: 4, runSpacing: 4,
                children: sanPham.bienThes.map((v) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.navUnselected, borderRadius: BorderRadius.circular(6)),
                  child: Text('${v.tenHienThi}: ${fmt.format(v.gia)}₫ (${v.tonKho})',
                      style: const TextStyle(fontSize: 10, color: AppColors.textPrimary)),
                )).toList(),
              ),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: sanPham.tongTonKho > 0 ? AppColors.activeGreen.withOpacity(0.1) : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${sanPham.tongTonKho}',
                style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: sanPham.tongTonKho > 0 ? AppColors.activeGreen : Colors.red,
                )),
          ),
        ],
      ),
    );
  }
}

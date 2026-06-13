import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/nhan_vien.dart';
import 'nhan_vien_provider.dart';

class NhanVienPage extends ConsumerWidget {
  const NhanVienPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nhanVienAsync = ref.watch(nhanVienProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('Nhân Viên', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
                onPressed: () => ref.read(nhanVienProvider.notifier).lamMoi(),
              ),
            ]),
            const SizedBox(height: 16),
            Expanded(
              child: nhanVienAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(e.toString(), style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: () => ref.read(nhanVienProvider.notifier).lamMoi(), child: const Text('Thử lại')),
                ])),
                data: (ds) => ds.isEmpty
                    ? const Center(child: Text('Chưa có nhân viên', style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.separated(
                        itemCount: ds.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _TheNhanVien(nhanVien: ds[i]),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TheNhanVien extends StatelessWidget {
  final NhanVien nhanVien;

  const _TheNhanVien({required this.nhanVien});

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
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: nhanVien.dangHoatDong ? AppColors.navSelected : AppColors.navUnselected,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Center(child: Text(
            nhanVien.ten.isNotEmpty ? nhanVien.ten[0].toUpperCase() : '?',
            style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 16,
              color: nhanVien.dangHoatDong ? Colors.white : AppColors.textSecondary,
            ),
          )),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(nhanVien.ten, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            if (!nhanVien.dangHoatDong) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                child: const Text('Nghỉ', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ),
            ],
          ]),
          Text(nhanVien.soDienThoai, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _mauVaiTro(nhanVien.vaiTro).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(nhanVien.nhanVaiTro,
                style: TextStyle(fontSize: 11, color: _mauVaiTro(nhanVien.vaiTro), fontWeight: FontWeight.w600)),
          ),
          if (nhanVien.soDonGiao > 0) ...[
            const SizedBox(height: 4),
            Text('${nhanVien.soDonGiao} đơn', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ]),
      ]),
    );
  }

  Color _mauVaiTro(String vaiTro) {
    switch (vaiTro) {
      case 'manager': return Colors.purple;
      case 'picker': return Colors.blue;
      default: return Colors.orange;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fisd_shared/fisd_shared.dart';

import '../../core/session/phien_lam_viec.dart';
import '../../core/theme.dart';
import '../../core/thong_bao/da_xem_provider.dart';
import '../../core/thong_bao/dem_chua_doc_provider.dart';
import '../../core/thong_bao/nut_thong_bao.dart';
import 'chat_provider.dart';
import 'chat_repository.dart';
import 'kenh_chi_tiet_page.dart';

class DanhSachKenhPage extends ConsumerWidget {
  final PhienLamViec phien;
  const DanhSachKenhPage({super.key, required this.phien});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(danhSachKenhProvider(phien.id));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chat', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _moTaoKenh(context, ref),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_comment_outlined, color: Colors.white),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => errorState(() => ref.invalidate(danhSachKenhProvider(phien.id))),
        data: (list) {
          if (list.isEmpty) {
            return emptyState(Icons.chat_bubble_outline, 'Chưa có kênh chat nào',
                sub: 'Nhấn nút + để tạo kênh mới');
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(danhSachKenhProvider(phien.id)),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _KenhTile(kenh: list[i], phien: phien),
            ),
          );
        },
      ),
    );
  }

  Future<void> _moTaoKenh(BuildContext context, WidgetRef ref) async {
    final nhanVienList = await ref.read(danhSachNhanVienProvider.future);
    final tenCtrl = TextEditingController();
    final chon = <int>{};
    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
              left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Tạo kênh chat mới', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            TextField(controller: tenCtrl, decoration: AppDeco.input('Tên kênh')),
            const SizedBox(height: 16),
            const Text('Thêm thành viên', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(
              height: 240,
              child: ListView(
                children: nhanVienList
                    .where((nv) => nv.id != phien.id)
                    .map((nv) => CheckboxListTile(
                          value: chon.contains(nv.id),
                          onChanged: (v) => setState(() => v == true ? chon.add(nv.id) : chon.remove(nv.id)),
                          title: Text(nv.ten),
                          subtitle: Text(nv.nhanVaiTro),
                          controlAffinity: ListTileControlAffinity.leading,
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: AppDeco.primaryBtn,
                onPressed: () async {
                  if (tenCtrl.text.trim().isEmpty) return;
                  await ref.read(chatRepositoryProvider).taoKenh(
                        ten: tenCtrl.text.trim(),
                        thanhVienIds: chon.toList(),
                        chuKenhId: phien.id,
                      );
                  ref.invalidate(danhSachKenhProvider(phien.id));
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Tạo kênh'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _KenhTile extends ConsumerWidget {
  final KenhChat kenh;
  final PhienLamViec phien;
  const _KenhTile({required this.kenh, required this.phien});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mauTieuDe = kenh.laKenhDonHang ? AppColors.warning : AppColors.primary;
    final chuaDoc = ref.watch(demChuaDocProvider.select((m) => (m[kenh.id] ?? 0) > 0));
    final daXemKey = 'kenh_${kenh.id}';
    final daXem = ref.watch(daXemProvider.select((s) => s.contains(daXemKey)));
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          ref.read(daXemProvider.notifier).danhDauDaXem(daXemKey);
          ref.read(demChuaDocProvider.notifier).xoa(kenh.id);
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => KenhChiTietPage(kenh: kenh, phien: phien)));
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            NutThongBao(
              coThongBao: chuaDoc,
              daXem: daXem,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: mauTieuDe.withOpacity(0.12),
                child: Icon(kenh.laKenhDonHang ? Icons.local_shipping_outlined : Icons.tag,
                    color: mauTieuDe, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(kenh.ten, style: TextStyle(fontWeight: FontWeight.bold, color: mauTieuDe, fontSize: 15)),
                const SizedBox(height: 2),
                Text('${kenh.thanhVien.length} thành viên',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ]),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ]),
        ),
      ),
    );
  }
}

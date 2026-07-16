import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fisd_shared/fisd_shared.dart';

import '../../core/theme.dart';
import 'chat_provider.dart';
import 'chat_repository.dart';
import 'danh_tinh_chat_provider.dart';
import 'kenh_chi_tiet_page.dart';

class DanhSachKenhPage extends ConsumerWidget {
  const DanhSachKenhPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final danhTinh = ref.watch(danhTinhChatProvider);
    return danhTinh.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Lỗi: $e')),
      data: (dt) => dt == null ? const _ChonDanhTinhView() : _DanhSachKenhView(danhTinh: dt),
    );
  }
}

class _ChonDanhTinhView extends ConsumerWidget {
  const _ChonDanhTinhView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nhanVienList = ref.watch(danhSachNhanVienProvider);
    return Container(
      color: AppColors.background,
      child: Center(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.chat_bubble_outline, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            const Text('Bạn là ai?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Chọn nhân viên của bạn để dùng chat trên máy này',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 20),
            nhanVienList.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Lỗi tải nhân viên: $e'),
              data: (list) => SizedBox(
                height: 300,
                width: double.infinity,
                child: ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final nv = list[i];
                    return ListTile(
                      title: Text(nv.ten),
                      subtitle: Text(nv.nhanVaiTro),
                      onTap: () => ref.read(danhTinhChatProvider.notifier).chon(nv.id, nv.ten),
                    );
                  },
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _DanhSachKenhView extends ConsumerWidget {
  final DanhTinhChat danhTinh;
  const _DanhSachKenhView({required this.danhTinh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(danhSachKenhProvider(danhTinh.id));
    return Container(
      color: AppColors.background,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Row(children: [
            const Text('Chat', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('Bạn: ${danhTinh.ten}', style: const TextStyle(color: AppColors.textSecondary)),
            IconButton(
              icon: const Icon(Icons.switch_account_outlined),
              tooltip: 'Đổi người dùng',
              onPressed: () => ref.read(danhTinhChatProvider.notifier).doiNguoiDung(),
            ),
            IconButton(
              icon: const Icon(Icons.add_comment_outlined),
              tooltip: 'Tạo kênh mới',
              onPressed: () => _moTaoKenh(context, ref),
            ),
          ]),
        ),
        Expanded(
          child: state.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Lỗi tải kênh chat: $e'),
                TextButton(onPressed: () => ref.invalidate(danhSachKenhProvider(danhTinh.id)), child: const Text('Thử lại')),
              ]),
            ),
            data: (list) {
              if (list.isEmpty) {
                return const Center(child: Text('Chưa có kênh chat nào', style: TextStyle(color: AppColors.textSecondary)));
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _KenhTile(kenh: list[i], danhTinh: danhTinh),
              );
            },
          ),
        ),
      ]),
    );
  }

  Future<void> _moTaoKenh(BuildContext context, WidgetRef ref) async {
    final nhanVienList = await ref.read(danhSachNhanVienProvider.future);
    final tenCtrl = TextEditingController();
    final chon = <int>{};
    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Tạo kênh chat mới'),
          content: SizedBox(
            width: 420,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: tenCtrl, decoration: const InputDecoration(labelText: 'Tên kênh')),
              const SizedBox(height: 12),
              SizedBox(
                height: 260,
                child: ListView(
                  children: nhanVienList
                      .where((nv) => nv.id != danhTinh.id)
                      .map((nv) => CheckboxListTile(
                            value: chon.contains(nv.id),
                            onChanged: (v) => setState(() => v == true ? chon.add(nv.id) : chon.remove(nv.id)),
                            title: Text(nv.ten),
                            subtitle: Text(nv.nhanVaiTro),
                          ))
                      .toList(),
                ),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            FilledButton(
              onPressed: () async {
                if (tenCtrl.text.trim().isEmpty) return;
                await ref.read(chatRepositoryProvider).taoKenh(
                      ten: tenCtrl.text.trim(),
                      thanhVienIds: chon.toList(),
                      chuKenhId: danhTinh.id,
                    );
                ref.invalidate(danhSachKenhProvider(danhTinh.id));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Tạo kênh'),
            ),
          ],
        ),
      ),
    );
  }
}

class _KenhTile extends StatelessWidget {
  final KenhChat kenh;
  final DanhTinhChat danhTinh;
  const _KenhTile({required this.kenh, required this.danhTinh});

  @override
  Widget build(BuildContext context) {
    final mauTieuDe = kenh.laKenhDonHang ? Colors.deepOrange : AppColors.navSelected;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => KenhChiTietPage(kenh: kenh, danhTinh: danhTinh))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: mauTieuDe.withOpacity(0.12),
              child: Icon(kenh.laKenhDonHang ? Icons.local_shipping_outlined : Icons.tag, color: mauTieuDe, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(kenh.ten, style: TextStyle(fontWeight: FontWeight.bold, color: mauTieuDe)),
                Text('${kenh.thanhVien.length} thành viên', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ]),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ]),
        ),
      ),
    );
  }
}

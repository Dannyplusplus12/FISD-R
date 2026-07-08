import 'package:fisd_shared/fisd_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../xac_thuc/xac_thuc_provider.dart';
import 'kho_hang_provider.dart';
import 'chi_tiet_kho_page.dart';

class KhoHangPage extends ConsumerWidget {
  const KhoHangPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(danhSachKhoProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kho hàng', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Đăng xuất',
            onPressed: () => ref.read(xacThucProvider.notifier).dangXuat(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _themKho(context, ref),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => errorState(() => ref.invalidate(danhSachKhoProvider)),
        data: (khos) {
          if (khos.isEmpty) {
            return emptyState(Icons.store_outlined, 'Chưa có kho nào',
                sub: 'Nhấn + để thêm kho mới');
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(danhSachKhoProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: khos.length,
              itemBuilder: (_, i) => _KhoCard(
                kho: khos[i],
                onTap: () => _moChiTiet(context, ref, khos[i]),
                onSua: () => _suaKho(context, ref, khos[i]),
                onXoa: () => _xoaKho(context, ref, khos[i]),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _moChiTiet(BuildContext ctx, WidgetRef ref, KhoHang kho) async {
    await Navigator.push(ctx, MaterialPageRoute(builder: (_) => ChiTietKhoPage(kho: kho)));
    ref.invalidate(danhSachKhoProvider);
  }

  Future<void> _themKho(BuildContext ctx, WidgetRef ref) async {
    await showModalBottomSheet(
        context: ctx, isScrollControlled: true, builder: (_) => const _FormKho());
    ref.invalidate(danhSachKhoProvider);
  }

  Future<void> _suaKho(BuildContext ctx, WidgetRef ref, KhoHang kho) async {
    await showModalBottomSheet(
        context: ctx, isScrollControlled: true, builder: (_) => _FormKho(edit: kho));
    ref.invalidate(danhSachKhoProvider);
  }

  Future<void> _xoaKho(BuildContext ctx, WidgetRef ref, KhoHang kho) async {
    final ok = await showDialog<bool>(
        context: ctx,
        builder: (_) => AlertDialog(
              title: const Text('Xóa kho?'),
              content: Text('Xóa kho "${kho.ten}"? Các biến thể sẽ bị hủy liên kết.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Xóa', style: TextStyle(color: AppColors.danger))),
              ],
            ));
    if (ok == true) {
      await ref.read(khoHangActionProvider.notifier).xoaKho(kho.id);
      ref.invalidate(danhSachKhoProvider);
    }
  }
}

class _KhoCard extends StatelessWidget {
  final KhoHang kho;
  final VoidCallback onTap;
  final VoidCallback onSua;
  final VoidCallback onXoa;

  const _KhoCard({
    required this.kho,
    required this.onTap,
    required this.onSua,
    required this.onXoa,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppDeco.card(),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.store_outlined, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(kho.ten,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                if (kho.viTri.isNotEmpty)
                  Text(kho.viTri,
                      style:
                          const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ])),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'sua') onSua();
                  if (v == 'xoa') onXoa();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'sua',
                      child: Row(children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Sửa')
                      ])),
                  const PopupMenuItem(
                      value: 'xoa',
                      child: Row(children: [
                        Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                        SizedBox(width: 8),
                        Text('Xóa', style: TextStyle(color: AppColors.danger))
                      ])),
                ],
                child: const Icon(Icons.more_vert, color: AppColors.textSecondary),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _FormKho extends ConsumerStatefulWidget {
  final KhoHang? edit;
  const _FormKho({this.edit});

  @override
  ConsumerState<_FormKho> createState() => _FormKhoState();
}

class _FormKhoState extends ConsumerState<_FormKho> {
  final _tenCtrl = TextEditingController();
  final _viTriCtrl = TextEditingController();
  final _ghiChuCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.edit != null) {
      _tenCtrl.text = widget.edit!.ten;
      _viTriCtrl.text = widget.edit!.viTri;
      _ghiChuCtrl.text = widget.edit!.ghiChu;
    }
  }

  @override
  void dispose() {
    _tenCtrl.dispose();
    _viTriCtrl.dispose();
    _ghiChuCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20, right: 20, top: 20),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Text(widget.edit == null ? 'Thêm kho mới' : 'Sửa kho',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Spacer(),
              IconButton(
                  icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ]),
            const SizedBox(height: 16),
            TextField(
                controller: _tenCtrl,
                decoration: AppDeco.input('Tên kho *', icon: Icons.store_outlined)),
            const SizedBox(height: 10),
            TextField(
                controller: _viTriCtrl,
                decoration:
                    AppDeco.input('Vị trí', icon: Icons.location_on_outlined)),
            const SizedBox(height: 10),
            TextField(
                controller: _ghiChuCtrl,
                decoration: AppDeco.input('Ghi chú', icon: Icons.notes_outlined)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _luu,
              style: AppDeco.primaryBtn,
              child: _loading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Lưu',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 20),
          ]),
    );
  }

  Future<void> _luu() async {
    final ten = _tenCtrl.text.trim();
    if (ten.isEmpty) return;
    setState(() => _loading = true);
    if (widget.edit != null) {
      await ref.read(khoHangActionProvider.notifier).capNhatKho(
          widget.edit!.id, ten, _viTriCtrl.text.trim(), _ghiChuCtrl.text.trim());
    } else {
      await ref
          .read(khoHangActionProvider.notifier)
          .taoKho(ten, _viTriCtrl.text.trim(), _ghiChuCtrl.text.trim());
    }
    if (mounted) Navigator.pop(context);
  }
}

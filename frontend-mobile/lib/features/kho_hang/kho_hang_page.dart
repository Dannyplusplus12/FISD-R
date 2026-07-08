import 'package:fisd_shared/fisd_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'kho_hang_provider.dart';
import 'chi_tiet_kho_page.dart';

class KhoHangPage extends ConsumerWidget {
  const KhoHangPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(danhSachKhoProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Kho hàng')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _themKho(context, ref),
        child: const Icon(Icons.add),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: TextButton(
          onPressed: () => ref.invalidate(danhSachKhoProvider),
          child: const Text('Lỗi — thử lại'),
        )),
        data: (khos) {
          if (khos.isEmpty) {
            return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.store_outlined, size: 56, color: Colors.grey),
              SizedBox(height: 12),
              Text('Chưa có kho nào', style: TextStyle(color: Colors.grey)),
              SizedBox(height: 4),
              Text('Nhấn + để thêm kho', style: TextStyle(color: Colors.grey, fontSize: 13)),
            ]));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(danhSachKhoProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
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
    await showModalBottomSheet(context: ctx, isScrollControlled: true, builder: (_) => const _FormKho());
    ref.invalidate(danhSachKhoProvider);
  }

  Future<void> _suaKho(BuildContext ctx, WidgetRef ref, KhoHang kho) async {
    await showModalBottomSheet(context: ctx, isScrollControlled: true, builder: (_) => _FormKho(edit: kho));
    ref.invalidate(danhSachKhoProvider);
  }

  Future<void> _xoaKho(BuildContext ctx, WidgetRef ref, KhoHang kho) async {
    final ok = await showDialog<bool>(context: ctx, builder: (_) => AlertDialog(
      title: const Text('Xóa kho?'),
      content: Text('Xóa kho "${kho.ten}"? Tất cả biến thể trong kho sẽ bị hủy liên kết.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
      ],
    ));
    if (ok == true) {
      await ref.read(khoHangActionProvider.notifier).xoaKho(kho.id);
      ref.invalidate(danhSachKhoProvider);
    }
  }
}

// ── Card kho ─────────────────────────────────────────────────────────────────

class _KhoCard extends StatelessWidget {
  final KhoHang kho;
  final VoidCallback onTap;
  final VoidCallback onSua;
  final VoidCallback onXoa;

  const _KhoCard({required this.kho, required this.onTap, required this.onSua, required this.onXoa});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.store_outlined, color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(kho.ten, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              if (kho.viTri.isNotEmpty)
                Text(kho.viTri, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              if (kho.ghiChu.isNotEmpty)
                Text(kho.ghiChu, style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            PopupMenuButton<String>(
              onSelected: (v) { if (v == 'sua') onSua(); else if (v == 'xoa') onXoa(); },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'sua', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Sửa')])),
                const PopupMenuItem(value: 'xoa', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 8), Text('Xóa', style: TextStyle(color: Colors.red))])),
              ],
              child: const Icon(Icons.more_vert, color: Colors.grey),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Form kho ─────────────────────────────────────────────────────────────────

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
  void dispose() { _tenCtrl.dispose(); _viTriCtrl.dispose(); _ghiChuCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(widget.edit == null ? 'Thêm kho mới' : 'Sửa kho', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        _input(_tenCtrl, 'Tên kho *', Icons.store_outlined),
        const SizedBox(height: 10),
        _input(_viTriCtrl, 'Vị trí (VD: Tầng 1, góc trái)', Icons.location_on_outlined),
        const SizedBox(height: 10),
        _input(_ghiChuCtrl, 'Ghi chú', Icons.notes_outlined),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _luu,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A1A2E), foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Lưu', style: TextStyle(fontSize: 16)),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _input(TextEditingController c, String hint, IconData icon) => TextField(
    controller: c,
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: Colors.grey),
      filled: true, fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    ),
  );

  Future<void> _luu() async {
    final ten = _tenCtrl.text.trim();
    if (ten.isEmpty) return;
    if (widget.edit != null) {
      await ref.read(khoHangActionProvider.notifier).capNhatKho(widget.edit!.id, ten, _viTriCtrl.text.trim(), _ghiChuCtrl.text.trim());
    } else {
      await ref.read(khoHangActionProvider.notifier).taoKho(ten, _viTriCtrl.text.trim(), _ghiChuCtrl.text.trim());
    }
    if (mounted) Navigator.pop(context);
  }
}

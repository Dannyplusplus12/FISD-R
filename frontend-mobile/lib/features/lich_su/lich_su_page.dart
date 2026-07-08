import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/session/phien_lam_viec.dart';
import 'lich_su_provider.dart';
import 'lich_su_repository.dart';

const _boLocNhan = ['Hôm nay', 'Tuần', 'Tháng', 'Quý', 'Tất cả'];
const _boLocNgay = [1, 7, 30, 90, 0];

class LichSuPage extends ConsumerStatefulWidget {
  final PhienLamViec phien;
  const LichSuPage({super.key, required this.phien});

  @override
  ConsumerState<LichSuPage> createState() => _LichSuPageState();
}

class _LichSuPageState extends ConsumerState<LichSuPage> {
  int _boLocIdx = 4;

  @override
  Widget build(BuildContext context) {
    final filter = LichSuFilter(pickerId: widget.phien.id, days: _boLocNgay[_boLocIdx]);
    final state = ref.watch(lichSuProvider(filter));

    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử giao hàng')),
      body: Column(children: [
        // Filter chips
        SizedBox(
          height: 48,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            scrollDirection: Axis.horizontal,
            itemCount: _boLocNhan.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, i) => ChoiceChip(
              label: Text(_boLocNhan[i]),
              selected: _boLocIdx == i,
              onSelected: (_) => setState(() => _boLocIdx = i),
            ),
          ),
        ),
        Expanded(child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: TextButton(onPressed: () => ref.invalidate(lichSuProvider(filter)), child: const Text('Lỗi — thử lại'))),
          data: (list) {
            if (list.isEmpty) return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.local_shipping_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text('Chưa có đơn giao', style: TextStyle(color: Colors.grey)),
            ]));
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(lichSuProvider(filter)),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: list.length,
                itemBuilder: (_, i) => _DonCuCard(
                  don: list[i],
                  onTap: () => _moChiTiet(context, list[i], filter),
                ),
              ),
            );
          },
        )),
      ]),
    );
  }

  Future<void> _moChiTiet(BuildContext ctx, Map don, LichSuFilter filter) async {
    await Navigator.push(ctx, MaterialPageRoute(builder: (_) => _ChiTietDonCuPage(don: don, phien: widget.phien)));
    ref.invalidate(lichSuProvider(filter));
  }
}

// ── Card đơn cũ ───────────────────────────────────────────────────────────────

class _DonCuCard extends StatelessWidget {
  final Map don;
  final VoidCallback onTap;
  const _DonCuCard({required this.don, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Đơn #${don["id"]} — ${don["customer_name"] ?? "Khách lẻ"}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(don['delivered_at'] ?? don['created_at'] ?? '',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              if ((don['picker_note'] ?? '').isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 2),
                    child: Text(don['picker_note'], style: const TextStyle(color: Colors.orange, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ])),
            Text('${_fmt(don["total_amount"])} đ', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ]),
        ),
      ),
    );
  }
}

// ── Chi tiết đơn cũ (có sửa ghi chú + ảnh) ──────────────────────────────────

class _ChiTietDonCuPage extends ConsumerStatefulWidget {
  final Map don;
  final PhienLamViec phien;
  const _ChiTietDonCuPage({required this.don, required this.phien});

  @override
  ConsumerState<_ChiTietDonCuPage> createState() => _ChiTietDonCuPageState();
}

class _ChiTietDonCuPageState extends ConsumerState<_ChiTietDonCuPage> {
  late List<String> _anhs;
  late String _ghiChu;
  bool _dangLuu = false;

  @override
  void initState() {
    super.initState();
    _anhs = List<String>.from(widget.don['delivery_photo_paths'] as List? ?? []);
    _ghiChu = widget.don['picker_note'] ?? '';
  }

  Future<void> _suaGhiChu() async {
    final ctrl = TextEditingController(text: _ghiChu);
    final result = await showDialog<String>(context: context, builder: (_) => AlertDialog(
      title: const Text('Sửa ghi chú'),
      content: TextField(controller: ctrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Ghi chú...')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
        TextButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text('Lưu')),
      ],
    ));
    if (result == null || !mounted) return;
    setState(() => _dangLuu = true);
    await ref.read(lichSuRepoProvider).suaGhiChu(widget.don['id'], widget.phien.id, result);
    setState(() { _ghiChu = result; _dangLuu = false; });
  }

  Future<void> _themAnh() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isEmpty || !mounted) return;
    setState(() => _dangLuu = true);
    for (final x in picked) {
      final multi = MultipartFile.fromFileSync(x.path, filename: x.path.split('/').last);
      final res = await ref.read(lichSuRepoProvider).themAnh(widget.don['id'], widget.phien.id, multi);
      setState(() => _anhs.add(res['url'] as String));
    }
    setState(() => _dangLuu = false);
  }

  Future<void> _xoaAnh(int idx) async {
    final keys = widget.don['delivery_photo_paths'] as List? ?? [];
    // Tìm key tương ứng với index (keys và _anhs có cùng thứ tự)
    if (idx >= keys.length) return;
    final key = keys[idx];
    setState(() => _dangLuu = true);
    await ref.read(lichSuRepoProvider).xoaAnh(widget.don['id'], widget.phien.id, key.toString());
    setState(() { _anhs.removeAt(idx); _dangLuu = false; });
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.don['items'] as List? ?? [];
    return Scaffold(
      appBar: AppBar(
        title: Text('Đơn #${widget.don["id"]}'),
        actions: [if (_dangLuu) const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Thông tin đơn
        _infoRow('Khách hàng', widget.don['customer_name'] ?? 'Khách lẻ'),
        _infoRow('Ngày giao', widget.don['delivered_at'] ?? widget.don['created_at'] ?? ''),
        _infoRow('Tổng tiền', '${_fmt(widget.don["total_amount"])} đ'),
        const Divider(height: 24),

        // Hàng hóa
        const Text('Hàng hóa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: [
            Expanded(child: Text('${item["product_name"]} ${item["variant_info"] ?? ""}')),
            Text('x${item["quantity"]}  ${_fmt(item["price"])} đ', style: const TextStyle(color: Colors.grey)),
          ]),
        )),
        const Divider(height: 24),

        // Ghi chú
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Ghi chú', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: _suaGhiChu),
        ]),
        if (_ghiChu.isNotEmpty)
          Text(_ghiChu, style: const TextStyle(color: Colors.grey))
        else
          const Text('Không có ghi chú', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
        const Divider(height: 24),

        // Ảnh giao hàng
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Ảnh giao hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          TextButton.icon(onPressed: _dangLuu ? null : _themAnh, icon: const Icon(Icons.add_photo_alternate_outlined, size: 18), label: const Text('Thêm')),
        ]),
        if (_anhs.isEmpty)
          const Text('Chưa có ảnh', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 6, mainAxisSpacing: 6),
            itemCount: _anhs.length,
            itemBuilder: (_, i) => Stack(fit: StackFit.expand, children: [
              ClipRRect(borderRadius: BorderRadius.circular(8),
                  child: Image.network(_anhs[i], fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image)))),
              Positioned(top: 2, right: 2, child: GestureDetector(
                onTap: () => _xoaAnh(i),
                child: const CircleAvatar(radius: 10, backgroundColor: Colors.red, child: Icon(Icons.close, size: 12, color: Colors.white)),
              )),
            ]),
          ),
      ]),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey))),
      Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
    ]),
  );
}

String _fmt(dynamic v) {
  final n = (v is int) ? v : int.tryParse(v.toString()) ?? 0;
  return n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

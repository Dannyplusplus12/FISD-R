import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/session/phien_lam_viec.dart';
import '../../core/theme.dart';
import '../xac_thuc/xac_thuc_provider.dart';
import 'lich_su_provider.dart';

const _boLocNhan = ['Hôm nay', 'Tuần', 'Tháng', 'Tất cả'];
const _boLocNgay = [1, 7, 30, 0];

class LichSuPage extends ConsumerStatefulWidget {
  final PhienLamViec phien;
  const LichSuPage({super.key, required this.phien});

  @override
  ConsumerState<LichSuPage> createState() => _LichSuPageState();
}

class _LichSuPageState extends ConsumerState<LichSuPage> {
  int _boLocIdx = 3;

  @override
  Widget build(BuildContext context) {
    final filter = LichSuFilter(pickerId: widget.phien.id, days: _boLocNgay[_boLocIdx]);
    final state = ref.watch(lichSuProvider(filter));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lịch sử giao hàng', style: TextStyle(fontWeight: FontWeight.bold)),
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
      body: Column(children: [
        Container(
          color: AppColors.surface,
          child: SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _boLocNhan.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) => ChoiceChip(
                label: Text(_boLocNhan[i]),
                selected: _boLocIdx == i,
                onSelected: (_) => setState(() => _boLocIdx = i),
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                    color: _boLocIdx == i ? Colors.white : AppColors.textSecondary,
                    fontSize: 13),
                backgroundColor: AppColors.background,
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
        ),
        Container(height: 1, color: AppColors.divider),
        Expanded(child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => errorState(() => ref.invalidate(lichSuProvider(filter))),
          data: (list) {
            if (list.isEmpty) {
              return emptyState(Icons.local_shipping_outlined, 'Chưa có đơn giao nào');
            }
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(lichSuProvider(filter)),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) => _DonCuCard(don: list[i], phien: widget.phien),
              ),
            );
          },
        )),
      ]),
    );
  }
}

// ── Card đơn cũ (expandable) ─────────────────────────────────────────────────

String _formatGhiChu(String note) {
  final idx = note.indexOf(' | ');
  if (idx < 0) return note;
  return '${note.substring(0, idx)}\n${note.substring(idx + 3)}';
}

class _DonCuCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> don;
  final PhienLamViec phien;
  const _DonCuCard({required this.don, required this.phien});

  @override
  ConsumerState<_DonCuCard> createState() => _DonCuCardState();
}

class _DonCuCardState extends ConsumerState<_DonCuCard> {
  bool _mo = false;
  late List<String> _anhs;
  late List<String> _anhKeys;
  late String _ghiChu;
  bool _dangLuu = false;

  @override
  void initState() {
    super.initState();
    _anhs = List<String>.from(widget.don['delivery_photo_paths'] as List? ?? []);
    _anhKeys = List<String>.from(widget.don['delivery_photo_keys'] as List? ?? []);
    _ghiChu = widget.don['picker_note'] ?? '';
  }

  Future<void> _suaGhiChu() async {
    final ctrl = TextEditingController(text: _ghiChu);
    final result = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('Sửa ghi chú'),
              content: TextField(
                  controller: ctrl,
                  maxLines: 4,
                  decoration: const InputDecoration(hintText: 'Ghi chú...')),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
                TextButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text('Lưu')),
              ],
            ));
    if (result == null || !mounted) return;
    setState(() => _dangLuu = true);
    await ref.read(lichSuRepoProvider).suaGhiChu(widget.don['id'] as int, widget.phien.id, result);
    if (mounted) setState(() { _ghiChu = result; _dangLuu = false; });
  }

  Future<void> _themAnh() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isEmpty || !mounted) return;
    await _uploadAnh(picked.map((x) => x.path).toList());
  }

  Future<void> _chupCamera() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked == null || !mounted) return;
    await _uploadAnh([picked.path]);
  }

  Future<void> _uploadAnh(List<String> paths) async {
    if (!mounted) return;
    setState(() => _dangLuu = true);
    for (final path in paths) {
      final multi = MultipartFile.fromFileSync(path, filename: path.split('/').last);
      final res = await ref.read(lichSuRepoProvider).themAnh(widget.don['id'] as int, widget.phien.id, multi);
      if (mounted) setState(() {
        _anhs.add((res['url'] ?? '') as String);
        _anhKeys.add((res['key'] ?? '') as String);
      });
    }
    if (mounted) setState(() => _dangLuu = false);
  }

  void _pilotChonAnh() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Chụp ảnh'),
            onTap: () { Navigator.pop(context); _chupCamera(); },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Chọn từ thư viện'),
            onTap: () { Navigator.pop(context); _themAnh(); },
          ),
        ]),
      ),
    );
  }

  Future<void> _xoaAnh(int idx) async {
    if (idx >= _anhKeys.length) return;
    final key = _anhKeys[idx];
    if (key.isEmpty) return;
    setState(() => _dangLuu = true);
    await ref.read(lichSuRepoProvider).xoaAnh(widget.don['id'] as int, widget.phien.id, key);
    if (mounted) setState(() {
      _anhs.removeAt(idx);
      _anhKeys.removeAt(idx);
      _dangLuu = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final don = widget.don;
    final items = don['items'] as List? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppDeco.card(),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // ── Header ──────────────────────────────────────────────
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _mo = !_mo),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Đơn #${don["id"]} — ${don["customer_name"] ?? "Khách lẻ"}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(don['delivered_at'] ?? don['created_at'] ?? '',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  if (_ghiChu.isNotEmpty)
                    Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(_formatGhiChu(_ghiChu),
                            style: const TextStyle(color: AppColors.warning, fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis)),
                ])),
                const SizedBox(width: 8),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(fmtTien(don["total_amount"]),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Hoàn thành',
                        style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ]),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _mo ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                ),
              ]),
            ),
          ),
        ),
        // ── Expanded content ─────────────────────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _mo
              ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Container(height: 1, color: AppColors.divider),
                  // Bảng hàng hóa
                  _BangHangHoa(items: items),
                  Container(height: 1, color: AppColors.divider),
                  // Ghi chú
                  _ghiChuSection(),
                  Container(height: 1, color: AppColors.divider),
                  // Ảnh giao hàng
                  _anhSection(),
                  const SizedBox(height: 4),
                ])
              : const SizedBox.shrink(),
        ),
      ]),
    );
  }

  Widget _ghiChuSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Ghi chú', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
          const Spacer(),
          if (_dangLuu)
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          else
            InkWell(
              onTap: _suaGhiChu,
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
              ),
            ),
        ]),
        const SizedBox(height: 4),
        _ghiChu.isNotEmpty
            ? Text(_formatGhiChu(_ghiChu), style: const TextStyle(fontSize: 13))
            : const Text('Chưa có ghi chú',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _anhSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Ảnh giao hàng', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
          const Spacer(),
          InkWell(
            onTap: _dangLuu ? null : _pilotChonAnh,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.add_photo_alternate_outlined,
                  size: 18, color: _dangLuu ? AppColors.textSecondary : AppColors.primary),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        if (_anhs.isEmpty)
          const Text('Chưa có ảnh',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontStyle: FontStyle.italic))
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4),
            itemCount: _anhs.length,
            itemBuilder: (_, i) => Stack(fit: StackFit.expand, children: [
              ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(_anhs[i], fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          color: AppColors.background,
                          child: const Icon(Icons.broken_image_outlined, color: AppColors.textSecondary, size: 20)))),
              if (i < _anhKeys.length && _anhKeys[i].isNotEmpty)
                Positioned(
                    top: 2, right: 2,
                    child: GestureDetector(
                      onTap: () => _xoaAnh(i),
                      child: const CircleAvatar(
                          radius: 10,
                          backgroundColor: AppColors.danger,
                          child: Icon(Icons.close, size: 12, color: Colors.white)),
                    )),
            ]),
          ),
      ]),
    );
  }
}

// ── Bảng hàng hóa (dùng chung) ───────────────────────────────────────────────

class _BangHangHoa extends StatelessWidget {
  final List items;
  const _BangHangHoa({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
        color: AppColors.background,
        child: const Row(children: [
          Expanded(child: Text('Sản phẩm', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600))),
          SizedBox(width: 30, child: Text('SL', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600))),
          SizedBox(width: 64, child: Text('Đơn giá', textAlign: TextAlign.right, style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600))),
          SizedBox(width: 64, child: Text('Tổng', textAlign: TextAlign.right, style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600))),
        ]),
      ),
      const Divider(height: 1, color: AppColors.divider),
      ...List.generate(items.length, (i) {
        final item = items[i] as Map;
        final qty = (item['quantity'] as num?)?.toInt() ?? 0;
        final price = (item['price'] as num?)?.toInt() ?? 0;
        final variantInfo = (item['variant_info'] ?? '').toString();
        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item['product_name']?.toString() ?? '', style: const TextStyle(fontSize: 13)),
                if (variantInfo.isNotEmpty)
                  Text(variantInfo, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ])),
              SizedBox(width: 30, child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('×$qty', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
              )),
              SizedBox(width: 64, child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(fmtTien(price), textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              )),
              SizedBox(width: 64, child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(fmtTien(price * qty), textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              )),
            ]),
          ),
          if (i < items.length - 1)
            const Divider(height: 1, color: AppColors.divider, indent: 14, endIndent: 14),
        ]);
      }),
    ]);
  }
}

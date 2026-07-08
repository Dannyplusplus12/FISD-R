import 'package:dio/dio.dart';
import 'package:fisd_shared/fisd_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/api/api_client.dart';
import '../../core/session/phien_lam_viec.dart';
import '../../core/theme.dart';
import '../xac_thuc/xac_thuc_provider.dart';
import 'don_hang_orderer_provider.dart';
import 'tao_don_page.dart';

const _boLocNhan = ['Hôm nay', 'Tuần', 'Tháng', 'Tất cả'];
const _boLocNgay = [1, 7, 30, 0];

class DonHangOrdererPage extends ConsumerWidget {
  final PhienLamViec phien;
  const DonHangOrdererPage({super.key, required this.phien});

  List<Map> _locTheoThoiGian(List<Map<String, dynamic>> list, int ngay) {
    if (ngay == 0) return list;
    final gioi = DateTime.now().subtract(Duration(days: ngay));
    return list.where((don) {
      final s = (don['created_at'] ?? '') as String;
      if (s.isEmpty) return true;
      try {
        return DateTime.parse(s.replaceFirst(' ', 'T')).isAfter(gioi);
      } catch (_) {
        return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(donHangOrdererProvider(phien.id));
    final filterIdx = ref.watch(donHangFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Đơn hàng', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => ref.invalidate(donHangOrdererProvider(phien.id)),
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Đăng xuất',
            onPressed: () => ref.read(xacThucProvider.notifier).dangXuat(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _taoDon(context, ref),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tạo đơn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
                selected: filterIdx == i,
                onSelected: (_) => ref.read(donHangFilterProvider.notifier).state = i,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                    color: filterIdx == i ? Colors.white : AppColors.textSecondary,
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
          error: (e, _) => errorState(() => ref.invalidate(donHangOrdererProvider(phien.id))),
          data: (list) {
            final filtered = _locTheoThoiGian(list, _boLocNgay[filterIdx]);
            if (filtered.isEmpty) {
              return emptyState(Icons.receipt_long_outlined,
                  list.isEmpty ? 'Chưa có đơn nào' : 'Không có đơn trong khoảng thời gian này',
                  sub: list.isEmpty ? 'Nhấn + để tạo đơn mới' : null);
            }
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(donHangOrdererProvider(phien.id)),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: filtered.length,
                itemBuilder: (_, i) => _DonOrdererCard(don: filtered[i], phienId: phien.id),
              ),
            );
          },
        )),
      ]),
    );
  }

  Future<void> _taoDon(BuildContext ctx, WidgetRef ref) async {
    final ok = await Navigator.push<bool>(
        ctx, MaterialPageRoute(builder: (_) => TaoDonPage(phien: phien)));
    if (ok == true) ref.invalidate(donHangOrdererProvider(phien.id));
  }
}

// ── Card đơn của orderer ──────────────────────────────────────────────────────

class _DonOrdererCard extends StatefulWidget {
  final Map don;
  final int phienId;
  const _DonOrdererCard({required this.don, required this.phienId});

  @override
  State<_DonOrdererCard> createState() => _DonOrdererCardState();
}

class _DonOrdererCardState extends State<_DonOrdererCard> {
  bool _expanded = false;
  late List<String> _photos;
  late List<String> _photoKeys;
  bool _dangLuu = false;

  @override
  void initState() {
    super.initState();
    _photos = (widget.don['delivery_photo_paths'] as List? ?? []).cast<String>();
    _photoKeys = List<String>.from(widget.don['delivery_photo_keys'] as List? ?? []);
  }

  (String, Color) _statusInfo(String status) => switch (status) {
        'approved' => ('Chờ picker', AppColors.info),
        'assigned' => ('Đang giao', AppColors.warning),
        'completed' => ('Hoàn thành', AppColors.success),
        _ => ('Chờ duyệt', AppColors.textSecondary),
      };

  Future<void> _themAnhGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isEmpty || !mounted) return;
    await _uploadAnhs(picked.map((x) => x.path).toList());
  }

  Future<void> _chupCamera() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked == null || !mounted) return;
    await _uploadAnhs([picked.path]);
  }

  Future<void> _uploadAnhs(List<String> paths) async {
    if (!mounted) return;
    setState(() => _dangLuu = true);
    for (final path in paths) {
      final multi = MultipartFile.fromFileSync(path, filename: path.split('/').last);
      final form = FormData.fromMap({'picker_id': widget.phienId, 'photo': multi});
      final res = await ApiClient.dio.post(
        ApiEndpoints.themAnhDon(widget.don['id'] as int),
        data: form,
      );
      if (mounted) setState(() {
        _photos.add((res.data['url'] ?? '') as String);
        _photoKeys.add((res.data['key'] ?? '') as String);
      });
    }
    if (mounted) setState(() => _dangLuu = false);
  }

  Future<void> _xoaAnh(int idx) async {
    if (idx >= _photoKeys.length || _photoKeys[idx].isEmpty) return;
    setState(() => _dangLuu = true);
    await ApiClient.dio.delete(
      ApiEndpoints.xoaAnhDon(widget.don['id'] as int),
      queryParameters: {'picker_id': widget.phienId, 'key': _photoKeys[idx]},
    );
    if (mounted) setState(() {
      _photos.removeAt(idx);
      _photoKeys.removeAt(idx);
      _dangLuu = false;
    });
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
            onTap: () { Navigator.pop(context); _themAnhGallery(); },
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final don = widget.don;
    final status = don['status'] as String? ?? '';
    final items = (don['items'] as List? ?? []);
    final (label, mau) = _statusInfo(status);
    final pickerNote = (don['picker_note'] ?? '').toString().trim();
    final isCompleted = status == 'completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppDeco.card(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text('Đơn #${don["id"]}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 8),
                      _Badge(label: label, color: mau),
                    ]),
                    const SizedBox(height: 2),
                    Text(don['customer_name'] ?? 'Khách lẻ',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(don['created_at'] ?? '',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more, color: AppColors.textSecondary, size: 20),
                  ),
                ]),
              ]),
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 8),

              if (!_expanded) ...[
                ...items.take(2).map((item) => _ItemRow(item: item)),
                if (items.length > 2)
                  Text('+${items.length - 2} mặt hàng khác',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],

              if (_expanded) ...[
                ...items.map((item) => _ItemRow(item: item)),
                if (pickerNote.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: 8),
                  const Text('Ghi chú giao hàng',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(pickerNote,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
                if (isCompleted) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Text('Ảnh xác nhận',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const Spacer(),
                    if (_dangLuu)
                      const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                    else
                      InkWell(
                        onTap: _pilotChonAnh,
                        borderRadius: BorderRadius.circular(4),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.add_photo_alternate_outlined,
                              size: 18, color: AppColors.primary),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 8),
                  if (_photos.isEmpty)
                    const Text('Chưa có ảnh',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontStyle: FontStyle.italic))
                  else
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _photos.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) => Stack(children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(_photos[i],
                                width: 100, height: 100, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                    width: 100, height: 100,
                                    color: AppColors.background,
                                    child: const Icon(Icons.broken_image,
                                        color: AppColors.textSecondary))),
                          ),
                          if (i < _photoKeys.length && _photoKeys[i].isNotEmpty)
                            Positioned(
                              top: 4, right: 4,
                              child: GestureDetector(
                                onTap: () => _xoaAnh(i),
                                child: const CircleAvatar(
                                    radius: 10,
                                    backgroundColor: AppColors.danger,
                                    child: Icon(Icons.close, size: 12, color: Colors.white)),
                              ),
                            ),
                        ]),
                      ),
                    ),
                ] else if (!isCompleted && _photos.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: 8),
                  const Text('Ảnh xác nhận',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _photos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(_photos[i],
                            width: 100, height: 100, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                                width: 100, height: 100,
                                color: AppColors.background,
                                child: const Icon(Icons.broken_image,
                                    color: AppColors.textSecondary))),
                      ),
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(fmtTien(don["total_amount"]),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                if (status == 'assigned' && (don['assigned_picker_name'] ?? '').isNotEmpty)
                  Text('Picker: ${don["assigned_picker_name"]}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ]),
              if (status == 'completed' && (don['delivered_at'] ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Giao lúc ${don["delivered_at"]}',
                      style: const TextStyle(color: AppColors.success, fontSize: 12)),
                ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final dynamic item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(children: [
          const Icon(Icons.circle, size: 5, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
              child: Text('${item["product_name"]} ${item["variant_info"] ?? ""}',
                  style: const TextStyle(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)),
          Text('×${item["quantity"]}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ]),
      );
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

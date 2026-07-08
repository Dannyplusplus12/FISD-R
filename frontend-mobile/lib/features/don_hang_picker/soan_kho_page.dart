import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/api/api_client.dart';
import '../../core/session/phien_lam_viec.dart';
import 'draft_helper.dart';
import 'package:fisd_shared/fisd_shared.dart';

class SoanKhoPage extends StatefulWidget {
  final int donId;
  final PhienLamViec phien;

  const SoanKhoPage({super.key, required this.donId, required this.phien});

  @override
  State<SoanKhoPage> createState() => _SoanKhoPageState();
}

class _SoanKhoPageState extends State<SoanKhoPage> {
  DraftSoanKho? _draft;
  bool _loading = true;
  bool _hienOverlay = true;
  late PageController _pageCtrl;
  int _trangHienTai = 0;
  bool _dangGui = false;
  final _ghiChuCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _taiDraft();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _ghiChuCtrl.dispose();
    super.dispose();
  }

  Future<void> _taiDraft() async {
    // Thử load draft đã lưu
    var draft = await DraftSoanKho.tai(widget.donId);
    if (draft == null) {
      // Fetch từ API
      try {
        final res = await ApiClient.dio.get(ApiEndpoints.soanKho(widget.donId));
        final data = res.data as Map<String, dynamic>;
        final items = (data['items'] as List)
            .map((i) => DraftItem.fromApi(i as Map<String, dynamic>))
            .toList();
        draft = DraftSoanKho(
          orderId: widget.donId,
          customerName: (data['customer_name'] ?? '').toString(),
          items: items,
        );
        await draft.luu();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải đơn: $e'), backgroundColor: Colors.red));
          Navigator.pop(context);
        }
        return;
      }
    }
    if (mounted) {
      setState(() {
        _draft = draft;
        _ghiChuCtrl.text = draft!.ghiChu;
        _loading = false;
      });
    }
  }

  Future<void> _luuDraft() async {
    if (_draft == null) return;
    _draft!.ghiChu = _ghiChuCtrl.text;
    await _draft!.luu();
  }

  Future<void> _chupAnh() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isEmpty) return;
    setState(() {
      _draft!.anhPaths.addAll(picked.map((x) => x.path));
    });
    await _luuDraft();
  }

  Future<void> _chupCamera() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked == null) return;
    setState(() => _draft!.anhPaths.add(picked.path));
    await _luuDraft();
  }

  Future<void> _xoaAnh(int idx) async {
    setState(() => _draft!.anhPaths.removeAt(idx));
    await _luuDraft();
  }

  Future<void> _xacNhanGiao(BuildContext ctx) async {
    if (_draft == null) return;

    // Kiểm tra tất cả mặt hàng đã chọn kho
    final chuaChonIdx = _draft!.items.indexWhere((i) => i.selectedKhoId == null);
    if (chuaChonIdx >= 0) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
          content: Text('Vui lòng chọn kho cho tất cả mặt hàng'),
          backgroundColor: Colors.orange));
      _pageCtrl.animateToPage(chuaChonIdx,
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
      return;
    }

    if (_draft!.anhPaths.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Cần ít nhất 1 ảnh xác nhận'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _dangGui = true);
    try {
      final photos = _draft!.anhPaths
          .map((p) => MultipartFile.fromFileSync(p, filename: p.split('/').last))
          .toList();
      final items = _draft!.items.map((i) => {
        'order_item_id': i.orderItemId,
        'variant_id': i.variantId,
        'picked_qty': i.pickedQty,
      }).toList();

      final formData = FormData.fromMap({
        'picker_id': widget.phien.id,
        'items_json': '[${items.map((i) => '{"order_item_id":${i["order_item_id"]},"variant_id":${i["variant_id"]},"picked_qty":${i["picked_qty"]}}').join(',')}]',
        'picker_note': _ghiChuCtrl.text.trim(),
        'photos': photos,
      });
      await ApiClient.dio.put(ApiEndpoints.giaoKemAnh(widget.donId), data: formData);
      await DraftSoanKho.xoa(widget.donId);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã giao đơn #${widget.donId}')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _dangGui = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi giao hàng: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Colors.white)));
    }
    final draft = _draft!;
    final tongTrang = draft.items.length + 1; // items + trang xác nhận

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        // PageView
        PageView.builder(
          controller: _pageCtrl,
          itemCount: tongTrang,
          onPageChanged: (i) async {
            setState(() => _trangHienTai = i);
            await _luuDraft();
          },
          itemBuilder: (_, i) {
            if (i < draft.items.length) {
              return _ItemPage(
                item: draft.items[i],
                hienOverlay: _hienOverlay,
                onChanged: () async {
                  setState(() {});
                  await _luuDraft();
                },
              );
            }
            return _XacNhanPage(
              draft: draft,
              ghiChuCtrl: _ghiChuCtrl,
              dangGui: _dangGui,
              onChupAnh: _chupAnh,
              onChupCamera: _chupCamera,
              onXoaAnh: _xoaAnh,
              onXacNhan: () => _xacNhanGiao(context),
            );
          },
        ),

        // Top bar
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              // Nút X đóng overlay
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              // Tên đơn + khách
              Expanded(
                child: Text(
                  'Đơn #${widget.donId} • ${draft.customerName}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Page indicator
              Text(
                '${_trangHienTai + 1}/$tongTrang',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(width: 8),
              // Toggle overlay
              if (_trangHienTai < draft.items.length)
                GestureDetector(
                  onTap: () => setState(() => _hienOverlay = !_hienOverlay),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: _hienOverlay ? Colors.white24 : Colors.black54,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Icon(
                      _hienOverlay ? Icons.layers : Icons.layers_outlined,
                      color: Colors.white, size: 20,
                    ),
                  ),
                ),
            ]),
          ),
        ),

        // Dot indicator ở dưới
        Positioned(
          bottom: 12,
          left: 0, right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(tongTrang, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _trangHienTai == i ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _trangHienTai == i ? Colors.white : Colors.white38,
                borderRadius: BorderRadius.circular(3),
              ),
            )),
          ),
        ),
      ]),
    );
  }
}

// ── Trang từng mặt hàng ───────────────────────────────────────────────────────

class _ItemPage extends StatelessWidget {
  final DraftItem item;
  final bool hienOverlay;
  final VoidCallback onChanged;

  const _ItemPage({required this.item, required this.hienOverlay, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      // Ảnh sản phẩm full screen
      item.image.isNotEmpty
          ? Image.network(item.image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _anhTrong())
          : _anhTrong(),

      // Gradient phía dưới
      if (hienOverlay)
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.transparent, Colors.black87],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

      // Bottom overlay: kho + số lượng
      if (hienOverlay)
        Positioned(
          bottom: 36, left: 0, right: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chips kho hàng
                if (item.warehouses.isEmpty)
                  const Text('Chưa có kho nào', style: TextStyle(color: Colors.white60, fontSize: 13))
                else
                  Wrap(
                    spacing: 8,
                    children: item.warehouses.map((kho) {
                      final selected = item.selectedKhoId == kho['id'];
                      return GestureDetector(
                        onTap: () {
                          item.selectedKhoId = selected ? null : kho['id'] as int;
                          item.selectedKhoTen = selected ? null : kho['ten'] as String;
                          onChanged();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? Colors.white : Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: selected ? Colors.white : Colors.white54, width: 1.5),
                          ),
                          child: Text(
                            kho['ten'] as String,
                            style: TextStyle(
                              color: selected ? Colors.black : Colors.white,
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 12),

                // Tên + số lượng
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.productName,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (item.variantInfo.isNotEmpty)
                            Text(item.variantInfo, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                    // +/- số lượng
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        _nutSoLuong(Icons.remove, () {
                          if (item.pickedQty > 0) { item.pickedQty--; onChanged(); }
                        }),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '${item.pickedQty}',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        _nutSoLuong(Icons.add, () {
                          if (item.pickedQty < item.maxQty) { item.pickedQty++; onChanged(); }
                        }),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
    ]);
  }

  Widget _anhTrong() => Container(
    color: Colors.grey.shade900,
    child: const Center(child: Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 80)),
  );

  Widget _nutSoLuong(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      child: Icon(icon, color: Colors.white, size: 20),
    ),
  );
}

// ── Trang xác nhận ────────────────────────────────────────────────────────────

class _XacNhanPage extends StatelessWidget {
  final DraftSoanKho draft;
  final TextEditingController ghiChuCtrl;
  final bool dangGui;
  final VoidCallback onChupAnh;
  final VoidCallback onChupCamera;
  final void Function(int) onXoaAnh;
  final VoidCallback onXacNhan;

  const _XacNhanPage({
    required this.draft,
    required this.ghiChuCtrl,
    required this.dangGui,
    required this.onChupAnh,
    required this.onChupCamera,
    required this.onXoaAnh,
    required this.onXacNhan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A2E),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
          children: [
            const Text('Xác nhận giao hàng', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('${draft.items.length} mặt hàng', style: const TextStyle(color: Colors.white60)),
            const SizedBox(height: 20),

            // Tóm tắt items
            ...draft.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.productName, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                  Text(item.variantInfo, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('${item.pickedQty}/${item.maxQty}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  if (item.selectedKhoTen != null)
                    Text(item.selectedKhoTen!, style: const TextStyle(color: Colors.blue, fontSize: 12))
                  else
                    const Text('Chưa chọn kho', style: TextStyle(color: Colors.orange, fontSize: 12)),
                ]),
              ]),
            )),

            const Divider(color: Colors.white24, height: 28),

            // Ảnh xác nhận
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Ảnh xác nhận', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              Row(children: [
                TextButton.icon(
                  onPressed: onChupCamera,
                  icon: const Icon(Icons.camera_alt, color: Colors.white70, size: 18),
                  label: const Text('Camera', style: TextStyle(color: Colors.white70)),
                ),
                TextButton.icon(
                  onPressed: onChupAnh,
                  icon: const Icon(Icons.add_photo_alternate, color: Colors.white70, size: 18),
                  label: const Text('Thư viện', style: TextStyle(color: Colors.white70)),
                ),
              ]),
            ]),
            if (draft.anhPaths.isEmpty)
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange, width: 1.5),
                ),
                child: const Center(child: Text('Bắt buộc thêm ít nhất 1 ảnh', style: TextStyle(color: Colors.orange, fontSize: 13))),
              )
            else
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: draft.anhPaths.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => Stack(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(File(draft.anhPaths[i]), width: 100, height: 100, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(width: 100, height: 100, color: Colors.white12,
                              child: const Icon(Icons.broken_image, color: Colors.white30))),
                    ),
                    Positioned(top: 4, right: 4, child: GestureDetector(
                      onTap: () => onXoaAnh(i),
                      child: const CircleAvatar(radius: 10, backgroundColor: Colors.red, child: Icon(Icons.close, size: 12, color: Colors.white)),
                    )),
                  ]),
                ),
              ),

            const SizedBox(height: 16),

            // Ghi chú
            const Text('Ghi chú', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: ghiChuCtrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ghi chú giao hàng...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),

            // Nút xác nhận
            ElevatedButton(
              onPressed: dangGui ? null : onXacNhan,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                disabledBackgroundColor: Colors.green.withOpacity(0.5),
              ),
              child: dangGui
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Xác nhận giao hàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

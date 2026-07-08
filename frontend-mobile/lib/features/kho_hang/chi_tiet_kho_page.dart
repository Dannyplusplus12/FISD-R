import 'package:fisd_shared/fisd_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'kho_hang_provider.dart';
import 'kho_hang_repository.dart';

class ChiTietKhoPage extends ConsumerStatefulWidget {
  final KhoHang kho;
  const ChiTietKhoPage({super.key, required this.kho});

  @override
  ConsumerState<ChiTietKhoPage> createState() => _ChiTietKhoPageState();
}

class _ChiTietKhoPageState extends ConsumerState<ChiTietKhoPage> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sanPhamTrongKhoProvider(widget.kho.id));
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.kho.ten),
            if (widget.kho.viTri.isNotEmpty)
              Text(widget.kho.viTri, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _themBienThe(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm hàng'),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: TextButton(
          onPressed: () => ref.invalidate(sanPhamTrongKhoProvider(widget.kho.id)),
          child: const Text('Lỗi — thử lại'),
        )),
        data: (sanPhams) {
          if (sanPhams.isEmpty) {
            return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey),
              SizedBox(height: 12),
              Text('Kho trống', style: TextStyle(color: Colors.grey)),
              SizedBox(height: 4),
              Text('Nhấn + để thêm hàng vào kho', style: TextStyle(color: Colors.grey, fontSize: 13)),
            ]));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(sanPhamTrongKhoProvider(widget.kho.id)),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
              itemCount: sanPhams.length,
              itemBuilder: (_, i) => _SanPhamTrongKhoCard(
                sp: sanPhams[i],
                khoId: widget.kho.id,
                onChanged: () => ref.invalidate(sanPhamTrongKhoProvider(widget.kho.id)),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _themBienThe(BuildContext ctx) async {
    // Lấy tất cả sản phẩm rồi cho chọn biến thể chưa có trong kho này
    final allSps = await ref.read(khoHangRepoProvider).laySanPhams();
    if (!ctx.mounted) return;
    await showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      builder: (_) => _ChonBienThePage(khoId: widget.kho.id, allSps: allSps),
    );
    ref.invalidate(sanPhamTrongKhoProvider(widget.kho.id));
  }
}

// ── Card sản phẩm trong kho ──────────────────────────────────────────────────

class _SanPhamTrongKhoCard extends ConsumerWidget {
  final Map<String, dynamic> sp;
  final int khoId;
  final VoidCallback onChanged;

  const _SanPhamTrongKhoCard({required this.sp, required this.khoId, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bienThes = (sp['bien_thes'] as List? ?? []).cast<Map<String, dynamic>>();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header sản phẩm
          Row(children: [
            if ((sp['image'] as String? ?? '').isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(sp['image'] as String, width: 44, height: 44, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _iconSP()),
              )
            else _iconSP(),
            const SizedBox(width: 10),
            Expanded(child: Text(sp['ten'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
          ]),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Biến thể
          ...bienThes.map((bt) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_tenBienThe(bt), style: const TextStyle(fontWeight: FontWeight.w500)),
                Text('Giá: ${_fmt(bt["don_gia"] as int)}đ', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ])),
              // Số lượng trong kho này
              Row(children: [
                _nutSL(Icons.remove, () => _thayDoiSL(context, ref, bt, -1)),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${bt["so_luong"]}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                _nutSL(Icons.add, () => _thayDoiSL(context, ref, bt, 1)),
              ]),
              const SizedBox(width: 4),
              // Xóa khỏi kho
              GestureDetector(
                onTap: () => _xoaKhoiBienThe(context, ref, bt),
                child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              ),
            ]),
          )),
        ]),
      ),
    );
  }

  Future<void> _thayDoiSL(BuildContext ctx, WidgetRef ref, Map bt, int delta) async {
    final soLuongMoi = ((bt['so_luong'] as int) + delta).clamp(0, 9999);
    await ref.read(khoHangRepoProvider).capNhatSoLuongBienTheKho(khoId, bt['id'] as int, soLuongMoi);
    onChanged();
  }

  Future<void> _xoaKhoiBienThe(BuildContext ctx, WidgetRef ref, Map bt) async {
    final ok = await showDialog<bool>(context: ctx, builder: (_) => AlertDialog(
      title: const Text('Xóa khỏi kho?'),
      content: Text('Xóa "${_tenBienThe(bt)}" khỏi kho này?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
      ],
    ));
    if (ok == true) {
      await ref.read(khoHangRepoProvider).xoaBienTheKhoiKho(khoId, bt['id'] as int);
      onChanged();
    }
  }

  String _tenBienThe(Map bt) {
    final parts = [if ((bt['mau_sac'] as String).isNotEmpty) bt['mau_sac'], if ((bt['kich_co'] as String).isNotEmpty) bt['kich_co']];
    return parts.isEmpty ? 'Mặc định' : parts.join(' / ');
  }

  Widget _iconSP() => Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
      child: const Icon(Icons.inventory_2_outlined, color: Colors.grey));

  Widget _nutSL(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32, height: 32,
      decoration: BoxDecoration(color: const Color(0xFF1A1A2E).withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, size: 18, color: const Color(0xFF1A1A2E)),
    ),
  );

  String _fmt(int v) => v.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

// ── Chọn biến thể để thêm vào kho ────────────────────────────────────────────

class _ChonBienThePage extends ConsumerStatefulWidget {
  final int khoId;
  final List<SanPham> allSps;
  const _ChonBienThePage({required this.khoId, required this.allSps});

  @override
  ConsumerState<_ChonBienThePage> createState() => _ChonBienThePageState();
}

class _ChonBienThePageState extends ConsumerState<_ChonBienThePage> {
  String _search = '';
  final Map<int, int> _soLuongMap = {}; // btId → soLuong nhập
  final Set<int> _dangThem = {};

  @override
  Widget build(BuildContext context) {
    final filtered = widget.allSps.where((sp) => sp.ten.toLowerCase().contains(_search.toLowerCase())).toList();
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (_, ctrl) => Column(children: [
        const SizedBox(height: 8),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'Tìm sản phẩm...',
              prefixIcon: const Icon(Icons.search),
              filled: true, fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: ListView.builder(
          controller: ctrl,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: filtered.length,
          itemBuilder: (_, i) {
            final sp = filtered[i];
            return ExpansionTile(
              title: Text(sp.ten, style: const TextStyle(fontWeight: FontWeight.w600)),
              children: sp.bienThes.map((bt) {
                if (bt.id == null) return const SizedBox();
                final sl = _soLuongMap[bt.id!] ?? 0;
                final dangThem = _dangThem.contains(bt.id!);
                return ListTile(
                  title: Text(bt.tenHienThi),
                  subtitle: Text('Giá: ${bt.gia}đ'),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(
                      width: 60,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          hintText: 'SL',
                          filled: true, fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        onChanged: (v) => setState(() => _soLuongMap[bt.id!] = int.tryParse(v) ?? 0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    dangThem
                        ? const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 2))
                        : IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.green),
                            onPressed: () => _them(bt.id!, sl),
                          ),
                  ]),
                );
              }).toList(),
            );
          },
        )),
      ]),
    );
  }

  Future<void> _them(int btId, int soLuong) async {
    setState(() => _dangThem.add(btId));
    try {
      await ref.read(khoHangRepoProvider).themBienTheVaoKho(widget.khoId, btId, soLuong);
      if (mounted) {
        setState(() => _dangThem.remove(btId));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã thêm vào kho')));
      }
    } catch (_) {
      if (mounted) setState(() => _dangThem.remove(btId));
    }
  }
}

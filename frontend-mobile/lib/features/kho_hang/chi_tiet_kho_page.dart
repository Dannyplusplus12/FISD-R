import 'package:fisd_shared/fisd_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import 'kho_hang_provider.dart';

class ChiTietKhoPage extends ConsumerStatefulWidget {
  final KhoHang kho;
  final bool readOnly;
  const ChiTietKhoPage({super.key, required this.kho, this.readOnly = false});

  @override
  ConsumerState<ChiTietKhoPage> createState() => _ChiTietKhoPageState();
}

class _ChiTietKhoPageState extends ConsumerState<ChiTietKhoPage> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sanPhamTrongKhoProvider(widget.kho.id));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.kho.ten, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (widget.kho.viTri.isNotEmpty)
            Text(widget.kho.viTri,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.textSecondary)),
        ]),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      floatingActionButton: widget.readOnly
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _themBienThe(context),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Thêm hàng', style: TextStyle(color: Colors.white)),
            ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => errorState(() => ref.invalidate(sanPhamTrongKhoProvider(widget.kho.id))),
        data: (sanPhams) {
          if (sanPhams.isEmpty) {
            return emptyState(Icons.inventory_2_outlined, 'Kho trống',
                sub: widget.readOnly ? null : 'Nhấn + để thêm hàng vào kho');
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(sanPhamTrongKhoProvider(widget.kho.id)),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: sanPhams.length,
              itemBuilder: (_, i) => _SanPhamCard(
                sp: sanPhams[i],
                khoId: widget.kho.id,
                readOnly: widget.readOnly,
                onChanged: () => ref.invalidate(sanPhamTrongKhoProvider(widget.kho.id)),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _themBienThe(BuildContext ctx) async {
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

class _SanPhamCard extends ConsumerWidget {
  final Map<String, dynamic> sp;
  final int khoId;
  final bool readOnly;
  final VoidCallback onChanged;

  const _SanPhamCard({
    required this.sp,
    required this.khoId,
    required this.readOnly,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bienThes = (sp['bien_thes'] as List? ?? []).cast<Map<String, dynamic>>();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppDeco.card(),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if ((sp['image'] as String? ?? '').isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(sp['image'] as String,
                    width: 44, height: 44, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _iconSP()),
              )
            else
              _iconSP(),
            const SizedBox(width: 10),
            Expanded(
                child: Text(sp['ten'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
          ]),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),
          ...bienThes.map((bt) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_tenBienThe(bt),
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                    Text('${fmtTien(bt["don_gia"] as int)}đ',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ])),
                  if (readOnly)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${bt["so_luong"]}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    )
                  else ...[
                    _nutSL(Icons.remove, () => _thayDoiSL(ref, bt, -1)),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                          color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                      child: Text('${bt["so_luong"]}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    _nutSL(Icons.add, () => _thayDoiSL(ref, bt, 1)),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _xoaKhoiBienThe(context, ref, bt),
                      child: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                    ),
                  ],
                ]),
              )),
        ]),
      ),
    );
  }

  Future<void> _thayDoiSL(WidgetRef ref, Map bt, int delta) async {
    final soLuongMoi = ((bt['so_luong'] as int) + delta).clamp(0, 9999);
    await ref.read(khoHangRepoProvider).capNhatSoLuongBienTheKho(khoId, bt['id'] as int, soLuongMoi);
    onChanged();
  }

  Future<void> _xoaKhoiBienThe(BuildContext ctx, WidgetRef ref, Map bt) async {
    final ok = await showDialog<bool>(
        context: ctx,
        builder: (_) => AlertDialog(
              title: const Text('Xóa khỏi kho?'),
              content: Text('Xóa "${_tenBienThe(bt)}" khỏi kho này?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Xóa', style: TextStyle(color: AppColors.danger))),
              ],
            ));
    if (ok == true) {
      await ref.read(khoHangRepoProvider).xoaBienTheKhoiKho(khoId, bt['id'] as int);
      onChanged();
    }
  }

  String _tenBienThe(Map bt) {
    final parts = [
      if ((bt['mau_sac'] as String).isNotEmpty) bt['mau_sac'],
      if ((bt['kich_co'] as String).isNotEmpty) bt['kich_co']
    ];
    return parts.isEmpty ? 'Mặc định' : parts.join(' / ');
  }

  Widget _iconSP() => Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
      child: const Icon(Icons.inventory_2_outlined, color: AppColors.textSecondary));

  Widget _nutSL(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
      );
}

class _ChonBienThePage extends ConsumerStatefulWidget {
  final int khoId;
  final List<SanPham> allSps;
  const _ChonBienThePage({required this.khoId, required this.allSps});

  @override
  ConsumerState<_ChonBienThePage> createState() => _ChonBienThePageState();
}

class _ChonBienThePageState extends ConsumerState<_ChonBienThePage> {
  String _search = '';
  final Map<int, int> _soLuongMap = {};
  final Set<int> _dangThem = {};

  @override
  Widget build(BuildContext context) {
    final filtered = widget.allSps
        .where((sp) => sp.ten.toLowerCase().contains(_search.toLowerCase()))
        .toList();
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (_, ctrl) => Column(children: [
        const SizedBox(height: 8),
        Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: AppDeco.input('Tìm sản phẩm...', icon: Icons.search),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
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
                    subtitle: Text('${fmtTien(bt.gia)}đ'),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      SizedBox(
                        width: 60,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: AppDeco.input('SL'),
                          onChanged: (v) =>
                              setState(() => _soLuongMap[bt.id!] = int.tryParse(v) ?? 0),
                        ),
                      ),
                      const SizedBox(width: 8),
                      dangThem
                          ? const SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : IconButton(
                              icon: const Icon(Icons.add_circle, color: AppColors.success),
                              onPressed: () => _them(bt.id!, sl),
                            ),
                    ]),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ]),
    );
  }

  Future<void> _them(int btId, int soLuong) async {
    setState(() => _dangThem.add(btId));
    try {
      await ref.read(khoHangRepoProvider).themBienTheVaoKho(widget.khoId, btId, soLuong);
      if (mounted) {
        setState(() => _dangThem.remove(btId));
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Đã thêm vào kho')));
      }
    } catch (_) {
      if (mounted) setState(() => _dangThem.remove(btId));
    }
  }
}

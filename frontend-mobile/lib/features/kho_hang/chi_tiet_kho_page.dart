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
  String _search = '';

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
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: AppColors.textSecondary)),
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
        error: (_, __) =>
            errorState(() => ref.invalidate(sanPhamTrongKhoProvider(widget.kho.id))),
        data: (sanPhams) {
          if (sanPhams.isEmpty) {
            return emptyState(Icons.inventory_2_outlined, 'Kho trống',
                sub: widget.readOnly ? null : 'Nhấn + để thêm hàng vào kho');
          }

          final filtered = _search.isEmpty
              ? sanPhams
              : sanPhams
                  .where((sp) => (sp['ten'] as String)
                      .toLowerCase()
                      .contains(_search.toLowerCase()))
                  .toList();

          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: AppDeco.input('Tìm sản phẩm...', icon: Icons.search),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(sanPhamTrongKhoProvider(widget.kho.id)),
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _SanPhamTile(
                    sp: filtered[i],
                    khoId: widget.kho.id,
                    readOnly: widget.readOnly,
                    onChanged: () =>
                        ref.invalidate(sanPhamTrongKhoProvider(widget.kho.id)),
                  ),
                ),
              ),
            ),
          ]);
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

// ── Grid tile ─────────────────────────────────────────────────────────────────

class _SanPhamTile extends ConsumerWidget {
  final Map<String, dynamic> sp;
  final int khoId;
  final bool readOnly;
  final VoidCallback onChanged;

  const _SanPhamTile({
    required this.sp,
    required this.khoId,
    required this.readOnly,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bienThes = (sp['bien_thes'] as List? ?? []).cast<Map<String, dynamic>>();
    final tongSL = bienThes.fold<int>(0, (s, bt) => s + (bt['so_luong'] as int? ?? 0));
    final gia = bienThes.isNotEmpty ? fmtTien(bienThes.first['don_gia'] as int) : '—';
    final imageUrl = sp['image'] as String? ?? '';
    final ten = sp['ten'] as String;

    return GestureDetector(
      onTap: () => _moChiTiet(context, ref, bienThes),
      child: Container(
        decoration: AppDeco.card(),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Ảnh ──────────────────────────────────────────────
          Expanded(
            child: Stack(fit: StackFit.expand, children: [
              imageUrl.isNotEmpty
                  ? Image.network(imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),
              // Badge số lượng góc trên phải
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: tongSL > 0 ? AppColors.primary : AppColors.danger,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$tongSL',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ]),
          ),
          // ── Info ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ten,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(gia,
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.background,
        child: const Center(
          child: Icon(Icons.inventory_2_outlined,
              size: 48, color: AppColors.divider),
        ),
      );

  void _moChiTiet(BuildContext ctx, WidgetRef ref, List<Map<String, dynamic>> bienThes) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BienTheSheet(
        sp: sp,
        khoId: khoId,
        bienThes: bienThes,
        readOnly: readOnly,
        onChanged: onChanged,
        ref: ref,
      ),
    );
  }
}

// ── Bottom sheet biến thể ─────────────────────────────────────────────────────

class _BienTheSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> sp;
  final int khoId;
  final List<Map<String, dynamic>> bienThes;
  final bool readOnly;
  final VoidCallback onChanged;
  final WidgetRef ref;

  const _BienTheSheet({
    required this.sp,
    required this.khoId,
    required this.bienThes,
    required this.readOnly,
    required this.onChanged,
    required this.ref,
  });

  @override
  ConsumerState<_BienTheSheet> createState() => _BienTheSheetState();
}

class _BienTheSheetState extends ConsumerState<_BienTheSheet> {
  late List<Map<String, dynamic>> _bienThes;

  @override
  void initState() {
    super.initState();
    _bienThes = List.from(widget.bienThes);
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.sp['image'] as String? ?? '';
    final ten = widget.sp['ten'] as String;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          const SizedBox(height: 8),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          // Header: ảnh nhỏ + tên
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _thumbPlaceholder())
                    : _thumbPlaceholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(ten,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 17))),
            ]),
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: AppColors.divider),
          Expanded(
            child: ListView.builder(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _bienThes.length,
              itemBuilder: (_, i) => _BienTheRow(
                bt: _bienThes[i],
                khoId: widget.khoId,
                readOnly: widget.readOnly,
                onSoLuongChanged: (newSL) {
                  setState(() => _bienThes[i] = {..._bienThes[i], 'so_luong': newSL});
                  widget.onChanged();
                },
                onXoa: () {
                  setState(() => _bienThes.removeAt(i));
                  widget.onChanged();
                },
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _thumbPlaceholder() => Container(
      width: 56,
      height: 56,
      color: AppColors.background,
      child: const Icon(Icons.inventory_2_outlined,
          color: AppColors.textSecondary, size: 24));
}

class _BienTheRow extends ConsumerWidget {
  final Map<String, dynamic> bt;
  final int khoId;
  final bool readOnly;
  final ValueChanged<int> onSoLuongChanged;
  final VoidCallback onXoa;

  const _BienTheRow({
    required this.bt,
    required this.khoId,
    required this.readOnly,
    required this.onSoLuongChanged,
    required this.onXoa,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ten = _tenBienThe();
    final gia = fmtTien(bt['don_gia'] as int);
    final soLuong = bt['so_luong'] as int;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(ten, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          Text(gia, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ])),
        if (readOnly)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10)),
            child: Text('$soLuong',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          )
        else ...[
          _nutSL(Icons.remove, () => _doi(ref, soLuong, -1)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10)),
            child: Text('$soLuong',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          _nutSL(Icons.add, () => _doi(ref, soLuong, 1)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _xoa(context, ref),
            child: const Icon(Icons.delete_outline,
                color: AppColors.danger, size: 22),
          ),
        ],
      ]),
    );
  }

  Future<void> _doi(WidgetRef ref, int cur, int delta) async {
    final moi = (cur + delta).clamp(0, 9999);
    await ref
        .read(khoHangRepoProvider)
        .capNhatSoLuongBienTheKho(khoId, bt['id'] as int, moi);
    onSoLuongChanged(moi);
  }

  Future<void> _xoa(BuildContext ctx, WidgetRef ref) async {
    final ok = await showDialog<bool>(
        context: ctx,
        builder: (_) => AlertDialog(
              title: const Text('Xóa khỏi kho?'),
              content: Text('Xóa "${_tenBienThe()}" khỏi kho này?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Huỷ')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Xóa',
                        style: TextStyle(color: AppColors.danger))),
              ],
            ));
    if (ok == true) {
      await ref
          .read(khoHangRepoProvider)
          .xoaBienTheKhoiKho(khoId, bt['id'] as int);
      onXoa();
    }
  }

  String _tenBienThe() {
    final parts = [
      if ((bt['mau_sac'] as String).isNotEmpty) bt['mau_sac'],
      if ((bt['kich_co'] as String).isNotEmpty) bt['kich_co'],
    ];
    return parts.isEmpty ? 'Mặc định' : parts.join(' / ');
  }

  Widget _nutSL(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
      );
}

// ── Chọn biến thể để thêm vào kho ───────────────────────────────────────────

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
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          const SizedBox(height: 8),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2))),
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
                  title:
                      Text(sp.ten, style: const TextStyle(fontWeight: FontWeight.w600)),
                  children: sp.bienThes.map((bt) {
                    if (bt.id == null) return const SizedBox();
                    final sl = _soLuongMap[bt.id!] ?? 0;
                    final dangThem = _dangThem.contains(bt.id!);
                    return ListTile(
                      title: Text(bt.tenHienThi),
                      subtitle: Text(fmtTien(bt.gia)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        SizedBox(
                          width: 60,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration: AppDeco.input('SL'),
                            onChanged: (v) => setState(
                                () => _soLuongMap[bt.id!] = int.tryParse(v) ?? 0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        dangThem
                            ? const SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : IconButton(
                                icon: const Icon(Icons.add_circle,
                                    color: AppColors.success),
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
      ),
    );
  }

  Future<void> _them(int btId, int soLuong) async {
    setState(() => _dangThem.add(btId));
    try {
      await ref
          .read(khoHangRepoProvider)
          .themBienTheVaoKho(widget.khoId, btId, soLuong);
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

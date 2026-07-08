import 'dart:async';
import 'package:fisd_shared/fisd_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../orderer/san_pham_orderer_page.dart';
import '../orderer/san_pham_orderer_provider.dart';
import 'kho_hang_provider.dart';

class ChiTietKhoPage extends ConsumerStatefulWidget {
  final KhoHang kho;
  const ChiTietKhoPage({super.key, required this.kho});

  @override
  ConsumerState<ChiTietKhoPage> createState() => _ChiTietKhoPageState();
}

class _ChiTietKhoPageState extends ConsumerState<ChiTietKhoPage> {
  String _search = '';

  void _refresh() => ref.invalidate(sanPhamTrongKhoProvider(widget.kho.id));

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
                    fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.textSecondary)),
        ]),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: AppColors.divider)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _themHang(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm hàng', style: TextStyle(color: Colors.white)),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => errorState(_refresh),
        data: (sanPhams) {
          if (sanPhams.isEmpty) {
            return emptyState(Icons.inventory_2_outlined, 'Kho trống',
                sub: 'Nhấn + để thêm hàng vào kho');
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
                onRefresh: () async => _refresh(),
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
                    onChanged: _refresh,
                  ),
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }

  Future<void> _themHang(BuildContext ctx) async {
    final allSps = await ref.read(khoHangRepoProvider).laySanPhams();
    if (!ctx.mounted) return;
    await showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChonHangSheet(khoId: widget.kho.id, allSps: allSps),
    );
    _refresh();
  }
}

// ── Grid tile ─────────────────────────────────────────────────────────────────

class _SanPhamTile extends StatelessWidget {
  final Map<String, dynamic> sp;
  final int khoId;
  final VoidCallback onChanged;

  const _SanPhamTile({required this.sp, required this.khoId, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final bienThes = (sp['bien_thes'] as List? ?? []).cast<Map<String, dynamic>>();
    final tongSL = bienThes.fold<int>(0, (s, bt) => s + (bt['so_luong'] as int? ?? 0));
    final gia = bienThes.isNotEmpty ? fmtTien(bienThes.first['don_gia'] as int) : '—';
    final imageUrl = sp['image'] as String? ?? '';

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _SanPhamSheet(sp: sp, khoId: khoId, onChanged: onChanged),
      ),
      child: Container(
        decoration: AppDeco.card(),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Stack(fit: StackFit.expand, children: [
              imageUrl.isNotEmpty
                  ? Image.network(imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),
              Positioned(
                top: 8, right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: tongSL > 0 ? AppColors.primary : AppColors.danger,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$tongSL',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(sp['ten'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(gia,
                  style: const TextStyle(
                      color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _placeholder() => Container(
      color: AppColors.background,
      child: const Center(
          child: Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.divider)));
}

// ── Bottom sheet sản phẩm ─────────────────────────────────────────────────────

class _SanPhamSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> sp;
  final int khoId;
  final VoidCallback onChanged;

  const _SanPhamSheet({required this.sp, required this.khoId, required this.onChanged});

  @override
  ConsumerState<_SanPhamSheet> createState() => _SanPhamSheetState();
}

class _SanPhamSheetState extends ConsumerState<_SanPhamSheet> {
  late List<Map<String, dynamic>> _bienThes;

  @override
  void initState() {
    super.initState();
    _bienThes = List<Map<String, dynamic>>.from(
        (widget.sp['bien_thes'] as List? ?? []).cast<Map<String, dynamic>>());
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.sp['image'] as String? ?? '';
    final ten = widget.sp['ten'] as String;
    final spId = widget.sp['id'] as int;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          const SizedBox(height: 8),
          Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl,
                        width: 54, height: 54, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _thumb())
                    : _thumb(),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(ten,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17))),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (v) {
                  if (v == 'sua_sp') _suaSanPham(context, spId);
                  if (v == 'them_bt') _themBienThe(context, spId);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'sua_sp',
                      child: Row(children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Sửa sản phẩm'),
                      ])),
                  const PopupMenuItem(value: 'them_bt',
                      child: Row(children: [
                        Icon(Icons.add_circle_outline, size: 18),
                        SizedBox(width: 8),
                        Text('Thêm biến thể'),
                      ])),
                ],
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.divider),
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: _bienThes.asMap().entries.map((e) => _BienTheRow(
                key: ValueKey(e.value['id'] ?? e.key),
                bt: e.value,
                khoId: widget.khoId,
                onSLChanged: (newSL) =>
                    setState(() => _bienThes[e.key] = {...e.value, 'so_luong': newSL}),
                onEdited: (updated) =>
                    setState(() => _bienThes[e.key] = {...e.value, ...updated}),
                onXoa: () {
                  setState(() => _bienThes.removeAt(e.key));
                  widget.onChanged();
                },
                onChanged: widget.onChanged,
              )).toList(),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _thumb() => Container(
      width: 54, height: 54,
      decoration:
          BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
      child:
          const Icon(Icons.inventory_2_outlined, color: AppColors.textSecondary, size: 24));

  Future<void> _suaSanPham(BuildContext ctx, int spId) async {
    final allSps = await ref.read(khoHangRepoProvider).laySanPhams();
    final sp = allSps.where((s) => s.id == spId).firstOrNull;
    if (sp == null || !ctx.mounted) return;
    await Navigator.push(ctx, MaterialPageRoute(builder: (_) => FormSanPhamPage(edit: sp)));
    ref.invalidate(sanPhamOrdererProvider);
    widget.onChanged();
  }

  Future<void> _themBienThe(BuildContext ctx, int spId) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: ctx,
      builder: (_) => const _FormBienTheDialog(),
    );
    if (result == null || !ctx.mounted) return;
    final repo = ref.read(khoHangRepoProvider);
    final newBt = await repo.themBienTheSanPham(
        spId, result['color']!, result['size']!, result['price']! as int);
    final btId = newBt['id'] as int;
    await repo.themBienTheVaoKho(widget.khoId, btId, result['so_luong'] as int);
    setState(() => _bienThes.add({
      'id': btId,
      'mau_sac': result['color'],
      'kich_co': result['size'],
      'don_gia': result['price'],
      'so_luong': result['so_luong'],
    }));
    widget.onChanged();
  }
}

// ── Row biến thể ──────────────────────────────────────────────────────────────

class _BienTheRow extends ConsumerStatefulWidget {
  final Map<String, dynamic> bt;
  final int khoId;
  final ValueChanged<int> onSLChanged;
  final ValueChanged<Map<String, dynamic>> onEdited;
  final VoidCallback onXoa;
  final VoidCallback onChanged;

  const _BienTheRow({
    super.key,
    required this.bt,
    required this.khoId,
    required this.onSLChanged,
    required this.onEdited,
    required this.onXoa,
    required this.onChanged,
  });

  @override
  ConsumerState<_BienTheRow> createState() => _BienTheRowState();
}

class _BienTheRowState extends ConsumerState<_BienTheRow> {
  late int _soLuong;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _soLuong = widget.bt['so_luong'] as int;
  }

  @override
  void didUpdateWidget(_BienTheRow old) {
    super.didUpdateWidget(old);
    // nếu parent reset lại dữ liệu (vd refresh), đồng bộ lại
    final newSL = widget.bt['so_luong'] as int;
    if (_debounce == null && newSL != _soLuong) {
      setState(() => _soLuong = newSL);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _doi(int delta) {
    final moi = (_soLuong + delta).clamp(0, 9999);
    setState(() => _soLuong = moi);
    widget.onSLChanged(moi);
    // debounce: gọi API sau 700ms không bấm tiếp
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () async {
      await ref.read(khoHangRepoProvider)
          .capNhatSoLuongBienTheKho(widget.khoId, widget.bt['id'] as int, moi);
      _debounce = null;
    });
  }

  String _ten() {
    final parts = [
      if ((widget.bt['mau_sac'] as String).isNotEmpty) widget.bt['mau_sac'],
      if ((widget.bt['kich_co'] as String).isNotEmpty) widget.bt['kich_co'],
    ];
    return parts.isEmpty ? 'Mặc định' : parts.join(' / ');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_ten(),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            Text(fmtTien(widget.bt['don_gia'] as int),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ]),
        ),
        _nut(Icons.remove, () => _doi(-1)),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
              color: AppColors.background, borderRadius: BorderRadius.circular(10)),
          child: Text('$_soLuong',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        _nut(Icons.add, () => _doi(1)),
        const SizedBox(width: 4),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
          onSelected: (v) {
            if (v == 'sua') _suaBienThe(context);
            if (v == 'xoa') _xoaBienThe(context);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'sua',
                child: Row(children: [
                  Icon(Icons.edit_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Sửa biến thể'),
                ])),
            const PopupMenuItem(value: 'xoa',
                child: Row(children: [
                  Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                  SizedBox(width: 8),
                  Text('Xóa', style: TextStyle(color: AppColors.danger)),
                ])),
          ],
        ),
      ]),
    );
  }

  Widget _nut(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
      );

  Future<void> _suaBienThe(BuildContext ctx) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: ctx,
      builder: (_) => _FormBienTheDialog(
        initColor: widget.bt['mau_sac'] as String,
        initSize: widget.bt['kich_co'] as String,
        initPrice: widget.bt['don_gia'] as int,
      ),
    );
    if (result == null) return;
    await ref.read(khoHangRepoProvider).capNhatBienThe(
        widget.bt['id'] as int, result['color']!, result['size']!, result['price']! as int);
    widget.onEdited({'mau_sac': result['color'], 'kich_co': result['size'], 'don_gia': result['price']});
    widget.onChanged();
  }

  Future<void> _xoaBienThe(BuildContext ctx) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Xóa biến thể?'),
        content: Text('Xóa "${_ten()}" hoàn toàn khỏi hệ thống?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Xóa', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(khoHangRepoProvider).xoaBienThe(widget.bt['id'] as int);
      widget.onXoa();
    }
  }
}

// ── Dialog form biến thể ──────────────────────────────────────────────────────

class _FormBienTheDialog extends StatefulWidget {
  final String initColor;
  final String initSize;
  final int initPrice; // VND

  const _FormBienTheDialog({this.initColor = '', this.initSize = '', this.initPrice = 0});

  @override
  State<_FormBienTheDialog> createState() => _FormBienTheDialogState();
}

class _FormBienTheDialogState extends State<_FormBienTheDialog> {
  late final TextEditingController _colorCtrl;
  late final TextEditingController _sizeCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _slCtrl;

  bool get _isNew => widget.initPrice == 0 && widget.initColor.isEmpty;

  @override
  void initState() {
    super.initState();
    _colorCtrl = TextEditingController(text: widget.initColor);
    _sizeCtrl = TextEditingController(text: widget.initSize);
    // Hiển thị theo đơn vị k
    _priceCtrl = TextEditingController(
        text: widget.initPrice > 0 ? '${widget.initPrice ~/ 1000}' : '');
    _slCtrl = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _colorCtrl.dispose();
    _sizeCtrl.dispose();
    _priceCtrl.dispose();
    _slCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isNew ? 'Thêm biến thể' : 'Sửa biến thể'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          controller: _colorCtrl,
          decoration:
              const InputDecoration(labelText: 'Màu sắc', hintText: 'vd: Đen, Trắng'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _sizeCtrl,
          decoration: const InputDecoration(labelText: 'Size', hintText: 'vd: 40, 41'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _priceCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
              labelText: 'Giá', suffixText: 'k', hintText: 'vd: 90'),
        ),
        if (_isNew) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _slCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Số lượng ban đầu'),
          ),
        ],
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
        TextButton(onPressed: _luu, child: const Text('Lưu')),
      ],
    );
  }

  void _luu() {
    Navigator.pop(context, {
      'color': _colorCtrl.text.trim(),
      'size': _sizeCtrl.text.trim(),
      'price': (int.tryParse(_priceCtrl.text) ?? 0) * 1000, // k → VND
      'so_luong': int.tryParse(_slCtrl.text) ?? 0,
    });
  }
}

// ── Chọn hàng để thêm vào kho ────────────────────────────────────────────────

class _ChonHangSheet extends ConsumerStatefulWidget {
  final int khoId;
  final List<SanPham> allSps;
  const _ChonHangSheet({required this.khoId, required this.allSps});

  @override
  ConsumerState<_ChonHangSheet> createState() => _ChonHangSheetState();
}

class _ChonHangSheetState extends ConsumerState<_ChonHangSheet> {
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
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
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
                      subtitle: Text(fmtTien(bt.gia)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        SizedBox(
                          width: 60,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: AppDeco.input('SL'),
                            onChanged: (v) => setState(
                                () => _soLuongMap[bt.id!] = int.tryParse(v) ?? 0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        dangThem
                            ? const SizedBox(
                                width: 32, height: 32,
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
      ),
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

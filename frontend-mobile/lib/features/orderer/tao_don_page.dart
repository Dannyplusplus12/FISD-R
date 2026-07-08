import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session/phien_lam_viec.dart';
import '../../core/so_luong_editor.dart';
import '../../core/theme.dart';
import 'don_hang_orderer_provider.dart';
import 'don_hang_orderer_repository.dart';

class _GioHangItem {
  final int variantId;
  final String productName;
  final String variantInfo;
  final int gia;
  final String mauSac;
  final String kichCo;
  final String imageUrl;
  int soLuong = 1;

  _GioHangItem({
    required this.variantId,
    required this.productName,
    required this.variantInfo,
    required this.gia,
    required this.mauSac,
    required this.kichCo,
    this.imageUrl = '',
  });
}

class TaoDonPage extends ConsumerStatefulWidget {
  final PhienLamViec phien;
  const TaoDonPage({super.key, required this.phien});

  @override
  ConsumerState<TaoDonPage> createState() => _TaoDonPageState();
}

class _TaoDonPageState extends ConsumerState<TaoDonPage> {
  final _searchCtrl = TextEditingController();
  final _repo = DonHangOrdererRepository();

  List<Map<String, dynamic>> _allSanPhams = [];
  List<Map<String, dynamic>> _filtered = [];
  List<Map<String, dynamic>> _khachHangs = [];
  Map<String, dynamic>? _khachDaChon;
  final List<_GioHangItem> _gio = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([_repo.laySanPhams(), _repo.layKhachHangs()]);
      if (mounted) {
        setState(() {
          _allSanPhams = results[0];
          _filtered = _allSanPhams;
          _khachHangs = results[1];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _search(String q) {
    setState(() {
      _filtered = q.isEmpty
          ? _allSanPhams
          : _allSanPhams
              .where((sp) =>
                  (sp['name'] as String).toLowerCase().contains(q.toLowerCase()) ||
                  (sp['code'] as String).toLowerCase().contains(q.toLowerCase()))
              .toList();
    });
  }

  int get _tongTien => _gio.fold(0, (s, i) => s + i.gia * i.soLuong);
  int get _soMon => _gio.fold(0, (s, i) => s + i.soLuong);

  void _themVaoGio(Map<String, dynamic> sp, Map<String, dynamic> bt) {
    final btId = bt['id'] as int;
    final idx = _gio.indexWhere((i) => i.variantId == btId);
    setState(() {
      if (idx >= 0) {
        _gio[idx].soLuong++;
      } else {
        final mau = (bt['color'] ?? '') as String;
        final co = (bt['size'] ?? '') as String;
        final info = [if (mau.isNotEmpty) mau, if (co.isNotEmpty) co].join('/');
        _gio.add(_GioHangItem(
          variantId: btId,
          productName: sp['name'] as String,
          variantInfo: info.isEmpty ? 'Mặc định' : info,
          gia: (bt['price'] as num).toInt(),
          mauSac: mau,
          kichCo: co,
          imageUrl: sp['image'] as String? ?? '',
        ));
      }
    });
  }

  void _botKhoiGio(int btId) {
    final idx = _gio.indexWhere((i) => i.variantId == btId);
    if (idx < 0) return;
    setState(() {
      if (_gio[idx].soLuong > 1) {
        _gio[idx].soLuong--;
      } else {
        _gio.removeAt(idx);
      }
    });
  }

  void _setGioQuantity(int btId, int newSL) {
    final idx = _gio.indexWhere((i) => i.variantId == btId);
    if (idx < 0) return;
    setState(() {
      if (newSL <= 0) {
        _gio.removeAt(idx);
      } else {
        _gio[idx].soLuong = newSL;
      }
    });
  }

  Future<void> _chonKhach() async {
    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChonKhachSheet(khachHangs: _khachHangs),
    );
    if (result != null) setState(() => _khachDaChon = result);
  }

  Future<void> _xemGioVaGui() async {
    if (_gio.isEmpty) return;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GioHangSheet(
        gio: _gio,
        khach: _khachDaChon,
        tongTien: _tongTien,
        onConfirm: _gui,
        onSoLuong: (idx, newSL) =>
            setState(() => _gio[idx].soLuong = newSL.clamp(1, 999)),
        onXoa: (idx) => setState(() => _gio.removeAt(idx)),
      ),
    );
    if (ok == true && mounted) Navigator.pop(context, true);
  }

  Future<bool> _gui() async {
    try {
      final cart = _gio.map((i) => {
            'product_name': i.productName,
            'variant_id': i.variantId,
            'color': i.mauSac,
            'size': i.kichCo,
            'quantity': i.soLuong,
            'price': i.gia,
          }).toList();
      await ref.read(taoDonProvider.notifier).taoDon(
            employeeId: widget.phien.id,
            customerName: _khachDaChon?['name'] as String? ?? 'Khách lẻ',
            customerPhone: _khachDaChon?['phone'] as String? ?? '',
            cart: cart,
          );
      return true;
    } catch (e) {
      if (mounted) {
        String msg = 'Lỗi tạo đơn';
        if (e is DioException) {
          final data = e.response?.data;
          if (data is Map && data['detail'] != null) msg = data['detail'].toString();
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.danger));
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gioMap = {for (final g in _gio) g.variantId: g.soLuong};

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tạo đơn hàng', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: AppColors.divider)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              // Khách hàng + search
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Column(children: [
                  GestureDetector(
                    onTap: _chonKhach,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10)),
                      child: Row(children: [
                        const Icon(Icons.person_outline,
                            size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _khachDaChon != null
                                ? '${_khachDaChon!["name"]}  •  ${_khachDaChon!["phone"] ?? ""}'
                                : 'Khách lẻ (mặc định)',
                            style: TextStyle(
                              color: _khachDaChon != null
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const Text('Đổi',
                            style: TextStyle(color: AppColors.info, fontSize: 13)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _searchCtrl,
                    onChanged: _search,
                    decoration: AppDeco.input('Tìm sản phẩm...', icon: Icons.search),
                  ),
                ]),
              ),
              Container(height: 1, color: AppColors.divider),
              // Grid sản phẩm
              Expanded(
                child: _filtered.isEmpty
                    ? emptyState(Icons.search_off_outlined, 'Không tìm thấy')
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _SanPhamTile(
                          sp: _filtered[i],
                          gioMap: gioMap,
                          onTap: () => _moChonBienThe(_filtered[i], gioMap),
                        ),
                      ),
              ),
            ]),
      bottomNavigationBar: _gio.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, -4))
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _xemGioVaGui,
                  style: AppDeco.primaryBtn,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.shopping_cart_outlined),
                    const SizedBox(width: 10),
                    Text('$_soMon món  •  ${fmtTien(_tongTien)}',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right),
                  ]),
                ),
              ),
            ),
    );
  }

  Future<void> _moChonBienThe(
      Map<String, dynamic> sp, Map<int, int> gioMap) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BienTheSheet(
        sp: sp,
        gioMap: gioMap,
        onThem: (bt) => _themVaoGio(sp, bt),
        onBot: (btId) => _botKhoiGio(btId),
        onSet: (btId, newSL) => _setGioQuantity(btId, newSL),
      ),
    );
  }
}

// ── Grid tile ─────────────────────────────────────────────────────────────────

class _SanPhamTile extends StatelessWidget {
  final Map<String, dynamic> sp;
  final Map<int, int> gioMap;
  final VoidCallback onTap;

  const _SanPhamTile(
      {required this.sp, required this.gioMap, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final imageUrl = sp['image'] as String? ?? '';
    final variants = (sp['variants'] as List? ?? []).cast<Map<String, dynamic>>();
    final tongGio = variants.fold<int>(
        0, (s, bt) => s + (gioMap[bt['id'] as int] ?? 0));

    return GestureDetector(
      onTap: onTap,
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
              if (tongGio > 0)
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.check, size: 11, color: Colors.white),
                      const SizedBox(width: 3),
                      Text('$tongGio',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(sp['name'] as String,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(sp['price_range'] as String? ?? '',
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
              size: 48, color: AppColors.divider)));
}

// ── Bottom sheet chọn biến thể ────────────────────────────────────────────────

class _BienTheSheet extends StatefulWidget {
  final Map<String, dynamic> sp;
  final Map<int, int> gioMap;
  final void Function(Map<String, dynamic> bt) onThem;
  final void Function(int btId) onBot;
  final void Function(int btId, int newSL) onSet;

  const _BienTheSheet({
    required this.sp,
    required this.gioMap,
    required this.onThem,
    required this.onBot,
    required this.onSet,
  });

  @override
  State<_BienTheSheet> createState() => _BienTheSheetState();
}

class _BienTheSheetState extends State<_BienTheSheet> {
  late Map<int, int> _local;

  @override
  void initState() {
    super.initState();
    _local = Map.from(widget.gioMap);
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.sp['image'] as String? ?? '';
    final ten = widget.sp['name'] as String;
    final variants =
        (widget.sp['variants'] as List? ?? []).cast<Map<String, dynamic>>();

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
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
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2))),
          // Ảnh lớn
          if (imageUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox()),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Expanded(
                  child: Text(ten,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 17))),
            ]),
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: AppColors.divider),
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: variants.map((bt) {
                final btId = bt['id'] as int;
                final stock = (bt['stock'] as num).toInt();
                final soLuong = _local[btId] ?? 0;
                final mau = (bt['color'] ?? '') as String;
                final co = (bt['size'] ?? '') as String;
                final tenBT =
                    [if (mau.isNotEmpty) mau, if (co.isNotEmpty) co].join(' / ');

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(children: [
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tenBT.isEmpty ? 'Mặc định' : tenBT,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 15)),
                            const SizedBox(height: 2),
                            Row(children: [
                              Text(fmtTien((bt['price'] as num).toInt()),
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              const SizedBox(width: 8),
                              Text('Còn $stock',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: stock > 0
                                          ? AppColors.textSecondary
                                          : AppColors.danger)),
                            ]),
                          ]),
                    ),
                    if (stock == 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10)),
                        child: const Text('Hết hàng',
                            style: TextStyle(
                                color: AppColors.danger, fontSize: 12)),
                      )
                    else if (soLuong == 0)
                      GestureDetector(
                        onTap: () {
                          widget.onThem(bt);
                          setState(() => _local[btId] = 1);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10)),
                          child: const Text('Thêm',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                        ),
                      )
                    else
                      Row(children: [
                        _Nut(Icons.remove, () {
                          widget.onBot(btId);
                          setState(() =>
                              _local[btId] = (_local[btId]! - 1).clamp(0, 999));
                        }),
                        SoLuongEditor(
                          value: soLuong,
                          min: 1,
                          onChanged: (v) {
                            widget.onSet(btId, v);
                            setState(() => _local[btId] = v);
                          },
                        ),
                        _Nut(Icons.add, () {
                          widget.onThem(bt);
                          setState(() =>
                              _local[btId] = (_local[btId]! + 1).clamp(0, 999));
                        }),
                      ]),
                  ]),
                );
              }).toList(),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Nut extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _Nut(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
      );
}

// ── Chọn khách hàng ───────────────────────────────────────────────────────────

class _ChonKhachSheet extends StatefulWidget {
  final List<Map<String, dynamic>> khachHangs;
  const _ChonKhachSheet({required this.khachHangs});

  @override
  State<_ChonKhachSheet> createState() => _ChonKhachSheetState();
}

class _ChonKhachSheetState extends State<_ChonKhachSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.khachHangs
        .where((k) =>
            (k['name'] as String).toLowerCase().contains(_q.toLowerCase()) ||
            (k['phone'] as String? ?? '').contains(_q))
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(children: [
          const SizedBox(height: 8),
          Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: const Text('Chọn khách hàng',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => setState(() => _q = v),
              decoration:
                  AppDeco.input('Tìm theo tên hoặc SĐT', icon: Icons.search),
              autofocus: true,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.background,
              child:
                  const Icon(Icons.person_outline, color: AppColors.textSecondary),
            ),
            title: const Text('Khách lẻ'),
            subtitle: const Text('Không ghi tên khách'),
            onTap: () => Navigator.pop(context, null),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: ctrl,
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final k = filtered[i];
                final no = (k['debt'] as num? ?? 0).toInt();
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      (k['name'] as String).isNotEmpty
                          ? (k['name'] as String)[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(k['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(
                      '${k["phone"] ?? ""}  ${k["area_name"] ?? ""}'),
                  trailing: no > 0
                      ? Text('Nợ ${fmtTien(no)}',
                          style: const TextStyle(
                              color: AppColors.danger, fontSize: 12))
                      : null,
                  onTap: () => Navigator.pop(context, k),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Giỏ hàng ─────────────────────────────────────────────────────────────────

class _GioHangSheet extends StatefulWidget {
  final List<_GioHangItem> gio;
  final Map<String, dynamic>? khach;
  final int tongTien;
  final Future<bool> Function() onConfirm;
  final void Function(int idx, int newSL) onSoLuong;
  final void Function(int idx) onXoa;

  const _GioHangSheet({
    required this.gio,
    required this.khach,
    required this.tongTien,
    required this.onConfirm,
    required this.onSoLuong,
    required this.onXoa,
  });

  @override
  State<_GioHangSheet> createState() => _GioHangSheetState();
}

class _GioHangSheetState extends State<_GioHangSheet> {
  bool _dangGui = false;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(children: [
          const SizedBox(height: 8),
          Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              const Text('Xem lại đơn',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              const Spacer(),
              Text('${widget.gio.length} sản phẩm',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(children: [
              const Icon(Icons.person_outline,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(widget.khach?['name'] as String? ?? 'Khách lẻ',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14)),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: widget.gio.length,
              itemBuilder: (_, i) {
                final item = widget.gio[i];
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(children: [
                    // Thumbnail
                    if (item.imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(item.imageUrl,
                            width: 44, height: 44, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _thumb()),
                      )
                    else
                      _thumb(),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500, fontSize: 14)),
                            Text(
                                '${item.variantInfo}  •  ${fmtTien(item.gia)}',
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12)),
                          ]),
                    ),
                    Row(children: [
                      _Nut(Icons.remove,
                          () => widget.onSoLuong(i, item.soLuong - 1)),
                      SoLuongEditor(
                        value: item.soLuong,
                        min: 1,
                        fontSize: 15,
                        onChanged: (v) => widget.onSoLuong(i, v),
                      ),
                      _Nut(Icons.add,
                          () => widget.onSoLuong(i, item.soLuong + 1)),
                    ]),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => widget.onXoa(i),
                      child: const Icon(Icons.delete_outline,
                          color: AppColors.danger, size: 20),
                    ),
                  ]),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Tổng tiền',
                    style: TextStyle(
                        fontSize: 15, color: AppColors.textSecondary)),
                Text(fmtTien(widget.tongTien),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _dangGui ? null : _gui,
                style: AppDeco.primaryBtn,
                child: _dangGui
                    ? const SizedBox(
                        height: 22, width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Xác nhận & gửi đến Picker',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _thumb() => Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8)),
      child: const Icon(Icons.inventory_2_outlined,
          color: AppColors.textSecondary, size: 20));

  Future<void> _gui() async {
    setState(() => _dangGui = true);
    final ok = await widget.onConfirm();
    if (mounted) {
      setState(() => _dangGui = false);
      if (ok) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Đơn hàng đã gửi đến picker!'),
              backgroundColor: AppColors.success),
        );
      }
    }
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session/phien_lam_viec.dart';
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
  int soLuong = 1;

  _GioHangItem({
    required this.variantId,
    required this.productName,
    required this.variantInfo,
    required this.gia,
    required this.mauSac,
    required this.kichCo,
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
      final results = await Future.wait([
        _repo.laySanPhams(),
        _repo.layKhachHangs(),
      ]);
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

  int get _tongTien => _gio.fold(0, (sum, i) => sum + i.gia * i.soLuong);
  int get _soMon => _gio.fold(0, (sum, i) => sum + i.soLuong);

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
        ));
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm ${sp["name"]}'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _chonKhach() async {
    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ChonKhachSheet(khachHangs: _khachHangs),
    );
    if (result != null) {
      setState(() => _khachDaChon = result);
    }
  }

  Future<void> _xemGioVaGui() async {
    if (_gio.isEmpty) return;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _GioHangSheet(
        gio: _gio,
        khach: _khachDaChon,
        tongTien: _tongTien,
        onConfirm: _gui,
        onSoLuongChanged: (idx, delta) {
          setState(() {
            _gio[idx].soLuong = (_gio[idx].soLuong + delta).clamp(1, 999);
          });
        },
        onXoa: (idx) {
          setState(() => _gio.removeAt(idx));
        },
      ),
    );
    if (ok == true && mounted) {
      Navigator.pop(context, true);
    }
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tạo đơn hàng', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              // Khách hàng
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: GestureDetector(
                  onTap: _chonKhach,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      const Icon(Icons.person_outline, size: 18, color: AppColors.textSecondary),
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
                      Text('Đổi', style: TextStyle(color: AppColors.info, fontSize: 13)),
                    ]),
                  ),
                ),
              ),
              // Search
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _search,
                  decoration: AppDeco.input('Tìm sản phẩm...', icon: Icons.search),
                ),
              ),
              Container(height: 1, color: AppColors.divider),
              // Product list
              Expanded(
                child: _filtered.isEmpty
                    ? emptyState(Icons.search_off_outlined, 'Không tìm thấy sản phẩm')
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _SanPhamCard(
                          sp: _filtered[i],
                          onThem: (bt) => _themVaoGio(_filtered[i], bt),
                          gioIds: {for (final g in _gio) g.variantId: g.soLuong},
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
                    Text('$_soMon món  •  ${fmtTien(_tongTien)} đ',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right),
                  ]),
                ),
              ),
            ),
    );
  }
}

class _SanPhamCard extends StatelessWidget {
  final Map<String, dynamic> sp;
  final Map<int, int> gioIds;
  final void Function(Map<String, dynamic> bt) onThem;

  const _SanPhamCard({required this.sp, required this.gioIds, required this.onThem});

  @override
  Widget build(BuildContext context) {
    final variants = (sp['variants'] as List? ?? []).cast<Map<String, dynamic>>();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppDeco.card(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(children: [
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
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(sp['name'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(sp['price_range'] as String? ?? '',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ])),
          ]),
        ),
        const Divider(height: 1, color: AppColors.divider),
        ...variants.map((bt) {
          final btId = bt['id'] as int;
          final stock = (bt['stock'] as num).toInt();
          final inCart = gioIds[btId] ?? 0;
          final mau = (bt['color'] ?? '') as String;
          final co = (bt['size'] ?? '') as String;
          final ten = [if (mau.isNotEmpty) mau, if (co.isNotEmpty) co].join(' / ');

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(children: [
              Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(ten.isEmpty ? 'Mặc định' : ten,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                Text('${fmtTien((bt["price"] as num).toInt())}đ  •  Còn $stock',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ])),
              stock == 0
                  ? const Text('Hết hàng',
                      style: TextStyle(color: AppColors.danger, fontSize: 12))
                  : GestureDetector(
                      onTap: () => onThem(bt),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: inCart > 0
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          if (inCart > 0) ...[
                            Icon(Icons.check, size: 14, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text('$inCart',
                                style: const TextStyle(
                                    color: AppColors.success,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(width: 4),
                          ],
                          Icon(Icons.add, size: 16,
                              color: inCart > 0 ? AppColors.success : AppColors.primary),
                        ]),
                      ),
                    ),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _iconSP() => Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
      child: const Icon(Icons.inventory_2_outlined, color: AppColors.textSecondary, size: 20));
}

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
      builder: (_, ctrl) => Column(children: [
        const SizedBox(height: 8),
        Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text('Chọn khách hàng',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            onChanged: (v) => setState(() => _q = v),
            decoration: AppDeco.input('Tìm theo tên hoặc SĐT', icon: Icons.search),
            autofocus: true,
          ),
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.background,
            child: const Icon(Icons.person_outline, color: AppColors.textSecondary),
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
                    (k['name'] as String).isNotEmpty ? (k['name'] as String)[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(k['name'] as String, style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text('${k["phone"] ?? ""}  ${k["area_name"] ?? ""}'),
                trailing: no > 0
                    ? Text('Nợ ${fmtTien(no)}đ',
                        style: const TextStyle(color: AppColors.danger, fontSize: 12))
                    : null,
                onTap: () => Navigator.pop(context, k),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _GioHangSheet extends StatefulWidget {
  final List<_GioHangItem> gio;
  final Map<String, dynamic>? khach;
  final int tongTien;
  final Future<bool> Function() onConfirm;
  final void Function(int idx, int delta) onSoLuongChanged;
  final void Function(int idx) onXoa;

  const _GioHangSheet({
    required this.gio,
    required this.khach,
    required this.tongTien,
    required this.onConfirm,
    required this.onSoLuongChanged,
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
      builder: (_, ctrl) => Column(children: [
        const SizedBox(height: 8),
        Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            const Text('Xem lại đơn hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            const Spacer(),
            Text('${widget.gio.length} sản phẩm',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ]),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(widget.khach?['name'] as String? ?? 'Khách lẻ',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ]),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            controller: ctrl,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: widget.gio.length,
            itemBuilder: (_, i) {
              final item = widget.gio[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(children: [
                  Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item.productName,
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                    Text('${item.variantInfo}  •  ${fmtTien(item.gia)}đ',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ])),
                  Row(children: [
                    _NutSL(Icons.remove, () => widget.onSoLuongChanged(i, -1)),
                    SizedBox(
                      width: 36,
                      child: Center(
                        child: Text('${item.soLuong}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    _NutSL(Icons.add, () => widget.onSoLuongChanged(i, 1)),
                  ]),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => widget.onXoa(i),
                    child: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                  ),
                ]),
              );
            },
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Tổng tiền', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
              Text('${fmtTien(widget.tongTien)} đ',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _dangGui ? null : _gui,
              style: AppDeco.primaryBtn,
              child: _dangGui
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Xác nhận & gửi đến Picker',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
      ]),
    );
  }

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

class _NutSL extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NutSL(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
      );
}

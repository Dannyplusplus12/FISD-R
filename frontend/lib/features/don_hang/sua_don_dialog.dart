import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format_tien.dart';
import '../../core/theme.dart';
import '../../models/don_hang.dart';
import '../../models/san_pham.dart';
import '../lenh_nhanh/lenh_nhanh_model.dart';
import '../lenh_nhanh/lenh_nhanh_provider.dart';
import '../san_pham/san_pham_provider.dart';
import 'don_hang_provider.dart';
import 'don_hang_repository.dart';

// ─── State cục bộ cho dialog ────────────────────────────────────────────────

class _GioMuc {
  final int bienTheId;
  final String tenSanPham;
  final String mauSac;
  final String kichCo;
  final int donGia;
  final int soLuong;

  const _GioMuc({
    required this.bienTheId,
    required this.tenSanPham,
    required this.mauSac,
    required this.kichCo,
    required this.donGia,
    required this.soLuong,
  });

  _GioMuc copyWith({int? soLuong}) => _GioMuc(
        bienTheId: bienTheId,
        tenSanPham: tenSanPham,
        mauSac: mauSac,
        kichCo: kichCo,
        donGia: donGia,
        soLuong: soLuong ?? this.soLuong,
      );

  int get thanhTien => donGia * soLuong;

  MatHangGio toMatHangGio() => MatHangGio(
        bienTheId: bienTheId,
        tenSanPham: tenSanPham,
        mauSac: mauSac,
        kichCo: kichCo,
        donGia: donGia,
        soLuong: soLuong,
      );
}

// ─── Dialog chính ───────────────────────────────────────────────────────────

class SuaDonDialog extends ConsumerStatefulWidget {
  final DonHang donHang;
  const SuaDonDialog({super.key, required this.donHang});

  @override
  ConsumerState<SuaDonDialog> createState() => _SuaDonDialogState();
}

class _SuaDonDialogState extends ConsumerState<SuaDonDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final TextEditingController _khachCtrl;
  late List<_GioMuc> _gio;
  bool _dangLuu = false;
  String? _loi;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _khachCtrl = TextEditingController(
        text: widget.donHang.tenKhachHang == 'Khách lẻ'
            ? ''
            : widget.donHang.tenKhachHang);
    _gio = widget.donHang.chiTiets
        .map((ct) => _GioMuc(
              bienTheId: ct.bienTheId ?? 0,
              tenSanPham: ct.tenSanPham,
              mauSac: ct.thongTinBienThe.split('-').first,
              kichCo: ct.thongTinBienThe.split('-').length > 1
                  ? ct.thongTinBienThe.split('-').last
                  : '',
              donGia: ct.donGia,
              soLuong: ct.soLuong,
            ))
        .toList();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _khachCtrl.dispose();
    super.dispose();
  }

  void _themBienThe(BienThe bt, SanPham sp) {
    setState(() {
      final idx = _gio.indexWhere((m) => m.bienTheId == bt.id);
      if (idx >= 0) {
        _gio[idx] = _gio[idx].copyWith(soLuong: _gio[idx].soLuong + 1);
      } else {
        _gio.add(_GioMuc(
          bienTheId: bt.id!,
          tenSanPham: sp.ten,
          mauSac: bt.mauSac,
          kichCo: bt.kichCo,
          donGia: bt.gia,
          soLuong: 1,
        ));
      }
    });
    // Chuyển về tab giỏ để thấy ngay
    _tabs.animateTo(1);
  }

  void _nhanKetQuaAI(KetQuaLenhNhanh kq) {
    setState(() {
      for (final m in kq.gio) {
        final idx = _gio.indexWhere((x) => x.bienTheId == m.bienTheId);
        if (idx >= 0) {
          _gio[idx] = _gio[idx].copyWith(soLuong: _gio[idx].soLuong + m.soLuong);
        } else {
          _gio.add(_GioMuc(
            bienTheId: m.bienTheId,
            tenSanPham: m.tenSanPham,
            mauSac: m.mauSac,
            kichCo: m.kichCo,
            donGia: m.donGia,
            soLuong: m.soLuong,
          ));
        }
      }
    });
    _tabs.animateTo(1);
  }

  Future<void> _luu() async {
    if (_gio.isEmpty) return;
    setState(() {
      _dangLuu = true;
      _loi = null;
    });
    try {
      final tenKhach = _khachCtrl.text.trim().isEmpty
          ? 'Khách lẻ'
          : _khachCtrl.text.trim();
      await ref.read(donHangRepositoryProvider).suaDon(
            donId: widget.donHang.id,
            tenKhachHang: tenKhach,
            gio: _gio.map((m) => m.toMatHangGio()).toList(),
          );
      ref.read(quanLyDonHangProvider.notifier).lamMoi();
      ref.read(donHangChoProvider.notifier).lamMoi();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _dangLuu = false;
        _loi = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  int get _tongTien => _gio.fold(0, (s, m) => s + m.thanhTien);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860, maxHeight: 680),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
              child: Row(children: [
                Text('Sửa đơn #${widget.donHang.id}',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Chờ duyệt',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600)),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ]),
            ),

            // ── Tabs ────────────────────────────────────────────────────
            TabBar(
              controller: _tabs,
              labelColor: AppColors.navSelected,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.navSelected,
              tabs: [
                const Tab(text: 'Thêm sản phẩm'),
                Tab(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('Giỏ hàng'),
                    if (_gio.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.navSelected,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${_gio.length}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ]),
                ),
              ],
            ),

            // ── Tab content ─────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _TabThemSanPham(onThem: _themBienThe, onLenhNhanh: _moLenhNhanh),
                  _TabGioHang(
                    gio: _gio,
                    khachCtrl: _khachCtrl,
                    onCapNhat: (id, sl) => setState(() {
                      final idx = _gio.indexWhere((m) => m.bienTheId == id);
                      if (idx >= 0) {
                        if (sl <= 0) {
                          _gio.removeAt(idx);
                        } else {
                          _gio[idx] = _gio[idx].copyWith(soLuong: sl);
                        }
                      }
                    }),
                    onXoa: (id) => setState(
                        () => _gio.removeWhere((m) => m.bienTheId == id)),
                  ),
                ],
              ),
            ),

            // ── Footer ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                    top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(children: [
                if (_loi != null)
                  Expanded(
                    child: Text(_loi!,
                        style: const TextStyle(
                            color: Colors.red, fontSize: 12)),
                  )
                else
                  Row(children: [
                    const Text('Tổng: ',
                        style: TextStyle(
                            fontWeight: FontWeight.w600)),
                    Text(dinhDangTien(_tongTien),
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.deepOrange)),
                  ]),
                const Spacer(),
                OutlinedButton(
                  onPressed: _dangLuu
                      ? null
                      : () => Navigator.pop(context),
                  child: const Text('Huỷ'),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  icon: _dangLuu
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save_outlined, size: 16),
                  label: Text(_dangLuu ? 'Đang lưu...' : 'Lưu thay đổi'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navSelected,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  onPressed:
                      _dangLuu || _gio.isEmpty ? null : _luu,
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  void _moLenhNhanh() async {
    ref.read(lenhNhanhProvider.notifier).datLai();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _MiniLenhNhanhDialog(
        onThem: _nhanKetQuaAI,
      ),
    );
    if (ok == true) {
      setState(() {});
    }
  }
}

// ─── Tab 1: Thêm sản phẩm ───────────────────────────────────────────────────

class _TabThemSanPham extends ConsumerStatefulWidget {
  final void Function(BienThe, SanPham) onThem;
  final VoidCallback onLenhNhanh;
  const _TabThemSanPham({required this.onThem, required this.onLenhNhanh});

  @override
  ConsumerState<_TabThemSanPham> createState() => _TabThemSanPhamState();
}

class _TabThemSanPhamState extends ConsumerState<_TabThemSanPham> {
  final _ctrl = TextEditingController();
  String _tuKhoa = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spAsync = ref.watch(sanPhamProvider);
    final allSp = spAsync.valueOrNull ?? [];
    final loc = _tuKhoa.isEmpty
        ? allSp
        : allSp
            .where((sp) =>
                sp.ten.toLowerCase().contains(_tuKhoa.toLowerCase()) ||
                sp.ma.toLowerCase().contains(_tuKhoa.toLowerCase()))
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                decoration: InputDecoration(
                  hintText: 'Tìm sản phẩm...',
                  prefixIcon: const Icon(Icons.search,
                      size: 16, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (v) => setState(() => _tuKhoa = v),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              icon: const Icon(Icons.bolt, size: 14),
              label: const Text('Lệnh nhanh'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.navSelected,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                textStyle: const TextStyle(fontSize: 12),
              ),
              onPressed: widget.onLenhNhanh,
            ),
          ]),
        ),
        Expanded(
          child: spAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Center(child: Text(e.toString())),
            data: (_) => loc.isEmpty
                ? const Center(
                    child: Text('Không tìm thấy',
                        style: TextStyle(
                            color: AppColors.textSecondary)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: loc.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 4),
                    itemBuilder: (_, i) => _HangSanPham(
                      sanPham: loc[i],
                      onThem: (bt) => widget.onThem(bt, loc[i]),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _HangSanPham extends StatelessWidget {
  final SanPham sanPham;
  final ValueChanged<BienThe> onThem;
  const _HangSanPham({required this.sanPham, required this.onThem});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(sanPham.ten,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            Text('Tồn ${sanPham.tongTonKho}',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ]),
          if (sanPham.ma.isNotEmpty)
            Text('Mã: ${sanPham.ma}',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: sanPham.bienThes.map((bt) {
              final het = bt.tonKho == 0;
              return GestureDetector(
                onTap: () => onThem(bt),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: het
                        ? const Color(0xFFF0F0F0)
                        : const Color(0xFFEEF4FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: het
                          ? Colors.grey.shade300
                          : AppColors.navSelected
                              .withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      bt.tenHienThi,
                      style: TextStyle(
                          fontSize: 12,
                          color: het
                              ? AppColors.textSecondary
                              : AppColors.navSelected,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 4),
                    Text(dinhDangTien(bt.gia),
                        style: const TextStyle(fontSize: 11)),
                    if (het) ...[
                      const SizedBox(width: 3),
                      const Text('(hết)',
                          style: TextStyle(
                              fontSize: 10, color: Colors.red)),
                    ],
                  ]),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 2: Giỏ hàng ────────────────────────────────────────────────────────

class _TabGioHang extends StatelessWidget {
  final List<_GioMuc> gio;
  final TextEditingController khachCtrl;
  final void Function(int bienTheId, int soLuong) onCapNhat;
  final void Function(int bienTheId) onXoa;

  const _TabGioHang({
    required this.gio,
    required this.khachCtrl,
    required this.onCapNhat,
    required this.onXoa,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: khachCtrl,
            decoration: InputDecoration(
              hintText: 'Tên khách hàng',
              prefixIcon: const Icon(Icons.person_outline,
                  size: 16, color: AppColors.textSecondary),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: gio.isEmpty
              ? const Center(
                  child: Text('Chưa có sản phẩm nào',
                      style: TextStyle(
                          color: AppColors.textSecondary)))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: gio.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 6),
                  itemBuilder: (_, i) => _HangGio(
                    muc: gio[i],
                    onCapNhat: onCapNhat,
                    onXoa: onXoa,
                  ),
                ),
        ),
      ],
    );
  }
}

class _HangGio extends StatefulWidget {
  final _GioMuc muc;
  final void Function(int, int) onCapNhat;
  final void Function(int) onXoa;
  const _HangGio(
      {required this.muc, required this.onCapNhat, required this.onXoa});

  @override
  State<_HangGio> createState() => _HangGioState();
}

class _HangGioState extends State<_HangGio> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: '${widget.muc.soLuong}');
    _focus = FocusNode();
    _focus.addListener(() {
      if (_focus.hasFocus) {
        _ctrl.selection = TextSelection(
            baseOffset: 0, extentOffset: _ctrl.text.length);
      }
    });
  }

  @override
  void didUpdateWidget(_HangGio old) {
    super.didUpdateWidget(old);
    if (old.muc.soLuong != widget.muc.soLuong && !_focus.hasFocus) {
      _ctrl.text = '${widget.muc.soLuong}';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _commit() {
    final n = int.tryParse(_ctrl.text) ?? widget.muc.soLuong;
    widget.onCapNhat(widget.muc.bienTheId, n);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.muc;
    final bienThe = [
      if (m.mauSac.isNotEmpty && m.mauSac != 'null') m.mauSac,
      if (m.kichCo.isNotEmpty && m.kichCo != 'null') m.kichCo,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.tenSanPham,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              if (bienThe.isNotEmpty)
                Text(bienThe,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              Text(dinhDangTien(m.donGia),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Số lượng
        _NutNho(
            icon: Icons.remove,
            onTap: () =>
                widget.onCapNhat(m.bienTheId, m.soLuong - 1)),
        SizedBox(
          width: 38,
          child: TextField(
            controller: _ctrl,
            focusNode: _focus,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 4),
              border: InputBorder.none,
            ),
            onSubmitted: (_) => _commit(),
            onEditingComplete: _commit,
          ),
        ),
        _NutNho(
            icon: Icons.add,
            onTap: () =>
                widget.onCapNhat(m.bienTheId, m.soLuong + 1)),
        const SizedBox(width: 8),
        Text(dinhDangTien(m.thanhTien),
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => widget.onXoa(m.bienTheId),
          child: const Icon(Icons.close,
              size: 16, color: AppColors.textSecondary),
        ),
      ]),
    );
  }
}

class _NutNho extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NutNho({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.navUnselected,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14),
        ),
      );
}

// ─── Mini Lệnh nhanh dialog (dùng trong SuaDon) ─────────────────────────────

class _MiniLenhNhanhDialog extends ConsumerStatefulWidget {
  final ValueChanged<KetQuaLenhNhanh> onThem;
  const _MiniLenhNhanhDialog({required this.onThem});

  @override
  ConsumerState<_MiniLenhNhanhDialog> createState() =>
      _MiniLenhNhanhDialogState();
}

class _MiniLenhNhanhDialogState
    extends ConsumerState<_MiniLenhNhanhDialog> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = ref.watch(lenhNhanhProvider);

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                const Icon(Icons.bolt, size: 18),
                const SizedBox(width: 6),
                const Text('Lệnh nhanh',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => Navigator.pop(context, false),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    enabled: !tt.dangTai,
                    decoration: InputDecoration(
                      hintText: 'vd: 1 đôi đen 40',
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _chay(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: tt.dangTai ? null : _chay,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navSelected,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  child: tt.dangTai
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Phân tích'),
                ),
              ]),

              if (tt.trangThai == TrangThaiLenh.xemTruoc &&
                  tt.ketQua != null) ...[
                const SizedBox(height: 12),
                _XemTruocNho(ketQua: tt.ketQua!),
                const SizedBox(height: 10),
                Row(children: [
                  OutlinedButton(
                    onPressed: () {
                      ref.read(lenhNhanhProvider.notifier).datLai();
                      _ctrl.clear();
                      _focus.requestFocus();
                    },
                    child: const Text('Nhập lại'),
                  ),
                  const Spacer(),
                  if (tt.ketQua!.gio.isNotEmpty)
                    FilledButton.icon(
                      icon: const Icon(Icons.add_shopping_cart,
                          size: 15),
                      label: const Text('Thêm vào giỏ'),
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.activeGreen),
                      onPressed: () {
                        widget.onThem(tt.ketQua!);
                        Navigator.pop(context, true);
                      },
                    ),
                ]),
              ],

              if (tt.trangThai == TrangThaiLenh.loi)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(tt.thongBaoLoi ?? 'Lỗi',
                        style: const TextStyle(
                            color: Colors.red, fontSize: 12)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _chay() {
    final l = _ctrl.text.trim();
    if (l.isEmpty) return;
    ref.read(lenhNhanhProvider.notifier).phanTich(l);
  }
}

class _XemTruocNho extends StatelessWidget {
  final KetQuaLenhNhanh ketQua;
  const _XemTruocNho({required this.ketQua});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4FF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ketQua.tenKhach != 'Khách lẻ')
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('Khách: ${ketQua.tenKhach}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ...ketQua.gio.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(children: [
                    Expanded(
                      child: Text(
                        '${m.tenSanPham}'
                        '${m.mauSac.isNotEmpty ? " · ${m.mauSac}" : ""}'
                        '${m.kichCo.isNotEmpty ? " · ${m.kichCo}" : ""}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Text('×${m.soLuong}  ${dinhDangTien(m.thanhTien)}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                )),
            if (ketQua.canhBao.isNotEmpty)
              ...ketQua.canhBao.map((w) => Text('⚠ $w',
                  style: const TextStyle(
                      fontSize: 11, color: Colors.orange))),
          ],
        ),
      );
}

// ─── Hàm tiện ích mở dialog ──────────────────────────────────────────────────

Future<bool?> moSuaDonDialog(BuildContext context, DonHang donHang) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => SuaDonDialog(donHang: donHang),
  );
}

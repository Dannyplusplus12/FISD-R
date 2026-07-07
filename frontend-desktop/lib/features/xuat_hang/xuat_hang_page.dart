import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fisd_shared/core/format_tien.dart';
import '../../core/theme.dart';
import 'package:fisd_shared/models/khach_hang.dart';
import 'package:fisd_shared/models/san_pham.dart';
import '../khach_hang/khach_hang_provider.dart';
import '../lenh_nhanh/lenh_nhanh_model.dart';
import '../lenh_nhanh/lenh_nhanh_provider.dart';
import '../san_pham/san_pham_provider.dart';
import 'xuat_hang_provider.dart';

class XuatHangPage extends ConsumerStatefulWidget {
  const XuatHangPage({super.key});
  @override
  ConsumerState<XuatHangPage> createState() => _XuatHangPageState();
}

class _XuatHangPageState extends ConsumerState<XuatHangPage> {
  final _timKiemCtrl = TextEditingController();
  final _timKiemFocus = FocusNode();
  String _tuKhoa = '';

  @override
  void dispose() {
    _timKiemCtrl.dispose();
    _timKiemFocus.dispose();
    super.dispose();
  }

  List<SanPham> _loc(List<SanPham> ds) {
    if (_tuKhoa.isEmpty) return ds;
    final k = _tuKhoa.toLowerCase();
    return ds.where((sp) =>
        sp.ten.toLowerCase().contains(k) || sp.ma.toLowerCase().contains(k)).toList();
  }

  void _moLenhNhanh() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const _LenhNhanhXuatDialog(),
    );
    if (result == true && mounted) {
      final kq = ref.read(lenhNhanhProvider).ketQua;
      if (kq != null) ref.read(xuatHangProvider.notifier).nhanKetQuaLenhNhanh(kq);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spAsync = ref.watch(sanPhamProvider);
    final gioState = ref.watch(xuatHangProvider);

    return SafeArea(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Cột trái: danh sách sản phẩm ──────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(
                  tongMau: spAsync.valueOrNull?.length ?? 0,
                  tongTrongGio: gioState.tongMuc,
                  onLenhNhanh: _moLenhNhanh,
                ),
                _ThanhTimKiem(
                  ctrl: _timKiemCtrl,
                  focus: _timKiemFocus,
                  onThay: (v) => setState(() => _tuKhoa = v),
                  onLamMoi: () {
                    _timKiemCtrl.clear();
                    setState(() => _tuKhoa = '');
                    ref.read(sanPhamProvider.notifier).lamMoi();
                  },
                ),
                Expanded(
                  child: spAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(e.toString(),
                            style: const TextStyle(
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () =>
                              ref.read(sanPhamProvider.notifier).lamMoi(),
                          child: const Text('Thử lại'),
                        ),
                      ]),
                    ),
                    data: (ds) {
                      final loc = _loc(ds);
                      if (loc.isEmpty) {
                        return const Center(
                          child: Text('Không tìm thấy sản phẩm',
                              style:
                                  TextStyle(color: AppColors.textSecondary)),
                        );
                      }
                      return _LuoiSanPham(sanPhams: loc);
                    },
                  ),
                ),
              ],
            ),
          ),
          // ── Cột phải: giỏ hàng ────────────────────────────────────────
          _PanelGioHang(gioState: gioState),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int tongMau;
  final int tongTrongGio;
  final VoidCallback onLenhNhanh;

  const _Header({
    required this.tongMau,
    required this.tongTrongGio,
    required this.onLenhNhanh,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(children: [
        const Text('Xuất hàng',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(width: 12),
        Text('$tongMau mẫu',
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary)),
        if (tongTrongGio > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.navSelected,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('$tongTrongGio SP trong giỏ',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
        ],
        const Spacer(),
        FilledButton.icon(
          icon: const Icon(Icons.bolt, size: 15),
          label: const Text('Lệnh nhanh'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.navSelected,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            textStyle: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600),
          ),
          onPressed: onLenhNhanh,
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Thanh tìm kiếm
// ─────────────────────────────────────────────────────────────────────────────

class _ThanhTimKiem extends StatelessWidget {
  final TextEditingController ctrl;
  final FocusNode focus;
  final ValueChanged<String> onThay;
  final VoidCallback onLamMoi;

  const _ThanhTimKiem({
    required this.ctrl,
    required this.focus,
    required this.onThay,
    required this.onLamMoi,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: ctrl,
            focusNode: focus,
            decoration: InputDecoration(
              hintText: 'Tìm theo tên hoặc mã hàng...',
              hintStyle: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
              prefixIcon: const Icon(Icons.search,
                  size: 18, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: onThay,
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.refresh, size: 15),
          label: const Text('Làm mới'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: BorderSide(color: Colors.grey.shade300),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            textStyle: const TextStyle(fontSize: 13),
          ),
          onPressed: onLamMoi,
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lưới sản phẩm
// ─────────────────────────────────────────────────────────────────────────────

class _LuoiSanPham extends ConsumerWidget {
  final List<SanPham> sanPhams;
  const _LuoiSanPham({required this.sanPhams});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        mainAxisExtent: 190,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: sanPhams.length,
      itemBuilder: (_, i) => _TheSanPham(
        sanPham: sanPhams[i],
        onThem: (bt) =>
            ref.read(xuatHangProvider.notifier).themBienThe(bt, sanPhams[i]),
      ),
    );
  }
}

class _TheSanPham extends StatelessWidget {
  final SanPham sanPham;
  final ValueChanged<BienThe> onThem;

  const _TheSanPham({required this.sanPham, required this.onThem});

  String get _nhanTonKho {
    final tong = sanPham.tongTonKho;
    if (tong == 0) return 'Hết hàng';
    if (tong <= 5) return 'Còn ít';
    return '';
  }

  Color get _mauNhan {
    final tong = sanPham.tongTonKho;
    if (tong == 0) return Colors.red;
    if (tong <= 5) return Colors.orange;
    return Colors.transparent;
  }

  void _xuLyNhan(BuildContext context) {
    final variants = sanPham.bienThes.where((v) => v.tonKho > 0).toList();
    if (variants.isEmpty) {
      // Hết hàng — vẫn cho thêm nhưng cảnh báo
      final all = sanPham.bienThes;
      if (all.length == 1) {
        onThem(all.first);
        return;
      }
      _moChonBienThe(context, all);
      return;
    }
    if (variants.length == 1 &&
        sanPham.bienThes.length == 1) {
      onThem(variants.first);
      return;
    }
    _moChonBienThe(context, sanPham.bienThes);
  }

  void _moChonBienThe(BuildContext context, List<BienThe> ds) {
    showDialog(
      context: context,
      builder: (_) => _DialogChonBienThe(sanPham: sanPham, onChon: onThem),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nhan = _nhanTonKho;
    final mau = _mauNhan;

    return GestureDetector(
      onTap: () => _xuLyNhan(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 4,
                offset: Offset(0, 2))
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Ảnh
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12)),
                    child: sanPham.anh.isNotEmpty
                        ? Image.network(
                            sanPham.anh,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const _PlaceholderAnh(),
                          )
                        : const _PlaceholderAnh(),
                  ),
                ),
                // Thông tin
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sanPham.ten,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (sanPham.ma.isNotEmpty)
                        Text('Mã ${sanPham.ma}',
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary)),
                      const SizedBox(height: 3),
                      Row(children: [
                        Expanded(
                          child: Text(
                            sanPham.khoangGia.isNotEmpty
                                ? sanPham.khoangGia
                                : (sanPham.bienThes.isNotEmpty
                                    ? dinhDangTien(
                                        sanPham.bienThes.first.gia)
                                    : '—'),
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.navSelected,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          'Tồn ${sanPham.tongTonKho}',
                          style: TextStyle(
                              fontSize: 10,
                              color: sanPham.tongTonKho == 0
                                  ? Colors.red
                                  : AppColors.textSecondary),
                        ),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
            // Badge trạng thái
            if (nhan.isNotEmpty)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: mau,
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(nhan,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderAnh extends StatelessWidget {
  const _PlaceholderAnh();
  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFFF0F0F0),
        child: const Center(
          child: Icon(Icons.person_outline,
              size: 40, color: Color(0xFFBBBBBB)),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog chọn biến thể
// ─────────────────────────────────────────────────────────────────────────────

class _DialogChonBienThe extends StatelessWidget {
  final SanPham sanPham;
  final ValueChanged<BienThe> onChon;
  const _DialogChonBienThe({required this.sanPham, required this.onChon});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(sanPham.ten,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: sanPham.bienThes.map((bt) {
                      final het = bt.tonKho == 0;
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          onChon(bt);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: het
                                ? const Color(0xFFF5F5F5)
                                : const Color(0xFFF0F4FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: het
                                  ? Colors.grey.shade300
                                  : AppColors.navSelected.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bt.tenHienThi,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: het
                                        ? AppColors.textSecondary
                                        : AppColors.navSelected),
                              ),
                              const SizedBox(height: 2),
                              Text(dinhDangTien(bt.gia),
                                  style: const TextStyle(fontSize: 12)),
                              Text(
                                het ? 'Hết hàng' : 'Tồn ${bt.tonKho}',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: het
                                        ? Colors.red
                                        : AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng')),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Panel giỏ hàng (cột phải)
// ─────────────────────────────────────────────────────────────────────────────

class _PanelGioHang extends ConsumerStatefulWidget {
  final XuatHangState gioState;
  const _PanelGioHang({required this.gioState});

  @override
  ConsumerState<_PanelGioHang> createState() => _PanelGioHangState();
}

class _PanelGioHangState extends ConsumerState<_PanelGioHang> {
  final _khachCtrl = TextEditingController();
  final _dienThoaiCtrl = TextEditingController();
  final _khachFocus = FocusNode();
  final _dienThoaiFocus = FocusNode();
  final _overlayCtrl = OverlayPortalController();
  final _layerLink = LayerLink();
  List<KhachHang> _goiY = [];

  @override
  void initState() {
    super.initState();
    _khachFocus.addListener(() {
      if (!_khachFocus.hasFocus) {
        _overlayCtrl.hide();
      }
    });
  }

  @override
  void dispose() {
    _khachCtrl.dispose();
    _dienThoaiCtrl.dispose();
    _khachFocus.dispose();
    _dienThoaiFocus.dispose();
    super.dispose();
  }

  void _capNhatGoiY(String val, List<KhachHang> tatCa) {
    if (val.isEmpty) {
      setState(() => _goiY = []);
      _overlayCtrl.hide();
      return;
    }
    final k = val.toLowerCase();
    final filtered =
        tatCa.where((kh) => kh.ten.toLowerCase().contains(k)).take(6).toList();
    setState(() => _goiY = filtered);
    if (filtered.isNotEmpty) {
      _overlayCtrl.show();
    } else {
      _overlayCtrl.hide();
    }
  }

  void _chonKhach(KhachHang kh) {
    _khachCtrl.text = kh.ten;
    _dienThoaiCtrl.text = kh.soDienThoai;
    ref.read(xuatHangProvider.notifier).capNhatKhach(
          ten: kh.ten,
          soDienThoai: kh.soDienThoai,
        );
    _overlayCtrl.hide();
    _dienThoaiFocus.requestFocus();
  }

  Future<void> _xuatHang() async {
    final ok = await ref.read(xuatHangProvider.notifier).xuatHang();
    if (ok && mounted) {
      _khachCtrl.clear();
      _dienThoaiCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đơn hàng đã gửi — chờ duyệt'),
          backgroundColor: AppColors.activeGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gs = widget.gioState;
    final khachAsync = ref.watch(khachHangProvider);
    final tatCaKhach = khachAsync.valueOrNull ?? [];

    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
              color: AppColors.sidebarShadow,
              blurRadius: 12,
              offset: Offset(-4, 0))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header giỏ
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(children: [
              const Text('Khách hàng',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
            ]),
          ),

          // Input khách hàng
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(children: [
              // Tên khách — với autocomplete
              CompositedTransformTarget(
                link: _layerLink,
                child: OverlayPortal(
                  controller: _overlayCtrl,
                  overlayChildBuilder: (_) => CompositedTransformFollower(
                    link: _layerLink,
                    targetAnchor: Alignment.bottomLeft,
                    followerAnchor: Alignment.topLeft,
                    child: Material(
                      elevation: 6,
                      borderRadius: BorderRadius.circular(10),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 256),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: _goiY
                              .map((kh) => ListTile(
                                    dense: true,
                                    leading: const Icon(
                                        Icons.person_outline,
                                        size: 16),
                                    title: Text(kh.ten,
                                        style: const TextStyle(
                                            fontSize: 13)),
                                    subtitle: kh.soDienThoai.isNotEmpty
                                        ? Text(kh.soDienThoai,
                                            style: const TextStyle(
                                                fontSize: 11))
                                        : null,
                                    onTap: () => _chonKhach(kh),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                  child: _OInput(
                    ctrl: _khachCtrl,
                    focus: _khachFocus,
                    icon: Icons.person_outline,
                    hint: 'Tên khách hàng',
                    onChanged: (v) {
                      ref
                          .read(xuatHangProvider.notifier)
                          .capNhatKhach(ten: v);
                      _capNhatGoiY(v, tatCaKhach);
                    },
                    onSubmitted: (_) =>
                        _dienThoaiFocus.requestFocus(),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              _OInput(
                ctrl: _dienThoaiCtrl,
                focus: _dienThoaiFocus,
                icon: Icons.phone_outlined,
                hint: 'Số điện thoại',
                kieuBanPhim: TextInputType.phone,
                onChanged: (v) => ref
                    .read(xuatHangProvider.notifier)
                    .capNhatKhach(soDienThoai: v),
                onSubmitted: (_) {},
              ),
            ]),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),

          // Header giỏ hàng
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 12, 6),
            child: Row(children: [
              const Text('Giỏ hàng',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
              if (gs.coHang) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.navSelected,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${gs.tongMuc}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ],
              const Spacer(),
              if (gs.coHang)
                GestureDetector(
                  onTap: () => ref
                      .read(xuatHangProvider.notifier)
                      .xoaTatCa(),
                  child: Row(children: [
                    const Icon(Icons.delete_outline,
                        size: 14, color: Colors.red),
                    const SizedBox(width: 3),
                    Text('Xóa hết',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade600)),
                  ]),
                ),
            ]),
          ),

          // Danh sách giỏ
          Expanded(
            child: gs.gio.isEmpty
                ? const Center(
                    child: Text('Chưa có sản phẩm',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    itemCount: gs.gio.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 6),
                    itemBuilder: (_, i) =>
                        _TheMucGio(muc: gs.gio[i]),
                  ),
          ),

          // Lỗi
          if (gs.loi != null)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(gs.loi!,
                  style: const TextStyle(
                      color: Colors.red, fontSize: 12)),
            ),

          const Divider(height: 1),

          // Tổng tiền + nút xuất
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  const Text('Tổng tiền:',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const Spacer(),
                  Text(
                    dinhDangTien(gs.tongTien),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.deepOrange,
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                FilledButton.icon(
                  icon: gs.dangXuat
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.shopping_cart_checkout,
                          size: 18),
                  label: Text(
                      gs.dangXuat ? 'Đang xử lý...' : 'Xuất hàng',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    backgroundColor: gs.coHang
                        ? Colors.deepOrange
                        : Colors.grey.shade400,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed:
                      gs.coHang && !gs.dangXuat ? _xuatHang : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mục trong giỏ hàng
// ─────────────────────────────────────────────────────────────────────────────

class _TheMucGio extends ConsumerStatefulWidget {
  final GioHangMuc muc;
  const _TheMucGio({required this.muc});

  @override
  ConsumerState<_TheMucGio> createState() => _TheMucGioState();
}

class _TheMucGioState extends ConsumerState<_TheMucGio> {
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
  void didUpdateWidget(_TheMucGio oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.muc.soLuong != widget.muc.soLuong && !_focus.hasFocus) {
      _ctrl.text = '${widget.muc.soLuong}';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _commit(String v) {
    final n = int.tryParse(v) ?? widget.muc.soLuong;
    ref
        .read(xuatHangProvider.notifier)
        .capNhatSoLuong(widget.muc.bienTheId, n);
    if (n <= 0) return;
    _ctrl.text = '$n';
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.muc;
    final bienTheInfo = [
      if (m.mauSac.isNotEmpty) m.mauSac,
      if (m.kichCo.isNotEmpty) m.kichCo,
    ].join(' · ');

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
              child: Text(m.tenSanPham,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            GestureDetector(
              onTap: () => ref
                  .read(xuatHangProvider.notifier)
                  .xoaMuc(m.bienTheId),
              child: const Icon(Icons.close,
                  size: 16, color: AppColors.textSecondary),
            ),
          ]),
          if (bienTheInfo.isNotEmpty)
            Text(bienTheInfo,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Row(children: [
            Text(dinhDangTien(m.donGia),
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
            const Spacer(),
            // Điều chỉnh số lượng
            _NutSoLuong(
              icon: Icons.remove,
              onTap: () => ref
                  .read(xuatHangProvider.notifier)
                  .capNhatSoLuong(m.bienTheId, m.soLuong - 1),
            ),
            SizedBox(
              width: 36,
              child: TextField(
                controller: _ctrl,
                focusNode: _focus,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly
                ],
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 4),
                  border: InputBorder.none,
                ),
                onSubmitted: _commit,
                onEditingComplete: () => _commit(_ctrl.text),
              ),
            ),
            _NutSoLuong(
              icon: Icons.add,
              onTap: () => ref
                  .read(xuatHangProvider.notifier)
                  .capNhatSoLuong(m.bienTheId, m.soLuong + 1),
            ),
            const SizedBox(width: 4),
            Text(dinhDangTien(m.thanhTien),
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
        ],
      ),
    );
  }
}

class _NutSoLuong extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NutSoLuong({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.navUnselected,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: AppColors.textPrimary),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Input helper
// ─────────────────────────────────────────────────────────────────────────────

class _OInput extends StatelessWidget {
  final TextEditingController ctrl;
  final FocusNode focus;
  final IconData icon;
  final String hint;
  final TextInputType kieuBanPhim;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  const _OInput({
    required this.ctrl,
    required this.focus,
    required this.icon,
    required this.hint,
    this.kieuBanPhim = TextInputType.text,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      focusNode: focus,
      keyboardType: kieuBanPhim,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        prefixIcon:
            Icon(icon, size: 16, color: AppColors.textSecondary),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog Lệnh nhanh tích hợp vào Xuất hàng
// (override: sau khi parse xong đóng dialog, populate giỏ)
// ─────────────────────────────────────────────────────────────────────────────

class _LenhNhanhXuatDialog extends ConsumerStatefulWidget {
  const _LenhNhanhXuatDialog();

  @override
  ConsumerState<_LenhNhanhXuatDialog> createState() =>
      _LenhNhanhXuatDialogState();
}

class _LenhNhanhXuatDialogState
    extends ConsumerState<_LenhNhanhXuatDialog> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(lenhNhanhProvider.notifier).datLai();
      _focus.requestFocus();
    });
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
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                const Icon(Icons.bolt, size: 20),
                const SizedBox(width: 8),
                const Text('Lệnh nhanh',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context, false),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    enabled: !tt.dangTai,
                    decoration: InputDecoration(
                      hintText: 'vd: chị Mai 1 đôi longden đen 40',
                      hintStyle: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _phanTich(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: tt.dangTai ? null : _phanTich,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navSelected,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
                  ),
                  child: tt.trangThai == TrangThaiLenh.dangPhanTich
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Phân tích'),
                ),
              ]),

              if (tt.trangThai == TrangThaiLenh.xemTruoc &&
                  tt.ketQua != null) ...[
                const SizedBox(height: 16),
                _XemTruocNho(ketQua: tt.ketQua!),
                const SizedBox(height: 14),
                Row(children: [
                  OutlinedButton(
                    onPressed: () {
                      ref.read(lenhNhanhProvider.notifier).datLai();
                      _focus.requestFocus();
                    },
                    child: const Text('Sửa lệnh'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    icon: const Icon(Icons.add_shopping_cart, size: 16),
                    label: const Text('Thêm vào giỏ'),
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.activeGreen),
                    onPressed: tt.ketQua!.gio.isEmpty
                        ? null
                        : () => Navigator.pop(context, true),
                  ),
                ]),
              ],

              if (tt.trangThai == TrangThaiLenh.loi)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      tt.thongBaoLoi ?? 'Lỗi',
                      style: const TextStyle(
                          color: Colors.red, fontSize: 13),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _phanTich() {
    final lenh = _ctrl.text.trim();
    if (lenh.isEmpty) return;
    ref.read(lenhNhanhProvider.notifier).phanTich(lenh);
  }
}

class _XemTruocNho extends StatelessWidget {
  final KetQuaLenhNhanh ketQua;
  const _XemTruocNho({required this.ketQua});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.person_outline,
                size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(ketQua.tenKhach,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
          const SizedBox(height: 8),
          ...ketQua.gio.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
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
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ]),
              )),
          if (ketQua.canhBao.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...ketQua.canhBao.map((w) => Text('⚠ $w',
                style: const TextStyle(
                    fontSize: 11, color: Colors.orange))),
          ],
        ],
      ),
    );
  }
}

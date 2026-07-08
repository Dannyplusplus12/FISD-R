import 'package:fisd_shared/fisd_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session/phien_lam_viec.dart';
import '../../core/theme.dart';
import 'khach_hang_orderer_provider.dart';

class KhachHangOrdererPage extends ConsumerStatefulWidget {
  final PhienLamViec phien;
  const KhachHangOrdererPage({super.key, required this.phien});

  @override
  ConsumerState<KhachHangOrdererPage> createState() => _KhachHangOrdererPageState();
}

class _KhachHangOrdererPageState extends ConsumerState<KhachHangOrdererPage> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(khachHangOrdererProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: AppDeco.input('Tìm khách hàng...', icon: Icons.search),
          ),
        ),
        Expanded(
          child: state.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => errorState(() => ref.invalidate(khachHangOrdererProvider)),
            data: (list) {
              final filtered = _search.isEmpty
                  ? list
                  : list
                      .where((k) =>
                          k.ten.toLowerCase().contains(_search.toLowerCase()) ||
                          k.soDienThoai.contains(_search))
                      .toList();
              if (filtered.isEmpty) {
                return emptyState(Icons.people_outline, 'Chưa có khách hàng',
                    sub: 'Nhấn + để thêm khách hàng');
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(khachHangOrdererProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _KhachCard(
                    khach: filtered[i],
                    onTap: () => _moChiTiet(context, filtered[i]),
                    onSua: () => _suaKhach(context, filtered[i]),
                    onXoa: () => _xoaKhach(context, filtered[i]),
                  ),
                ),
              );
            },
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _themKhach(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _moChiTiet(BuildContext ctx, KhachHang khach) async {
    await Navigator.push(
        ctx, MaterialPageRoute(builder: (_) => _ChiTietKhachPage(khach: khach, phien: widget.phien)));
    ref.invalidate(khachHangOrdererProvider);
  }

  Future<void> _themKhach(BuildContext ctx) async {
    final khuVucs = await ref.read(khuVucOrdererProvider.future);
    if (!ctx.mounted) return;
    await showModalBottomSheet(
        context: ctx,
        isScrollControlled: true,
        builder: (_) => _FormKhachSheet(khuVucs: khuVucs));
    ref.invalidate(khachHangOrdererProvider);
  }

  Future<void> _suaKhach(BuildContext ctx, KhachHang khach) async {
    final khuVucs = await ref.read(khuVucOrdererProvider.future);
    if (!ctx.mounted) return;
    await showModalBottomSheet(
        context: ctx,
        isScrollControlled: true,
        builder: (_) => _FormKhachSheet(edit: khach, khuVucs: khuVucs));
    ref.invalidate(khachHangOrdererProvider);
  }

  Future<void> _xoaKhach(BuildContext ctx, KhachHang khach) async {
    final ok = await showDialog<bool>(
        context: ctx,
        builder: (_) => AlertDialog(
              title: const Text('Xóa khách hàng?'),
              content: Text('Xóa "${khach.ten}"?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Xóa', style: TextStyle(color: AppColors.danger))),
              ],
            ));
    if (ok == true) {
      try {
        await ref.read(khachHangOrdererRepoProvider).xoaKhachHang(khach.id);
        ref.invalidate(khachHangOrdererProvider);
      } catch (_) {
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(content: Text('Lỗi xóa khách hàng'), backgroundColor: AppColors.danger));
        }
      }
    }
  }
}

class _KhachCard extends StatelessWidget {
  final KhachHang khach;
  final VoidCallback onTap;
  final VoidCallback onSua;
  final VoidCallback onXoa;

  const _KhachCard(
      {required this.khach, required this.onTap, required this.onSua, required this.onXoa});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppDeco.card(),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  khach.ten.isNotEmpty ? khach.ten[0].toUpperCase() : '?',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(khach.ten, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(khach.soDienThoai,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                if (khach.tenKhuVuc.isNotEmpty)
                  Text(khach.tenKhuVuc,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ])),
              if (khach.no > 0)
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('Nợ', style: const TextStyle(color: AppColors.danger, fontSize: 11)),
                  Text('${fmtTien(khach.no)}đ',
                      style: const TextStyle(
                          color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 14)),
                ]),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'sua') onSua();
                  if (v == 'xoa') onXoa();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'sua',
                      child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Sửa')])),
                  const PopupMenuItem(
                      value: 'xoa',
                      child: Row(children: [
                        Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                        SizedBox(width: 8),
                        Text('Xóa', style: TextStyle(color: AppColors.danger))
                      ])),
                ],
                child: const Icon(Icons.more_vert, color: AppColors.textSecondary),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Chi tiết khách (công nợ) ─────────────────────────────────────────────────

class _ChiTietKhachPage extends ConsumerWidget {
  final KhachHang khach;
  final PhienLamViec phien;
  const _ChiTietKhachPage({required this.khach, required this.phien});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lichSuNoProvider(khach.id));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(khach.ten, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: Column(children: [
        // Tổng nợ
        Container(
          width: double.infinity,
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Công nợ hiện tại', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 4),
            Text('${fmtTien(khach.no)} đ',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: khach.no > 0 ? AppColors.danger : AppColors.success)),
          ]),
        ),
        Container(height: 1, color: AppColors.divider),
        // Lịch sử
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(children: [
            const Text('Lịch sử công nợ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _themNo(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ghi nợ'),
            ),
          ]),
        ),
        Expanded(child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => errorState(() => ref.invalidate(lichSuNoProvider(khach.id))),
          data: (list) {
            if (list.isEmpty) {
              return emptyState(Icons.account_balance_wallet_outlined, 'Chưa có bản ghi nợ');
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              itemCount: list.length,
              itemBuilder: (_, i) => _NoCard(
                item: list[i],
                khId: khach.id,
                onXoa: () => _xoaNo(context, ref, list[i]),
              ),
            );
          },
        )),
      ]),
    );
  }

  Future<void> _themNo(BuildContext ctx, WidgetRef ref) async {
    await showModalBottomSheet(
        context: ctx,
        isScrollControlled: true,
        builder: (_) => _FormNoSheet(khId: khach.id, nhanVienId: phien.id));
    ref.invalidate(lichSuNoProvider(khach.id));
    ref.invalidate(khachHangOrdererProvider);
  }

  Future<void> _xoaNo(BuildContext ctx, WidgetRef ref, LichSuNoItem item) async {
    final ok = await showDialog<bool>(
        context: ctx,
        builder: (_) => AlertDialog(
              title: const Text('Xóa bản ghi nợ?'),
              content: const Text('Số dư sẽ được hoàn lại.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Xóa', style: TextStyle(color: AppColors.danger))),
              ],
            ));
    if (ok == true) {
      await ref.read(khachHangOrdererRepoProvider).xoaNoItem(khach.id, item.id);
      ref.invalidate(lichSuNoProvider(khach.id));
      ref.invalidate(khachHangOrdererProvider);
    }
  }
}

class _NoCard extends StatelessWidget {
  final LichSuNoItem item;
  final int khId;
  final VoidCallback onXoa;
  const _NoCard({required this.item, required this.khId, required this.onXoa});

  @override
  Widget build(BuildContext context) {
    final tangNo = item.thayDoi > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppDeco.card(),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (tangNo ? AppColors.danger : AppColors.success).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              tangNo ? Icons.trending_up : Icons.trending_down,
              color: tangNo ? AppColors.danger : AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.ghiChu.isNotEmpty ? item.ghiChu : (tangNo ? 'Tăng nợ' : 'Trả nợ'),
                style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('${item.ngayTao}  •  ${item.tenNhanVien}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              '${tangNo ? "+" : ""}${fmtTien(item.thayDoi)}đ',
              style: TextStyle(
                  color: tangNo ? AppColors.danger : AppColors.success,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
            Text('Còn: ${fmtTien(item.soDuMoi)}đ',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ]),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onXoa,
            child: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
          ),
        ]),
      ),
    );
  }
}

class _FormNoSheet extends ConsumerStatefulWidget {
  final int khId;
  final int nhanVienId;
  const _FormNoSheet({required this.khId, required this.nhanVienId});

  @override
  ConsumerState<_FormNoSheet> createState() => _FormNoSheetState();
}

class _FormNoSheetState extends ConsumerState<_FormNoSheet> {
  final _soTienCtrl = TextEditingController();
  final _ghiChuCtrl = TextEditingController();
  bool _tangNo = true;
  bool _loading = false;

  @override
  void dispose() {
    _soTienCtrl.dispose();
    _ghiChuCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20, right: 20, top: 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
        Row(children: [
          const Text('Ghi công nợ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ]),
        const SizedBox(height: 12),
        // Loại nợ
        Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tangNo = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _tangNo ? AppColors.danger.withOpacity(0.1) : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: _tangNo ? AppColors.danger : AppColors.divider, width: 1.5),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.trending_up,
                      color: _tangNo ? AppColors.danger : AppColors.textSecondary, size: 18),
                  const SizedBox(width: 6),
                  Text('Tăng nợ',
                      style: TextStyle(
                          color: _tangNo ? AppColors.danger : AppColors.textSecondary,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tangNo = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_tangNo ? AppColors.success.withOpacity(0.1) : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: !_tangNo ? AppColors.success : AppColors.divider, width: 1.5),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.trending_down,
                      color: !_tangNo ? AppColors.success : AppColors.textSecondary, size: 18),
                  const SizedBox(width: 6),
                  Text('Trả nợ',
                      style: TextStyle(
                          color: !_tangNo ? AppColors.success : AppColors.textSecondary,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        TextField(
          controller: _soTienCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: AppDeco.input('Số tiền (đ) *', icon: Icons.attach_money_outlined),
          autofocus: true,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _ghiChuCtrl,
          decoration: AppDeco.input('Ghi chú', icon: Icons.notes_outlined),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _loading ? null : _luu,
          style: AppDeco.primaryBtn,
          child: _loading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Lưu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  Future<void> _luu() async {
    final soTien = int.tryParse(_soTienCtrl.text.trim()) ?? 0;
    if (soTien <= 0) return;
    setState(() => _loading = true);
    try {
      await ref.read(khachHangOrdererRepoProvider).themNoItem(
            khId: widget.khId,
            nhanVienId: widget.nhanVienId,
            soTien: _tangNo ? soTien : -soTien,
            ghiChu: _ghiChuCtrl.text.trim(),
          );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ── Form khách hàng ──────────────────────────────────────────────────────────

class _FormKhachSheet extends ConsumerStatefulWidget {
  final KhachHang? edit;
  final List<TomTatKhuVuc> khuVucs;
  const _FormKhachSheet({this.edit, required this.khuVucs});

  @override
  ConsumerState<_FormKhachSheet> createState() => _FormKhachSheetState();
}

class _FormKhachSheetState extends ConsumerState<_FormKhachSheet> {
  final _tenCtrl = TextEditingController();
  final _sdtCtrl = TextEditingController();
  int? _khuVucId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.edit != null) {
      _tenCtrl.text = widget.edit!.ten;
      _sdtCtrl.text = widget.edit!.soDienThoai;
      _khuVucId = widget.edit!.khuVucId;
    }
  }

  @override
  void dispose() {
    _tenCtrl.dispose();
    _sdtCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20, right: 20, top: 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
        Row(children: [
          Text(widget.edit == null ? 'Thêm khách hàng' : 'Sửa khách hàng',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ]),
        const SizedBox(height: 16),
        TextField(controller: _tenCtrl, decoration: AppDeco.input('Tên khách *', icon: Icons.person_outline)),
        const SizedBox(height: 10),
        TextField(
          controller: _sdtCtrl,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: AppDeco.input('Số điện thoại', icon: Icons.phone_outlined),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<int>(
          value: _khuVucId,
          decoration: AppDeco.input('Khu vực', icon: Icons.map_outlined),
          items: [
            const DropdownMenuItem<int>(value: null, child: Text('Không chọn')),
            ...widget.khuVucs
                .map((kv) => DropdownMenuItem<int>(value: kv.id, child: Text(kv.ten))),
          ],
          onChanged: (v) => setState(() => _khuVucId = v),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _loading ? null : _luu,
          style: AppDeco.primaryBtn,
          child: _loading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Lưu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  Future<void> _luu() async {
    final ten = _tenCtrl.text.trim();
    if (ten.isEmpty) return;
    setState(() => _loading = true);
    try {
      if (widget.edit != null) {
        await ref.read(khachHangOrdererRepoProvider).capNhatKhachHang(
              id: widget.edit!.id,
              ten: ten,
              soDt: _sdtCtrl.text.trim(),
              khuVucId: _khuVucId,
            );
      } else {
        await ref.read(khachHangOrdererRepoProvider).taoKhachHang(
              ten: ten,
              soDt: _sdtCtrl.text.trim(),
              khuVucId: _khuVucId,
            );
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }
}

import 'package:fisd_shared/fisd_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../xac_thuc/xac_thuc_provider.dart';
import '../kho_hang/kho_hang_provider.dart';
import '../kho_hang/chi_tiet_kho_page.dart';
import 'san_pham_orderer_page.dart';
import 'san_pham_orderer_provider.dart';

class KhoOrdererPage extends ConsumerStatefulWidget {
  const KhoOrdererPage({super.key});

  @override
  ConsumerState<KhoOrdererPage> createState() => _KhoOrdererPageState();
}

class _KhoOrdererPageState extends ConsumerState<KhoOrdererPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kho & Sản phẩm', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Đăng xuất',
            onPressed: () => ref.read(xacThucProvider.notifier).dangXuat(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(children: [
            Container(height: 1, color: AppColors.divider),
            TabBar(
              controller: _tab,
              tabs: const [Tab(text: 'Sản phẩm'), Tab(text: 'Kho hàng')],
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.label,
            ),
          ]),
        ),
      ),
      floatingActionButton: _tab.index == 0
          ? FloatingActionButton(
              onPressed: () => _themSanPham(context),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : FloatingActionButton(
              onPressed: () => _themKho(context),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _SanPhamContent(),
          _KhoContent(),
        ],
      ),
    );
  }

  Future<void> _themSanPham(BuildContext ctx) async {
    await Navigator.push(ctx, MaterialPageRoute(builder: (_) => const FormSanPhamPage()));
    ref.invalidate(sanPhamOrdererProvider);
  }

  Future<void> _themKho(BuildContext ctx) async {
    await showModalBottomSheet(
        context: ctx, isScrollControlled: true, builder: (_) => const _FormKhoInline());
    ref.invalidate(danhSachKhoProvider);
  }
}

// ── Tab sản phẩm ─────────────────────────────────────────────────────────────

class _SanPhamContent extends ConsumerStatefulWidget {
  const _SanPhamContent();

  @override
  ConsumerState<_SanPhamContent> createState() => _SanPhamContentState();
}

class _SanPhamContentState extends ConsumerState<_SanPhamContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _search = '';

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(sanPhamOrdererProvider);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: TextField(
          onChanged: (v) => setState(() => _search = v),
          decoration: AppDeco.input('Tìm sản phẩm...', icon: Icons.search),
        ),
      ),
      Expanded(
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => errorState(() => ref.invalidate(sanPhamOrdererProvider)),
          data: (list) {
            final filtered = _search.isEmpty
                ? list
                : list
                    .where((sp) =>
                        sp.ten.toLowerCase().contains(_search.toLowerCase()) ||
                        sp.ma.toLowerCase().contains(_search.toLowerCase()))
                    .toList();
            if (filtered.isEmpty) return emptyState(Icons.inventory_2_outlined, 'Không có sản phẩm');
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(sanPhamOrdererProvider),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: filtered.length,
                itemBuilder: (_, i) => _SanPhamCard(
                  sp: filtered[i],
                  onSua: () => _suaSanPham(context, filtered[i]),
                  onXoa: () => _xoaSanPham(context, filtered[i]),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }

  Future<void> _suaSanPham(BuildContext ctx, SanPham sp) async {
    await Navigator.push(ctx, MaterialPageRoute(builder: (_) => FormSanPhamPage(edit: sp)));
    ref.invalidate(sanPhamOrdererProvider);
  }

  Future<void> _xoaSanPham(BuildContext ctx, SanPham sp) async {
    final ok = await showDialog<bool>(
        context: ctx,
        builder: (_) => AlertDialog(
              title: const Text('Xóa sản phẩm?'),
              content: Text('Xóa "${sp.ten}"?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Xóa', style: TextStyle(color: AppColors.danger))),
              ],
            ));
    if (ok == true && ctx.mounted) {
      try {
        await ref.read(sanPhamOrdererRepoProvider).xoaSanPham(sp.id);
        ref.invalidate(sanPhamOrdererProvider);
      } catch (_) {
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
              content: Text('Lỗi xóa sản phẩm'), backgroundColor: AppColors.danger));
        }
      }
    }
  }
}

class _SanPhamCard extends StatelessWidget {
  final SanPham sp;
  final VoidCallback onSua;
  final VoidCallback onXoa;
  const _SanPhamCard({required this.sp, required this.onSua, required this.onXoa});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppDeco.card(),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onSua,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: sp.anh.isNotEmpty
                    ? Image.network(sp.anh,
                        width: 56, height: 56, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _iconSP())
                    : _iconSP(),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(sp.ten, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(sp.ma, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text(sp.khoangGia, style: const TextStyle(color: AppColors.primary, fontSize: 13)),
                Text('${sp.bienThes.length} biến thể  •  Tổng: ${sp.tongTonKho}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ])),
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

  Widget _iconSP() => Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
      child: const Icon(Icons.image_outlined, color: AppColors.textSecondary, size: 24));
}

// ── Tab kho hàng ─────────────────────────────────────────────────────────────

class _KhoContent extends ConsumerStatefulWidget {
  const _KhoContent();

  @override
  ConsumerState<_KhoContent> createState() => _KhoContentState();
}

class _KhoContentState extends ConsumerState<_KhoContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(danhSachKhoProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => errorState(() => ref.invalidate(danhSachKhoProvider)),
      data: (khos) {
        if (khos.isEmpty) {
          return emptyState(Icons.store_outlined, 'Chưa có kho nào', sub: 'Nhấn + để thêm kho mới');
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(danhSachKhoProvider),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: khos.length,
            itemBuilder: (_, i) => _KhoCard(
              kho: khos[i],
              onTap: () => _moChiTiet(context, khos[i]),
              onSua: () => _suaKho(context, khos[i]),
              onXoa: () => _xoaKho(context, khos[i]),
            ),
          ),
        );
      },
    );
  }

  Future<void> _moChiTiet(BuildContext ctx, KhoHang kho) async {
    await Navigator.push(
        ctx, MaterialPageRoute(builder: (_) => ChiTietKhoPage(kho: kho, readOnly: false)));
    ref.invalidate(danhSachKhoProvider);
  }

  Future<void> _suaKho(BuildContext ctx, KhoHang kho) async {
    await showModalBottomSheet(
        context: ctx,
        isScrollControlled: true,
        builder: (_) => _FormKhoInline(edit: kho));
    ref.invalidate(danhSachKhoProvider);
  }

  Future<void> _xoaKho(BuildContext ctx, KhoHang kho) async {
    final ok = await showDialog<bool>(
        context: ctx,
        builder: (_) => AlertDialog(
              title: const Text('Xóa kho?'),
              content: Text('Xóa kho "${kho.ten}"?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Xóa', style: TextStyle(color: AppColors.danger))),
              ],
            ));
    if (ok == true) {
      await ref.read(khoHangActionProvider.notifier).xoaKho(kho.id);
      ref.invalidate(danhSachKhoProvider);
    }
  }
}

class _KhoCard extends StatelessWidget {
  final KhoHang kho;
  final VoidCallback onTap;
  final VoidCallback onSua;
  final VoidCallback onXoa;
  const _KhoCard({required this.kho, required this.onTap, required this.onSua, required this.onXoa});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppDeco.card(),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.store_outlined, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(kho.ten, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                if (kho.viTri.isNotEmpty)
                  Text(kho.viTri, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ])),
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

// ── Form kho inline ──────────────────────────────────────────────────────────

class _FormKhoInline extends ConsumerStatefulWidget {
  final KhoHang? edit;
  const _FormKhoInline({this.edit});

  @override
  ConsumerState<_FormKhoInline> createState() => _FormKhoInlineState();
}

class _FormKhoInlineState extends ConsumerState<_FormKhoInline> {
  final _tenCtrl = TextEditingController();
  final _viTriCtrl = TextEditingController();
  final _ghiChuCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.edit != null) {
      _tenCtrl.text = widget.edit!.ten;
      _viTriCtrl.text = widget.edit!.viTri;
      _ghiChuCtrl.text = widget.edit!.ghiChu;
    }
  }

  @override
  void dispose() {
    _tenCtrl.dispose();
    _viTriCtrl.dispose();
    _ghiChuCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20, right: 20, top: 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Text(widget.edit == null ? 'Thêm kho mới' : 'Sửa kho',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ]),
        const SizedBox(height: 16),
        TextField(controller: _tenCtrl, decoration: AppDeco.input('Tên kho *', icon: Icons.store_outlined)),
        const SizedBox(height: 10),
        TextField(controller: _viTriCtrl, decoration: AppDeco.input('Vị trí', icon: Icons.location_on_outlined)),
        const SizedBox(height: 10),
        TextField(controller: _ghiChuCtrl, decoration: AppDeco.input('Ghi chú', icon: Icons.notes_outlined)),
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
    if (widget.edit != null) {
      await ref.read(khoHangActionProvider.notifier)
          .capNhatKho(widget.edit!.id, ten, _viTriCtrl.text.trim(), _ghiChuCtrl.text.trim());
    } else {
      await ref.read(khoHangActionProvider.notifier)
          .taoKho(ten, _viTriCtrl.text.trim(), _ghiChuCtrl.text.trim());
    }
    if (mounted) Navigator.pop(context);
  }
}

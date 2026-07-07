import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import 'package:fisd_shared/core/format_tien.dart';
import 'package:fisd_shared/models/don_hang.dart';
import '../lenh_nhanh/lenh_nhanh_dialog.dart';
import 'don_hang_provider.dart';
import 'sua_don_dialog.dart';

class DonHangPage extends ConsumerStatefulWidget {
  const DonHangPage({super.key});

  @override
  ConsumerState<DonHangPage> createState() => _DonHangPageState();
}

class _DonHangPageState extends ConsumerState<DonHangPage> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() { super.initState(); _tabs = TabController(length: 2, vsync: this); }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(children: [
              const Text('Đơn Hàng', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
                onPressed: () {
                  ref.read(quanLyDonHangProvider.notifier).lamMoi();
                  ref.read(donHangChoProvider.notifier).lamMoi();
                },
              ),
              const SizedBox(width: 4),
              FilledButton.icon(
                icon: const Icon(Icons.bolt, size: 16),
                label: const Text('Lệnh nhanh'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navSelected,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                onPressed: () async {
                  final donId = await moLenhNhanhDialog(context);
                  if (donId != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã tạo đơn #$donId — chờ duyệt'),
                        backgroundColor: AppColors.activeGreen,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
              ),
            ]),
          ),
          TabBar(
            controller: _tabs,
            labelColor: AppColors.navSelected,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.navSelected,
            tabs: const [Tab(text: 'Lịch sử'), Tab(text: 'Chờ duyệt')],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                const _TabLichSu(),
                const _TabChoDuyet(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabLichSu extends ConsumerWidget {
  const _TabLichSu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donHangAsync = ref.watch(quanLyDonHangProvider);
    return donHangAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _LoiHienThi(thongBao: e.toString(),
          thuLai: () => ref.read(quanLyDonHangProvider.notifier).lamMoi()),
      data: (ds) => ds.isEmpty
          ? const Center(child: Text('Chưa có đơn hàng nào', style: TextStyle(color: AppColors.textSecondary)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: ds.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _TheDonHang(
                donHang: ds[i],
                onHuy: () => ref.read(quanLyDonHangProvider.notifier).huy(ds[i].id),
                onSua: ds[i].dangCho ? () async {
                  final ok = await moSuaDonDialog(context, ds[i]);
                  if (ok == true) {
                    ref.read(quanLyDonHangProvider.notifier).lamMoi();
                    ref.read(donHangChoProvider.notifier).lamMoi();
                  }
                } : null,
              ),
            ),
    );
  }
}

class _TabChoDuyet extends ConsumerWidget {
  const _TabChoDuyet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donHangAsync = ref.watch(donHangChoProvider);
    return donHangAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _LoiHienThi(thongBao: e.toString(),
          thuLai: () => ref.read(donHangChoProvider.notifier).lamMoi()),
      data: (ds) => ds.isEmpty
          ? const Center(child: Text('Không có đơn chờ duyệt', style: TextStyle(color: AppColors.textSecondary)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: ds.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _TheDonHang(
                donHang: ds[i],
                onDuyet: () => ref.read(donHangChoProvider.notifier).duyet(ds[i].id),
                onTuChoi: () => ref.read(donHangChoProvider.notifier).tuChoi(ds[i].id),
                onSua: () async {
                  final ok = await moSuaDonDialog(context, ds[i]);
                  if (ok == true) {
                    ref.read(quanLyDonHangProvider.notifier).lamMoi();
                    ref.read(donHangChoProvider.notifier).lamMoi();
                  }
                },
              ),
            ),
    );
  }
}

class _TheDonHang extends StatelessWidget {
  final DonHang donHang;
  final VoidCallback? onDuyet;
  final VoidCallback? onTuChoi;
  final VoidCallback? onHuy;
  final VoidCallback? onSua;

  const _TheDonHang({required this.donHang, this.onDuyet, this.onTuChoi, this.onHuy, this.onSua});

  @override
  Widget build(BuildContext context) {
    final mauTT = _mauTrangThai(donHang.trangThai);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('#${donHang.id} — ${donHang.tenKhachHang}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: mauTT.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(donHang.nhanTrangThai,
                style: TextStyle(fontSize: 11, color: mauTT, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 6),
        Text('${dinhDangTien(donHang.tongTien)}  •  ${donHang.tongSoLuong} sản phẩm',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Text(donHang.ngayTao, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        if (onDuyet != null || onTuChoi != null || onHuy != null || onSua != null) ...[
          const SizedBox(height: 10),
          Row(children: [
            if (onSua != null) _NutHanhDong(nhan: 'Sửa', mau: Colors.indigo, onNhan: onSua!),
            if (onDuyet != null) ...[if (onSua != null) const SizedBox(width: 8), _NutHanhDong(nhan: 'Duyệt', mau: AppColors.activeGreen, onNhan: onDuyet!)],
            if (onTuChoi != null) ...[const SizedBox(width: 8), _NutHanhDong(nhan: 'Từ chối', mau: Colors.red, onNhan: onTuChoi!)],
            if (onHuy != null) ...[const SizedBox(width: 8), _NutHanhDong(nhan: 'Hủy', mau: Colors.orange, onNhan: onHuy!)],
          ]),
        ],
      ]),
    );
  }

  Color _mauTrangThai(String tt) {
    switch (tt) {
      case 'pending': return Colors.orange;
      case 'approved': return Colors.blue;
      case 'assigned': return Colors.purple;
      case 'completed': return AppColors.activeGreen;
      default: return AppColors.textSecondary;
    }
  }
}

class _NutHanhDong extends StatelessWidget {
  final String nhan;
  final Color mau;
  final VoidCallback onNhan;

  const _NutHanhDong({required this.nhan, required this.mau, required this.onNhan});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onNhan,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: mau.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: mau.withOpacity(0.4)),
        ),
        child: Text(nhan, style: TextStyle(fontSize: 12, color: mau, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _LoiHienThi extends StatelessWidget {
  final String thongBao;
  final VoidCallback thuLai;

  const _LoiHienThi({required this.thongBao, required this.thuLai});

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, size: 48, color: Colors.red),
      const SizedBox(height: 8),
      Text(thongBao, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: thuLai, child: const Text('Thử lại')),
    ]));
  }
}

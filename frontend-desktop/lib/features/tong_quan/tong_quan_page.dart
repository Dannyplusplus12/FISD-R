import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import 'package:fisd_shared/core/format_tien.dart';
import 'package:fisd_shared/models/don_hang.dart';
import '../san_pham/san_pham_provider.dart';
import '../khach_hang/khach_hang_provider.dart';
import '../don_hang/don_hang_provider.dart';

class TongQuanPage extends ConsumerWidget {
  const TongQuanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sanPhamAsync = ref.watch(sanPhamProvider);
    final khachHangAsync = ref.watch(khachHangProvider);
    final donHangAsync = ref.watch(quanLyDonHangProvider);
    final choDuyetAsync = ref.watch(donHangChoProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tổng Quan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text('Dữ liệu thời gian thực từ máy chủ',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            Expanded(
              flex: 50,
              child: Column(
                children: [
                  Expanded(
                    child: Row(children: [
                      Expanded(
                        child: _TheThongKe(
                          tieuDe: 'Sản Phẩm',
                          bieu_tuong: Icons.inventory_2_outlined,
                          asyncValue: sanPhamAsync,
                          layGiaTri: (ds) => '${ds.length}',
                          layPhuDe: (ds) {
                            final tong = ds.fold<int>(0, (t, p) => t + p.tongTonKho);
                            return 'Tổng tồn: $tong';
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TheThongKe(
                          tieuDe: 'Khách Hàng',
                          bieu_tuong: Icons.people_outline,
                          asyncValue: khachHangAsync,
                          layGiaTri: (ds) => '${ds.length}',
                          layPhuDe: (ds) {
                            final no = ds.fold<int>(0, (t, k) => t + k.no);
                            return 'Nợ: ${dinhDangTien(no)}';
                          },
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Row(children: [
                      Expanded(
                        child: _TheThongKe(
                          tieuDe: 'Đơn Hoàn Thành',
                          bieu_tuong: Icons.check_circle_outline,
                          asyncValue: donHangAsync,
                          layGiaTri: (ds) => '${ds.where((o) => o.hoanThanh).length}',
                          layPhuDe: (ds) {
                            final doanhThu = ds.where((o) => o.hoanThanh).fold<int>(0, (t, o) => t + o.tongTien);
                            return dinhDangTien(doanhThu);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TheThongKe(
                          tieuDe: 'Chờ Duyệt',
                          bieu_tuong: Icons.pending_outlined,
                          asyncValue: choDuyetAsync,
                          layGiaTri: (ds) => '${ds.length}',
                          layPhuDe: (ds) => ds.isEmpty ? 'Không có đơn nào' : 'Cần xét duyệt',
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(flex: 50, child: _DonHangGanDay(donHangAsync: donHangAsync)),
          ],
        ),
      ),
    );
  }
}

class _TheThongKe<T> extends StatelessWidget {
  final String tieuDe;
  final IconData bieu_tuong;
  final AsyncValue<T> asyncValue;
  final String Function(T) layGiaTri;
  final String Function(T) layPhuDe;

  const _TheThongKe({
    required this.tieuDe,
    required this.bieu_tuong,
    required this.asyncValue,
    required this.layGiaTri,
    required this.layPhuDe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 12, offset: Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(bieu_tuong, color: AppColors.textSecondary, size: 18),
          asyncValue.when(
            loading: () => const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            error: (_, __) => const Icon(Icons.error_outline, size: 20, color: Colors.red),
            data: (du_lieu) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(layGiaTri(du_lieu), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 1),
                Text(tieuDe, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(layPhuDe(du_lieu),
                    style: const TextStyle(fontSize: 10, color: AppColors.activeGreen, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DonHangGanDay extends StatelessWidget {
  final AsyncValue<List<DonHang>> donHangAsync;

  const _DonHangGanDay({required this.donHangAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 12, offset: Offset(0, 6))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Đơn Hàng Gần Đây', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Expanded(
              child: donHangAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text(e.toString())),
                data: (ds) {
                  final ganDay = ds.take(10).toList();
                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: ganDay.length,
                    itemBuilder: (_, i) {
                      final don = ganDay[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(children: [
                          Container(width: 6, height: 6,
                              decoration: BoxDecoration(color: _mauTrangThai(don.trangThai), shape: BoxShape.circle)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text('#${don.id} ${don.tenKhachHang}',
                                style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                          ),
                          Text(dinhDangTien(don.tongTien),
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ]),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
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

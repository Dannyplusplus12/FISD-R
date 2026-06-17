import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme.dart';
import '../../../core/format_tien.dart';
import '../../../models/bao_cao.dart';
import '../../../models/khach_hang.dart';
import '../../khach_hang/khach_hang_provider.dart';
import 'bao_cao_provider.dart';
import 'bao_cao_repository.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

String _fmtNgayHien(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

// "2026-05-18" → "18/05"
String _fmtNhanTrucX(String ngay) {
  if (ngay.length < 10) return ngay;
  return '${ngay.substring(8, 10)}/${ngay.substring(5, 7)}';
}

// "2026-05-18" → "18/05/2026"
String _fmtNgayDay(String ngay) {
  if (ngay.length < 10) return ngay;
  return '${ngay.substring(8, 10)}/${ngay.substring(5, 7)}/${ngay.substring(0, 4)}';
}

String _fmtCompact(double v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(0)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
  return v.toInt().toString();
}

double _khoangNhan(int n) {
  if (n <= 14) return 1;
  if (n <= 60) return 7;
  return 30;
}

// ── Main Page ─────────────────────────────────────────────────────────────────

class BaoCaoPage extends ConsumerWidget {
  const BaoCaoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(locBaoCaoProvider);
    final metric = ref.watch(metricBieuDoProvider);
    final baoCaoAsync = ref.watch(baoCaoProvider);
    final khuVucAsync = ref.watch(khuVucProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ThanhLoc(loc: loc, khuVucAsync: khuVucAsync),
          const SizedBox(height: 16),
          baoCaoAsync.when(
            loading: () => const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: CircularProgressIndicator(),
            )),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('Lỗi tải dữ liệu: $e',
                  style: const TextStyle(color: Colors.red))),
            ),
            data: (bc) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CacThe(baoCao: bc, metric: metric),
                const SizedBox(height: 16),
                _BieuDo(baoCao: bc, metric: metric, loc: loc),
                const SizedBox(height: 16),
                _HaiBang(baoCao: bc),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter Bar ────────────────────────────────────────────────────────────────

class _ThanhLoc extends ConsumerWidget {
  final TrangLocBaoCao loc;
  final AsyncValue<List<TomTatKhuVuc>> khuVucAsync;

  const _ThanhLoc({required this.loc, required this.khuVucAsync});

  Future<void> _chonNgayTuyChinh(BuildContext context, WidgetRef ref) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: loc.tuNgay, end: loc.denNgay),
      locale: const Locale('vi', 'VN'),
    );
    if (range != null && context.mounted) {
      ref.read(locBaoCaoProvider.notifier).chonNgay(range.start, range.end);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dsKhuVuc = khuVucAsync.valueOrNull ?? [];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Dropdown khu vực
        _ODropdown<int?>(
          nhan: 'Khu vực',
          giaTri: loc.khuVucId,
          cacLuaChon: [
            const DropdownMenuItem<int?>(value: null, child: Text('Tất cả')),
            ...dsKhuVuc.map((kv) => DropdownMenuItem<int?>(value: kv.id, child: Text(kv.ten))),
          ],
          onThayDoi: (v) => ref.read(locBaoCaoProvider.notifier).chonKhuVuc(v),
        ),
        // Dropdown khoảng thời gian
        _ODropdown<KhoangThoiGian>(
          nhan: 'Khoảng',
          giaTri: loc.khoang,
          cacLuaChon: const [
            DropdownMenuItem(value: KhoangThoiGian.thangNay, child: Text('Tháng này')),
            DropdownMenuItem(value: KhoangThoiGian.tuanNay, child: Text('Tuần này')),
            DropdownMenuItem(value: KhoangThoiGian.quyNay, child: Text('Quý này')),
            DropdownMenuItem(value: KhoangThoiGian.namNay, child: Text('Năm này')),
            DropdownMenuItem(value: KhoangThoiGian.tuyChinh, child: Text('Tùy chỉnh')),
          ],
          onThayDoi: (v) {
            if (v == null) return;
            if (v == KhoangThoiGian.tuyChinh) {
              _chonNgayTuyChinh(context, ref);
            } else {
              ref.read(locBaoCaoProvider.notifier).chonKhoang(v);
            }
          },
        ),
        // Hiển thị ngày
        if (loc.khoang == KhoangThoiGian.tuyChinh)
          InkWell(
            onTap: () => _chonNgayTuyChinh(context, ref),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    '${_fmtNgayHien(loc.tuNgay)} → ${_fmtNgayHien(loc.denNgay)}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Text(
              '${_fmtNgayHien(loc.tuNgay)} → ${_fmtNgayHien(loc.denNgay)}',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
      ],
    );
  }
}

class _ODropdown<T> extends StatelessWidget {
  final String nhan;
  final T giaTri;
  final List<DropdownMenuItem<T>> cacLuaChon;
  final ValueChanged<T?> onThayDoi;

  const _ODropdown({
    required this.nhan,
    required this.giaTri,
    required this.cacLuaChon,
    required this.onThayDoi,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: AppColors.surface,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$nhan: ', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: giaTri,
              items: cacLuaChon,
              onChanged: onThayDoi,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              iconSize: 18,
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat Cards ────────────────────────────────────────────────────────────────

class _CacThe extends ConsumerWidget {
  final BaoCao baoCao;
  final MetricBieuDo metric;

  const _CacThe({required this.baoCao, required this.metric});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void chon(MetricBieuDo m) => ref.read(metricBieuDoProvider.notifier).state = m;

    return Row(
      children: [
        Expanded(child: _The(
          tieuDe: 'Doanh Thu',
          giaTri: dinhDangTien(baoCao.tongDoanhThu),
          mauVien: Colors.red.shade400,
          daChon: metric == MetricBieuDo.doanhThu,
          onNhan: () => chon(MetricBieuDo.doanhThu),
        )),
        const SizedBox(width: 10),
        Expanded(child: _The(
          tieuDe: 'Số Đơn Hàng',
          giaTri: '${baoCao.soDonHang}',
          mauVien: Colors.blue.shade400,
          daChon: metric == MetricBieuDo.soDon,
          onNhan: () => chon(MetricBieuDo.soDon),
        )),
        const SizedBox(width: 10),
        Expanded(child: _The(
          tieuDe: 'Sản Phẩm Đã Bán',
          giaTri: '${baoCao.sanPhamDaBan}',
          mauVien: Colors.green.shade500,
          daChon: metric == MetricBieuDo.sanPhamDaBan,
          onNhan: () => chon(MetricBieuDo.sanPhamDaBan),
        )),
        const SizedBox(width: 10),
        Expanded(child: _The(
          tieuDe: 'Khách Hàng',
          giaTri: '${baoCao.soKhachHang}',
          mauVien: Colors.orange.shade400,
          daChon: metric == MetricBieuDo.soKhachHang,
          onNhan: () => chon(MetricBieuDo.soKhachHang),
        )),
      ],
    );
  }
}

class _The extends StatelessWidget {
  final String tieuDe;
  final String giaTri;
  final Color mauVien;
  final bool daChon;
  final VoidCallback onNhan;

  const _The({
    required this.tieuDe,
    required this.giaTri,
    required this.mauVien,
    required this.daChon,
    required this.onNhan,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onNhan,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: daChon ? mauVien : Colors.transparent, width: 4)),
          boxShadow: [
            if (daChon)
              BoxShadow(color: mauVien.withAlpha(51), blurRadius: 10, offset: const Offset(0, 4))
            else
              const BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tieuDe, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Text(
              giaTri,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: daChon ? mauVien : AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Line Chart ────────────────────────────────────────────────────────────────

class _BieuDo extends ConsumerStatefulWidget {
  final BaoCao baoCao;
  final MetricBieuDo metric;
  final TrangLocBaoCao loc;

  const _BieuDo({required this.baoCao, required this.metric, required this.loc});

  @override
  ConsumerState<_BieuDo> createState() => _BieuDoState();
}

class _BieuDoState extends ConsumerState<_BieuDo> {
  int? _chiSoTouch;

  List<FlSpot> _buildSpots(List<DiemBieuDo> ds) {
    return ds.asMap().entries.map((entry) {
      final i = entry.key;
      final d = entry.value;
      final double y = switch (widget.metric) {
        MetricBieuDo.doanhThu => d.doanhThu.toDouble(),
        MetricBieuDo.soDon => d.soDon.toDouble(),
        MetricBieuDo.sanPhamDaBan => d.soSanPham.toDouble(),
        MetricBieuDo.soKhachHang => d.soKhach.toDouble(),
      };
      return FlSpot(i.toDouble(), y);
    }).toList();
  }

  Color get _mau => switch (widget.metric) {
        MetricBieuDo.doanhThu => Colors.red.shade400,
        MetricBieuDo.soDon => Colors.blue.shade400,
        MetricBieuDo.sanPhamDaBan => Colors.green.shade500,
        MetricBieuDo.soKhachHang => Colors.orange.shade400,
      };

  String get _tenMetric => switch (widget.metric) {
        MetricBieuDo.doanhThu => 'Doanh Thu',
        MetricBieuDo.soDon => 'Số Đơn Hàng',
        MetricBieuDo.sanPhamDaBan => 'Sản Phẩm Đã Bán',
        MetricBieuDo.soKhachHang => 'Khách Hàng',
      };

  String _formatGiaTriTooltip(double v) => switch (widget.metric) {
        MetricBieuDo.doanhThu => dinhDangTien(v.toInt()),
        _ => v.toInt().toString(),
      };

  void _moPopupNgay(BuildContext context, String ngay) {
    final repo = ref.read(baoCaoRepositoryProvider);
    final khuVucId = widget.loc.khuVucId;
    showDialog(
      context: context,
      builder: (_) => _PopupChiTietNgay(
        ngay: ngay,
        khuVucId: khuVucId,
        repo: repo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ds = widget.baoCao.theoDiem;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$_tenMetric Theo Ngày',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: ds.isEmpty
                ? const Center(
                    child: Text('Không có dữ liệu trong khoảng thời gian này',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13)))
                : Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: ds.length > 1 ? (ds.length - 1).toDouble() : 1,
                        lineTouchData: LineTouchData(
                          handleBuiltInTouches: true,
                          touchCallback: (event, response) {
                            final spot = response?.lineBarSpots?.firstOrNull;
                            if (spot != null) {
                              setState(() => _chiSoTouch = spot.spotIndex);
                            }
                            if (event is FlTapUpEvent && spot != null) {
                              final idx = spot.spotIndex;
                              if (idx >= 0 && idx < ds.length) {
                                _moPopupNgay(context, ds[idx].ngay);
                              }
                            }
                          },
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (_) => AppColors.surface,
                            tooltipBorder: BorderSide(color: Colors.grey.shade200),
                            tooltipRoundedRadius: 8,
                            fitInsideHorizontally: true,
                            fitInsideVertically: true,
                            getTooltipItems: (spots) => spots.map((spot) {
                              final idx = spot.spotIndex;
                              if (idx < 0 || idx >= ds.length) return null;
                              return LineTooltipItem(
                                '${_fmtNhanTrucX(ds[idx].ngay)}\n${_formatGiaTriTooltip(spot.y)}',
                                TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _mau,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: Colors.grey.shade200,
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: _khoangNhan(ds.length),
                              reservedSize: 28,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx < 0 || idx >= ds.length) return const SizedBox();
                                if (ds.length > 1 &&
                                    idx % _khoangNhan(ds.length).toInt() != 0 &&
                                    idx != ds.length - 1) {
                                  return const SizedBox();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    _fmtNhanTrucX(ds[idx].ngay),
                                    style: const TextStyle(
                                        fontSize: 10, color: AppColors.textSecondary),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 52,
                              getTitlesWidget: (value, meta) {
                                if (value == meta.max) return const SizedBox();
                                return Text(
                                  widget.metric == MetricBieuDo.doanhThu
                                      ? _fmtCompact(value)
                                      : value.toInt().toString(),
                                  style: const TextStyle(
                                      fontSize: 10, color: AppColors.textSecondary),
                                  textAlign: TextAlign.right,
                                );
                              },
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _buildSpots(ds),
                            isCurved: true,
                            curveSmoothness: 0.3,
                            color: _mau,
                            barWidth: 2,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                                radius: index == _chiSoTouch ? 5 : 3,
                                color: _mau,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              ),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: _mau.withAlpha(18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app, size: 12, color: AppColors.textSecondary),
              SizedBox(width: 4),
              Text('Bấm vào điểm để xem chi tiết hóa đơn trong ngày',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Popup: Orders in a Day ────────────────────────────────────────────────────

class _PopupChiTietNgay extends StatefulWidget {
  final String ngay;
  final int? khuVucId;
  final BaoCaoRepository repo;

  const _PopupChiTietNgay({
    required this.ngay,
    this.khuVucId,
    required this.repo,
  });

  @override
  State<_PopupChiTietNgay> createState() => _PopupChiTietNgayState();
}

class _PopupChiTietNgayState extends State<_PopupChiTietNgay> {
  late Future<DonHangNgay> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repo.layDonHangNgay(widget.ngay, khuVucId: widget.khuVucId);
  }

  @override
  Widget build(BuildContext context) {
    final tieuDe = 'Hóa Đơn Ngày ${_fmtNgayDay(widget.ngay)}';

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Text(tieuDe,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<DonHangNgay>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(
                        child: Text('Lỗi: ${snap.error}',
                            style: const TextStyle(color: Colors.red)));
                  }
                  final data = snap.data!;
                  if (data.donHangs.isEmpty) {
                    return const Center(
                      child: Text('Không có hóa đơn trong ngày này',
                          style: TextStyle(color: AppColors.textSecondary)),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                    itemCount: data.donHangs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (_, i) => _TheHoaDon(hd: data.donHangs[i]),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Đóng'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TheHoaDon extends StatelessWidget {
  final HoaDonNgay hd;

  const _TheHoaDon({required this.hd});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header order
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(hd.maHoaDon,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                      Text(hd.tenKhachHang,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(hd.thoiGian,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                    Text(dinhDangTien(hd.tongTien),
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.activeGreen)),
                  ],
                ),
              ],
            ),
          ),
          // Table header
          Container(
            color: AppColors.navUnselected,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: const Row(
              children: [
                Expanded(flex: 4, child: Text('Sản Phẩm', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                Expanded(flex: 1, child: Text('SL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('Đơn Giá', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.end)),
                Expanded(flex: 2, child: Text('Thành Tiền', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.end)),
              ],
            ),
          ),
          // Table rows
          ...hd.sanPham.map((sp) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                        flex: 4,
                        child: Text(sp.ten,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis)),
                    Expanded(
                        flex: 1,
                        child: Text('${sp.soLuong}',
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.center)),
                    Expanded(
                        flex: 2,
                        child: Text(dinhDangTien(sp.donGia),
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.end)),
                    Expanded(
                        flex: 2,
                        child: Text(dinhDangTien(sp.thanhTien),
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.end)),
                  ],
                ),
              )),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ── Two Bottom Tables ─────────────────────────────────────────────────────────

class _HaiBang extends StatelessWidget {
  final BaoCao baoCao;

  const _HaiBang({required this.baoCao});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _BangSanPham(ds: baoCao.sanPhamBanChay)),
        const SizedBox(width: 16),
        Expanded(child: _BangKhachHang(ds: baoCao.khachMuaNhieu)),
      ],
    );
  }
}

class _BangSanPham extends StatelessWidget {
  final List<SanPhamBanChay> ds;

  const _BangSanPham({required this.ds});

  @override
  Widget build(BuildContext context) {
    return _KhungBang(
      tieuDe: 'Sản Phẩm Bán Chạy',
      hauTo: Row(
        children: [
          _OTieuDeBang(text: 'Sản Phẩm', flex: 5),
          _OTieuDeBang(text: 'SL', flex: 2, align: TextAlign.center),
          _OTieuDeBang(text: 'Doanh Thu', flex: 3, align: TextAlign.end),
        ],
      ),
      body: ds.isEmpty
          ? const _HangTrong()
          : Column(
              children: ds.asMap().entries.map((e) {
                final sp = e.value;
                return _HangBang(
                  chiSo: e.key,
                  cells: Row(
                    children: [
                      Expanded(
                          flex: 5,
                          child: Text(sp.ten,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis)),
                      Expanded(
                          flex: 2,
                          child: Text('${sp.soLuong}',
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.center)),
                      Expanded(
                          flex: 3,
                          child: Text(dinhDangTien(sp.doanhThu),
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.activeGreen),
                              textAlign: TextAlign.end)),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _BangKhachHang extends StatelessWidget {
  final List<KhachMuaNhieu> ds;

  const _BangKhachHang({required this.ds});

  @override
  Widget build(BuildContext context) {
    return _KhungBang(
      tieuDe: 'Khách Mua Nhiều Nhất',
      hauTo: Row(
        children: [
          _OTieuDeBang(text: 'Khách Hàng', flex: 5),
          _OTieuDeBang(text: 'Đơn', flex: 2, align: TextAlign.center),
          _OTieuDeBang(text: 'Tổng Chi', flex: 3, align: TextAlign.end),
        ],
      ),
      body: ds.isEmpty
          ? const _HangTrong()
          : Column(
              children: ds.asMap().entries.map((e) {
                final kh = e.value;
                return _HangBang(
                  chiSo: e.key,
                  cells: Row(
                    children: [
                      Expanded(
                          flex: 5,
                          child: Text(kh.ten,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis)),
                      Expanded(
                          flex: 2,
                          child: Text('${kh.soDon}',
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.center)),
                      Expanded(
                          flex: 3,
                          child: Text(dinhDangTien(kh.tongChi),
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.activeGreen),
                              textAlign: TextAlign.end)),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

// ── Table helpers ─────────────────────────────────────────────────────────────

class _KhungBang extends StatelessWidget {
  final String tieuDe;
  final Widget hauTo;
  final Widget body;

  const _KhungBang({required this.tieuDe, required this.hauTo, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(tieuDe,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          Container(
            color: const Color(0xFFF5F5F5),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            child: hauTo,
          ),
          body,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _OTieuDeBang extends StatelessWidget {
  final String text;
  final int flex;
  final TextAlign align;

  const _OTieuDeBang({required this.text, required this.flex, this.align = TextAlign.start});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(text,
          style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          textAlign: align),
    );
  }
}

class _HangBang extends StatelessWidget {
  final int chiSo;
  final Widget cells;

  const _HangBang({required this.chiSo, required this.cells});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: chiSo.isOdd ? const Color(0xFFF9F9F9) : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: cells,
    );
  }
}

class _HangTrong extends StatelessWidget {
  const _HangTrong();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text('Không có dữ liệu',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fisd_shared/models/bao_cao.dart';
import 'bao_cao_repository.dart';

enum KhoangThoiGian { tuanNay, thangNay, quyNay, namNay, tuyChinh }

enum MetricBieuDo { doanhThu, soDon, sanPhamDaBan, soKhachHang }

class TrangLocBaoCao {
  final KhoangThoiGian khoang;
  final DateTime tuNgay;
  final DateTime denNgay;
  final int? khuVucId;

  const TrangLocBaoCao({
    required this.khoang,
    required this.tuNgay,
    required this.denNgay,
    this.khuVucId,
  });
}

DateTime _dauThangNay() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
}

class LocBaoCaoNotifier extends StateNotifier<TrangLocBaoCao> {
  LocBaoCaoNotifier()
      : super(TrangLocBaoCao(
          khoang: KhoangThoiGian.thangNay,
          tuNgay: _dauThangNay(),
          denNgay: DateTime.now(),
        ));

  void chonKhoang(KhoangThoiGian khoang) {
    final now = DateTime.now();
    DateTime tu;

    switch (khoang) {
      case KhoangThoiGian.tuanNay:
        tu = now.subtract(Duration(days: now.weekday - 1));
        tu = DateTime(tu.year, tu.month, tu.day);
      case KhoangThoiGian.thangNay:
        tu = DateTime(now.year, now.month, 1);
      case KhoangThoiGian.quyNay:
        final quyDau = ((now.month - 1) ~/ 3) * 3 + 1;
        tu = DateTime(now.year, quyDau, 1);
      case KhoangThoiGian.namNay:
        tu = DateTime(now.year, 1, 1);
      case KhoangThoiGian.tuyChinh:
        state = TrangLocBaoCao(
          khoang: KhoangThoiGian.tuyChinh,
          tuNgay: state.tuNgay,
          denNgay: state.denNgay,
          khuVucId: state.khuVucId,
        );
        return;
    }

    state = TrangLocBaoCao(
      khoang: khoang,
      tuNgay: tu,
      denNgay: now,
      khuVucId: state.khuVucId,
    );
  }

  void chonNgay(DateTime tu, DateTime den) {
    state = TrangLocBaoCao(
      khoang: KhoangThoiGian.tuyChinh,
      tuNgay: tu,
      denNgay: den,
      khuVucId: state.khuVucId,
    );
  }

  void chonKhuVuc(int? khuVucId) {
    state = TrangLocBaoCao(
      khoang: state.khoang,
      tuNgay: state.tuNgay,
      denNgay: state.denNgay,
      khuVucId: khuVucId,
    );
  }
}

final locBaoCaoProvider =
    StateNotifierProvider<LocBaoCaoNotifier, TrangLocBaoCao>((ref) => LocBaoCaoNotifier());

final metricBieuDoProvider = StateProvider<MetricBieuDo>((ref) => MetricBieuDo.doanhThu);

String _fmtNgayApi(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

final baoCaoProvider = FutureProvider.autoDispose<BaoCao>((ref) async {
  final loc = ref.watch(locBaoCaoProvider);
  final repo = ref.read(baoCaoRepositoryProvider);
  return repo.layBaoCao(
    tuNgay: _fmtNgayApi(loc.tuNgay),
    denNgay: _fmtNgayApi(loc.denNgay),
    khuVucId: loc.khuVucId,
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'lich_su_repository.dart';

final lichSuRepoProvider = Provider((_) => LichSuRepository());

class LichSuFilter {
  final int pickerId;
  final int days;
  const LichSuFilter({required this.pickerId, required this.days});

  @override
  bool operator ==(Object other) => other is LichSuFilter && other.pickerId == pickerId && other.days == days;

  @override
  int get hashCode => Object.hash(pickerId, days);
}

final lichSuProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, LichSuFilter>((ref, filter) async {
  return ref.read(lichSuRepoProvider).layLichSuGiao(filter.pickerId, days: filter.days);
});

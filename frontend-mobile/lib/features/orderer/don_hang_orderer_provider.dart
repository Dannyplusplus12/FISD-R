import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'don_hang_orderer_repository.dart';

// 0=Hôm nay, 1=Tuần, 2=Tháng, 3=Tất cả
final donHangFilterProvider = StateProvider<int>((_) => 3);

final donHangOrdererRepoProvider = Provider((_) => DonHangOrdererRepository());

final donHangOrdererProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, int>((ref, ordererId) async {
  return ref.read(donHangOrdererRepoProvider).layDonCuaOrderer(ordererId);
});

class TaoDonNotifier extends StateNotifier<AsyncValue<void>> {
  TaoDonNotifier(this._repo) : super(const AsyncData(null));
  final DonHangOrdererRepository _repo;

  Future<int?> taoDon({
    required int employeeId,
    required String customerName,
    required String customerPhone,
    required List<Map<String, dynamic>> cart,
  }) async {
    state = const AsyncLoading();
    try {
      final id = await _repo.taoDon(
        employeeId: employeeId,
        customerName: customerName,
        customerPhone: customerPhone,
        cart: cart,
      );
      state = const AsyncData(null);
      return id;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return null;
    }
  }
}

final taoDonProvider = StateNotifierProvider<TaoDonNotifier, AsyncValue<void>>(
  (ref) => TaoDonNotifier(ref.read(donHangOrdererRepoProvider)),
);

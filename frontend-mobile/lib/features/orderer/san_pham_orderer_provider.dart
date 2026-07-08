import 'package:fisd_shared/fisd_shared.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'san_pham_orderer_repository.dart';

final sanPhamOrdererRepoProvider = Provider((_) => SanPhamOrdererRepository());

final sanPhamOrdererProvider = FutureProvider.autoDispose<List<SanPham>>((ref) async {
  return ref.read(sanPhamOrdererRepoProvider).laySanPhams();
});

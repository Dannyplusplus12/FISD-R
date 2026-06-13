import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/product.dart';
import 'product_repository.dart';

// ── Products Provider ─────────────────────────────────────────────────────────
//
// Holds the list of products and handles loading / error states.
//
// HOW RIVERPOD AsyncNotifier WORKS:
//
//   build()    — runs once when first watched; returns the initial data
//   refresh()  — clears data, fetches again from the server
//
// In the UI page you do:
//   final productsAsync = ref.watch(productsProvider);
//   productsAsync.when(
//     loading: () => CircularProgressIndicator(),
//     error:   (e, _) => Text('Lỗi: $e'),
//     data:    (products) => ListView(...),
//   )
//
// The `when()` call handles all three states automatically — no if/else needed.

class ProductsNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() {
    // This is called automatically the first time a widget watches the provider.
    return ref.read(productRepositoryProvider).getAll();
  }

  // Refetch the list (e.g. after creating/editing/deleting a product).
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(productRepositoryProvider).getAll(),
    );
  }

  Future<void> search(String query) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(productRepositoryProvider).getAll(search: query),
    );
  }
}

final productsProvider =
    AsyncNotifierProvider<ProductsNotifier, List<Product>>(ProductsNotifier.new);

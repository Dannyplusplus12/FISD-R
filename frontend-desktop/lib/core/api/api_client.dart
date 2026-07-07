import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Backend URL ───────────────────────────────────────────────────────────────
// Change this one constant to point the whole app at a different server.
const String kBackendUrl = 'https://backend-production-0935.up.railway.app';

// ── Dio instance provider ─────────────────────────────────────────────────────
//
// All repositories (product_repository, order_repository, …) receive this
// Dio instance via `ref.watch(apiClientProvider)`.
//
// HOW IT WORKS
// ─────────────
// Dio is like a smarter version of the http package.
// You give it a base URL once here, then every request just says:
//   dio.get('/products')          → calls kBackendUrl/products
//   dio.post('/checkout', …)      → calls kBackendUrl/checkout
//
// Timeouts: if the server doesn't respond in 15s, Dio throws DioException
// which our providers catch and turn into a friendly error message.
final apiClientProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: kBackendUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: const {'Content-Type': 'application/json'},
    ),
  );
});

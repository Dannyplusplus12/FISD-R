import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/order.dart';
import 'order_repository.dart';

// ── Orders Provider ───────────────────────────────────────────────────────────
//
// Multiple providers for different order lists (history, pending, etc.).
// Each screen watches the one it needs.

// Full order history (management view, latest 200 orders)
class ManagementOrdersNotifier extends AsyncNotifier<List<Order>> {
  @override
  Future<List<Order>> build() {
    return ref.read(orderRepositoryProvider).getManagement();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(orderRepositoryProvider).getManagement(),
    );
  }

  // Approve a pending order and remove it from the list.
  Future<void> approve(int orderId) async {
    await ref.read(orderRepositoryProvider).approve(orderId);
    await refresh();
  }

  Future<void> reject(int orderId) async {
    await ref.read(orderRepositoryProvider).reject(orderId);
    await refresh();
  }

  Future<void> cancel(int orderId) async {
    await ref.read(orderRepositoryProvider).cancel(orderId);
    await refresh();
  }
}

final managementOrdersProvider =
    AsyncNotifierProvider<ManagementOrdersNotifier, List<Order>>(
  ManagementOrdersNotifier.new,
);

// Pending orders only (for the manager approval screen)
class PendingOrdersNotifier extends AsyncNotifier<List<Order>> {
  @override
  Future<List<Order>> build() {
    return ref.read(orderRepositoryProvider).getPending();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(orderRepositoryProvider).getPending(),
    );
  }

  Future<void> approve(int orderId) async {
    await ref.read(orderRepositoryProvider).approve(orderId);
    await refresh();
  }

  Future<void> reject(int orderId) async {
    await ref.read(orderRepositoryProvider).reject(orderId);
    await refresh();
  }
}

final pendingOrdersProvider =
    AsyncNotifierProvider<PendingOrdersNotifier, List<Order>>(
  PendingOrdersNotifier.new,
);

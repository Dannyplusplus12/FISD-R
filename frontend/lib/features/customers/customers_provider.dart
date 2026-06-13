import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/customer.dart';
import 'customer_repository.dart';

// Customers list
class CustomersNotifier extends AsyncNotifier<List<Customer>> {
  @override
  Future<List<Customer>> build() {
    return ref.read(customerRepositoryProvider).getAll();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(customerRepositoryProvider).getAll(),
    );
  }

  Future<void> create({
    required String name,
    String phone = '',
    int debt = 0,
    required int areaId,
  }) async {
    await ref.read(customerRepositoryProvider).create(
          name: name,
          phone: phone,
          debt: debt,
          areaId: areaId,
        );
    await refresh();
  }

  Future<void> delete(int id) async {
    await ref.read(customerRepositoryProvider).delete(id);
    await refresh();
  }
}

final customersProvider =
    AsyncNotifierProvider<CustomersNotifier, List<Customer>>(CustomersNotifier.new);

// Areas list
class AreasNotifier extends AsyncNotifier<List<AreaSummary>> {
  @override
  Future<List<AreaSummary>> build() {
    return ref.read(customerRepositoryProvider).getAreas();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(customerRepositoryProvider).getAreas(),
    );
  }

  Future<void> create(String name) async {
    await ref.read(customerRepositoryProvider).createArea(name);
    await refresh();
  }

  Future<void> update(int id, String name) async {
    await ref.read(customerRepositoryProvider).updateArea(id, name);
    await refresh();
  }

  Future<void> delete(int id) async {
    await ref.read(customerRepositoryProvider).deleteArea(id);
    await refresh();
  }
}

final areasProvider =
    AsyncNotifierProvider<AreasNotifier, List<AreaSummary>>(AreasNotifier.new);

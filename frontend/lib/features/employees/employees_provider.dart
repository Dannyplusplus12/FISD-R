import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/employee.dart';
import 'employee_repository.dart';

class EmployeesNotifier extends AsyncNotifier<List<Employee>> {
  @override
  Future<List<Employee>> build() {
    return ref.read(employeeRepositoryProvider).getAll();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(employeeRepositoryProvider).getAll(),
    );
  }

  Future<void> delete(int id) async {
    await ref.read(employeeRepositoryProvider).delete(id);
    await refresh();
  }
}

final employeesProvider =
    AsyncNotifierProvider<EmployeesNotifier, List<Employee>>(EmployeesNotifier.new);

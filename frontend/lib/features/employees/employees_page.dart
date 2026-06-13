import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/employee.dart';
import 'employees_provider.dart';

// ── Employees Page ────────────────────────────────────────────────────────────

class EmployeesPage extends ConsumerWidget {
  const EmployeesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeesProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Nhân Viên',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
                  onPressed: () => ref.read(employeesProvider.notifier).refresh(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: employeesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(e.toString(), style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => ref.read(employeesProvider.notifier).refresh(),
                      child: const Text('Thử lại'),
                    ),
                  ]),
                ),
                data: (employees) => employees.isEmpty
                    ? const Center(
                        child: Text('Chưa có nhân viên',
                            style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.separated(
                        itemCount: employees.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _EmployeeCard(employee: employees[i]),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final Employee employee;

  const _EmployeeCard({required this.employee});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          // Avatar circle with first letter of name
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: employee.isActive ? AppColors.navSelected : AppColors.navUnselected,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: Text(
                employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: employee.isActive ? Colors.white : AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(employee.name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  if (!employee.isActive) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Nghỉ',
                          style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ),
                  ],
                ]),
                Text(employee.phone,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _roleColor(employee.role).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                employee.roleLabel,
                style: TextStyle(
                    fontSize: 11,
                    color: _roleColor(employee.role),
                    fontWeight: FontWeight.w600),
              ),
            ),
            if (employee.deliveredCount > 0) ...[
              const SizedBox(height: 4),
              Text('${employee.deliveredCount} đơn',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ]),
        ],
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'manager': return Colors.purple;
      case 'picker': return Colors.blue;
      default: return Colors.orange;
    }
  }
}

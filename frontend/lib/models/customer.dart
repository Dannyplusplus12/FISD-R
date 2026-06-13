// ── Customer Models ───────────────────────────────────────────────────────────

class AreaSummary {
  final int id;
  final String name;
  final int customerCount;
  final int totalDebt;

  const AreaSummary({
    required this.id,
    required this.name,
    this.customerCount = 0,
    this.totalDebt = 0,
  });

  factory AreaSummary.fromJson(Map<String, dynamic> j) => AreaSummary(
        id: j['id'] as int,
        name: (j['name'] ?? '').toString(),
        customerCount: (j['customer_count'] ?? 0) as int,
        totalDebt: (j['total_debt'] ?? 0) as int,
      );
}

class Customer {
  final int id;
  final String name;
  final String phone;
  final int debt;    // VND owed by this customer; negative = customer overpaid
  final int? areaId;
  final String areaName;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.debt,
    this.areaId,
    this.areaName = '',
  });

  factory Customer.fromJson(Map<String, dynamic> j) => Customer(
        id: j['id'] as int,
        name: (j['name'] ?? '').toString(),
        phone: (j['phone'] ?? '').toString(),
        debt: ((j['debt'] ?? 0) as num).toInt(),
        areaId: j['area_id'] as int?,
        areaName: (j['area_name'] ?? '').toString(),
      );
}

// One entry in a customer's debt history log.
class HistoryItem {
  final int id;
  final int changeAmount;   // positive = customer owes more, negative = paid back
  final int newBalance;
  final String note;
  final String createdAt;
  final int? actorEmployeeId;
  final String actorEmployeeName;

  const HistoryItem({
    required this.id,
    required this.changeAmount,
    required this.newBalance,
    required this.note,
    required this.createdAt,
    this.actorEmployeeId,
    this.actorEmployeeName = '',
  });

  factory HistoryItem.fromJson(Map<String, dynamic> j) => HistoryItem(
        id: j['id'] as int,
        changeAmount: ((j['change_amount'] ?? 0) as num).toInt(),
        newBalance: ((j['new_balance'] ?? 0) as num).toInt(),
        note: (j['note'] ?? '').toString(),
        createdAt: (j['created_at'] ?? '').toString(),
        actorEmployeeId: j['actor_employee_id'] as int?,
        actorEmployeeName: (j['actor_employee_name'] ?? '').toString(),
      );
}

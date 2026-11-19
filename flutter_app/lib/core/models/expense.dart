import 'package:cloud_firestore/cloud_firestore.dart';

enum ExpenseCategory {
  fuel('Fuel'),
  maintenance('Maintenance/Repairs'),
  tyres('Tyres'),
  driverWages('Driver Wages'),
  insurance('Insurance'),
  licences('Licences/Permits'),
  tolls('Tolls/Border Fees'),
  office('Office/Admin'),
  other('Other');

  final String label;
  const ExpenseCategory(this.label);

  static ExpenseCategory fromString(String? value) {
    return ExpenseCategory.values.firstWhere(
      (c) => c.label == value || c.name == value,
      orElse: () => ExpenseCategory.other,
    );
  }
}

class Expense {
  final String id;
  final String companyId;
  final ExpenseCategory category;
  final double amount;
  final DateTime date;
  final String description;
  final String? truckId;
  final String? receiptUrl;
  final DateTime createdAt;

  const Expense({
    required this.id,
    required this.companyId,
    required this.category,
    required this.amount,
    required this.date,
    required this.description,
    this.truckId,
    this.receiptUrl,
    required this.createdAt,
  });

  factory Expense.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Expense(
      id: doc.id,
      companyId: data['companyId'] as String? ?? '',
      category: ExpenseCategory.fromString(data['category'] as String?),
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: data['description'] as String? ?? '',
      truckId: data['truckId'] as String?,
      receiptUrl: data['receiptUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'category': category.label,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'description': description,
      'truckId': truckId,
      'receiptUrl': receiptUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentStatus {
  unpaid('Unpaid'),
  partiallyPaid('Partially Paid'),
  paid('Paid');

  final String label;
  const PaymentStatus(this.label);

  static PaymentStatus fromString(String? value) {
    return PaymentStatus.values.firstWhere(
      (s) => s.label == value || s.name == value,
      orElse: () => PaymentStatus.unpaid,
    );
  }
}

class Invoice {
  final String id;
  final String companyId;
  final String orderId;
  final String customerId; // Supports Phase 2 customer rules
  final String invoiceNumber;
  final DateTime issueDate;
  final DateTime dueDate;
  final double totalAmount;
  final double amountPaid;
  final PaymentStatus paymentStatus;
  final String? paymentMethod;
  final DateTime? paidAt;
  final String? pdfUrl;
  final DateTime createdAt;

  const Invoice({
    required this.id,
    required this.companyId,
    required this.orderId,
    required this.customerId,
    required this.invoiceNumber,
    required this.issueDate,
    required this.dueDate,
    required this.totalAmount,
    this.amountPaid = 0,
    this.paymentStatus = PaymentStatus.unpaid,
    this.paymentMethod,
    this.paidAt,
    this.pdfUrl,
    required this.createdAt,
  });

  double get balanceDue => (totalAmount - amountPaid).clamp(0, totalAmount);

  bool get isOverdue =>
      paymentStatus != PaymentStatus.paid && dueDate.isBefore(DateTime.now());

  factory Invoice.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Invoice(
      id: doc.id,
      companyId: data['companyId'] as String? ?? '',
      orderId: data['orderId'] as String? ?? '',
      customerId: data['customerId'] as String? ?? '',
      invoiceNumber: data['invoiceNumber'] as String? ?? '',
      issueDate:
          (data['issueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 14)),
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0,
      amountPaid: (data['amountPaid'] as num?)?.toDouble() ?? 0,
      paymentStatus: PaymentStatus.fromString(data['paymentStatus'] as String?),
      paymentMethod: data['paymentMethod'] as String?,
      paidAt: (data['paidAt'] as Timestamp?)?.toDate(),
      pdfUrl: data['pdfUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'orderId': orderId,
      'customerId': customerId,
      'invoiceNumber': invoiceNumber,
      'issueDate': Timestamp.fromDate(issueDate),
      'dueDate': Timestamp.fromDate(dueDate),
      'totalAmount': totalAmount,
      'amountPaid': amountPaid,
      'paymentStatus': paymentStatus.label,
      'paymentMethod': paymentMethod,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'pdfUrl': pdfUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Invoice copyWith({
    double? amountPaid,
    PaymentStatus? paymentStatus,
    String? paymentMethod,
    DateTime? paidAt,
    String? pdfUrl,
  }) {
    return Invoice(
      id: id,
      companyId: companyId,
      orderId: orderId,
      customerId: customerId,
      invoiceNumber: invoiceNumber,
      issueDate: issueDate,
      dueDate: dueDate,
      totalAmount: totalAmount,
      amountPaid: amountPaid ?? this.amountPaid,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidAt: paidAt ?? this.paidAt,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      createdAt: createdAt,
    );
  }
}

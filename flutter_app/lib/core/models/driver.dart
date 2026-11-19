import 'package:cloud_firestore/cloud_firestore.dart';

class Driver {
  final String id;
  final String companyId;
  final String name;
  final String phone;
  final String licenceNumber;
  final DateTime licenceExpiry;
  final String? assignedTruckId;
  final DateTime createdAt;

  const Driver({
    required this.id,
    required this.companyId,
    required this.name,
    required this.phone,
    required this.licenceNumber,
    required this.licenceExpiry,
    this.assignedTruckId,
    required this.createdAt,
  });

  bool get isLicenceExpiringSoon =>
      licenceExpiry.difference(DateTime.now()).inDays <= 30;

  bool get isLicenceExpired => licenceExpiry.isBefore(DateTime.now());

  factory Driver.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Driver(
      id: doc.id,
      companyId: data['companyId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      licenceNumber: data['licenceNumber'] as String? ?? '',
      licenceExpiry:
          (data['licenceExpiry'] as Timestamp?)?.toDate() ?? DateTime.now(),
      assignedTruckId: data['assignedTruckId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'name': name,
      'phone': phone,
      'licenceNumber': licenceNumber,
      'licenceExpiry': Timestamp.fromDate(licenceExpiry),
      'assignedTruckId': assignedDriverId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Driver copyWith({
    String? name,
    String? phone,
    String? licenceNumber,
    DateTime? licenceExpiry,
    String? assignedTruckId,
  }) {
    return Driver(
      id: id,
      companyId: companyId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      licenceNumber: licenceNumber ?? this.licenceNumber,
      licenceExpiry: licenceExpiry ?? this.licenceExpiry,
      assignedTruckId: assignedTruckId ?? this.assignedTruckId,
      createdAt: createdAt,
    );
  }
}

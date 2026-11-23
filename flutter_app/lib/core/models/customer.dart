import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String id;
  final String companyId;
  final String name;
  final String business;
  final String phone;
  final String email;
  final String address;
  final String? uid; // Phase 2: optional Firebase Auth uid for portal login
  final DateTime createdAt;

  const Customer({
    required this.id,
    required this.companyId,
    required this.name,
    required this.business,
    required this.phone,
    required this.email,
    required this.address,
    this.uid,
    required this.createdAt,
  });

  String get displayName =>
      business.trim().isNotEmpty ? '$business ($name)' : name;

  factory Customer.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Customer(
      id: doc.id,
      companyId: data['companyId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      business: data['business'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      email: data['email'] as String? ?? '',
      address: data['address'] as String? ?? '',
      uid: data['uid'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'name': name,
      'business': business,
      'phone': phone,
      'email': email,
      'address': address,
      if (uid != null) 'uid': uid,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Customer copyWith({
    String? name,
    String? business,
    String? phone,
    String? email,
    String? address,
    String? uid,
  }) {
    return Customer(
      id: id,
      companyId: companyId,
      name: name ?? this.name,
      business: business ?? this.business,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      uid: uid ?? this.uid,
      createdAt: createdAt,
    );
  }
}

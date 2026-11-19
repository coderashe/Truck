import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  owner('owner', 'Owner / Manager'),
  staff('staff', 'Staff'),
  customer('customer', 'Customer');

  final String value;
  final String label;
  const UserRole(this.value, this.label);

  static UserRole fromString(String? value) {
    return UserRole.values.firstWhere(
      (r) => r.value == value,
      orElse: () => UserRole.owner,
    );
  }
}

class AppUser {
  final String uid;
  final String companyId;
  final String name;
  final String email;
  final UserRole role;
  final String? customerId; // Phase 2: links customer auth account to /customers/{id}
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.companyId,
    required this.name,
    required this.email,
    required this.role,
    this.customerId,
    required this.createdAt,
  });

  bool get isOwner => role == UserRole.owner;
  bool get isStaff => role == UserRole.staff;
  bool get isCustomer => role == UserRole.customer;

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      companyId: data['companyId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: UserRole.fromString(data['role'] as String?),
      customerId: data['customerId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'name': name,
      'email': email,
      'role': role.value,
      if (customerId != null) 'customerId': customerId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AppUser copyWith({
    String? companyId,
    String? name,
    String? email,
    UserRole? role,
    String? customerId,
  }) {
    return AppUser(
      uid: uid,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      customerId: customerId ?? this.customerId,
      createdAt: createdAt,
    );
  }
}

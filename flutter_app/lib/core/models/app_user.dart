import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  owner('owner', 'Owner'),
  manager('manager', 'Manager'),
  accountant('accountant', 'Accountant'),
  driver('driver', 'Driver');

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
  final String phone;
  final UserRole role;
  final String? driverId; // set when role == driver
  final String? customerId;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.companyId,
    required this.name,
    required this.email,
    this.phone = '',
    required this.role,
    this.driverId,
    this.customerId,
    required this.createdAt,
  });

  bool get isOwner => role == UserRole.owner;
  bool get isManager => role == UserRole.manager;
  bool get isAccountant => role == UserRole.accountant;
  bool get isDriver => role == UserRole.driver;
  bool get canEditData => role == UserRole.owner || role == UserRole.manager;
  bool get canViewFinancials => role != UserRole.driver;
  bool get canManageTeam => role == UserRole.owner;
  bool get canAccessSettings => role == UserRole.owner;

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      companyId: data['companyId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      role: UserRole.fromString(data['role'] as String?),
      driverId: data['driverId'] as String?,
      customerId: data['customerId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.value,
      if (driverId != null) 'driverId': driverId,
      if (customerId != null) 'customerId': customerId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AppUser copyWith({
    String? companyId,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? driverId,
    String? customerId,
  }) {
    return AppUser(
      uid: uid,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      driverId: driverId ?? this.driverId,
      customerId: customerId ?? this.customerId,
      createdAt: createdAt,
    );
  }
}

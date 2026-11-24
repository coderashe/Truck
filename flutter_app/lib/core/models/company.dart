import 'package:cloud_firestore/cloud_firestore.dart';

class TeamMember {
  final String uid;
  final String name;
  final String email;
  final String role;
  final DateTime joinedAt;

  const TeamMember({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.joinedAt,
  });

  factory TeamMember.fromMap(Map<String, dynamic> data) {
    return TeamMember(
      uid: data['uid'] as String? ?? '',
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? 'manager',
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'role': role,
        'joinedAt': Timestamp.fromDate(joinedAt),
      };
}

class Company {
  final String id;
  final String name;
  final String? logoUrl;
  final String address;
  final String phone;
  final String email;
  final String taxNumber;
  final String bankDetails;
  final String currency;
  final double defaultRatePerKm;
  final bool defaultRoundTrip;
  final String invoiceFooter;
  final int invoiceAccentHex;
  final int invoiceCounter;
  final String ownerId;
  final bool setupCompleted;
  final Map<String, String> joinCodes;
  final List<TeamMember> members;
  final DateTime createdAt;

  const Company({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.address,
    required this.phone,
    required this.email,
    required this.taxNumber,
    required this.bankDetails,
    this.currency = 'USD',
    this.defaultRatePerKm = 1.75,
    this.defaultRoundTrip = true,
    this.invoiceFooter =
        'Thank you for your business. Payment is due within 14 days.',
    this.invoiceAccentHex = 0xFF0F172A,
    this.invoiceCounter = 0,
    required this.ownerId,
    this.setupCompleted = false,
    this.joinCodes = const {},
    this.members = const [],
    required this.createdAt,
  });

  factory Company.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawCodes = data['joinCodes'] as Map<String, dynamic>? ?? {};
    final rawMembers = data['members'] as List<dynamic>? ?? [];
    return Company(
      id: doc.id,
      name: data['name'] as String? ?? 'My Trucking Company',
      logoUrl: data['logoUrl'] as String?,
      address: data['address'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      email: data['email'] as String? ?? '',
      taxNumber: data['taxNumber'] as String? ?? '',
      bankDetails: data['bankDetails'] as String? ?? '',
      currency: data['currency'] as String? ?? 'USD',
      defaultRatePerKm:
          (data['defaultRatePerKm'] as num?)?.toDouble() ?? 1.75,
      defaultRoundTrip: data['defaultRoundTrip'] as bool? ?? true,
      invoiceFooter: data['invoiceFooter'] as String? ??
          'Thank you for your business. Payment is due within 14 days.',
      invoiceAccentHex:
          (data['invoiceAccentHex'] as num?)?.toInt() ?? 0xFF0F172A,
      invoiceCounter: (data['invoiceCounter'] as num?)?.toInt() ?? 0,
      ownerId: data['ownerId'] as String? ?? '',
      setupCompleted: data['setupCompleted'] as bool? ?? false,
      joinCodes: rawCodes.map((k, v) => MapEntry(k, v as String)),
      members: rawMembers
          .map((e) => TeamMember.fromMap(e as Map<String, dynamic>))
          .toList(),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'logoUrl': logoUrl,
      'address': address,
      'phone': phone,
      'email': email,
      'taxNumber': taxNumber,
      'bankDetails': bankDetails,
      'currency': currency,
      'defaultRatePerKm': defaultRatePerKm,
      'defaultRoundTrip': defaultRoundTrip,
      'invoiceFooter': invoiceFooter,
      'invoiceAccentHex': invoiceAccentHex,
      'invoiceCounter': invoiceCounter,
      'ownerId': ownerId,
      'setupCompleted': setupCompleted,
      'joinCodes': joinCodes,
      'members': members.map((m) => m.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Company copyWith({
    String? name,
    String? logoUrl,
    String? address,
    String? phone,
    String? email,
    String? taxNumber,
    String? bankDetails,
    String? currency,
    double? defaultRatePerKm,
    bool? defaultRoundTrip,
    String? invoiceFooter,
    int? invoiceAccentHex,
    int? invoiceCounter,
    bool? setupCompleted,
    Map<String, String>? joinCodes,
    List<TeamMember>? members,
  }) {
    return Company(
      id: id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      taxNumber: taxNumber ?? this.taxNumber,
      bankDetails: bankDetails ?? this.bankDetails,
      currency: currency ?? this.currency,
      defaultRatePerKm: defaultRatePerKm ?? this.defaultRatePerKm,
      defaultRoundTrip: defaultRoundTrip ?? this.defaultRoundTrip,
      invoiceFooter: invoiceFooter ?? this.invoiceFooter,
      invoiceAccentHex: invoiceAccentHex ?? this.invoiceAccentHex,
      invoiceCounter: invoiceCounter ?? this.invoiceCounter,
      ownerId: ownerId,
      setupCompleted: setupCompleted ?? this.setupCompleted,
      joinCodes: joinCodes ?? this.joinCodes,
      members: members ?? this.members,
      createdAt: createdAt,
    );
  }
}

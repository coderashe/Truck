import 'package:cloud_firestore/cloud_firestore.dart';

enum TruckStatus {
  active('Active'),
  maintenance('In Maintenance'),
  inactive('Inactive');

  final String label;
  const TruckStatus(this.label);

  static TruckStatus fromString(String? value) {
    return TruckStatus.values.firstWhere(
      (s) => s.label == value || s.name == value,
      orElse: () => TruckStatus.active,
    );
  }
}

class Truck {
  final String id;
  final String companyId;
  final String regNumber;
  final String makeModel;
  final double capacityTonnes;
  final String fuelType;
  final TruckStatus status;
  final String? photoUrl;
  final String? assignedDriverId;
  final DateTime createdAt;

  const Truck({
    required this.id,
    required this.companyId,
    required this.regNumber,
    required this.makeModel,
    required this.capacityTonnes,
    required this.fuelType,
    this.status = TruckStatus.active,
    this.photoUrl,
    this.assignedDriverId,
    required this.createdAt,
  });

  factory Truck.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Truck(
      id: doc.id,
      companyId: data['companyId'] as String? ?? '',
      regNumber: data['regNumber'] as String? ?? '',
      makeModel: data['makeModel'] as String? ?? '',
      capacityTonnes: (data['capacityTonnes'] as num?)?.toDouble() ?? 30.0,
      fuelType: data['fuelType'] as String? ?? 'Diesel',
      status: TruckStatus.fromString(data['status'] as String?),
      photoUrl: data['photoUrl'] as String?,
      assignedDriverId: data['assignedDriverId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'regNumber': regNumber,
      'makeModel': makeModel,
      'capacityTonnes': capacityTonnes,
      'fuelType': fuelType,
      'status': status.label,
      'photoUrl': photoUrl,
      'assignedDriverId': assignedDriverId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Truck copyWith({
    String? regNumber,
    String? makeModel,
    double? capacityTonnes,
    String? fuelType,
    TruckStatus? status,
    String? photoUrl,
    String? assignedDriverId,
  }) {
    return Truck(
      id: id,
      companyId: companyId,
      regNumber: regNumber ?? this.regNumber,
      makeModel: makeModel ?? this.makeModel,
      capacityTonnes: capacityTonnes ?? this.capacityTonnes,
      fuelType: fuelType ?? this.fuelType,
      status: status ?? this.status,
      photoUrl: photoUrl ?? this.photoUrl,
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
      createdAt: createdAt,
    );
  }
}

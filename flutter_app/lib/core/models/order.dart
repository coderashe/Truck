import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderSource {
  whatsapp('WhatsApp'),
  call('Call'),
  email('Email'),
  inPerson('In-person'),
  portal('Customer Portal'); // Phase 2

  final String label;
  const OrderSource(this.label);

  static OrderSource fromString(String? value) {
    return OrderSource.values.firstWhere(
      (s) => s.label == value || s.name == value,
      orElse: () => OrderSource.whatsapp,
    );
  }
}

enum OrderStatus {
  requested('Requested'), // Phase 2 customer booking request
  pending('Pending'),
  confirmed('Confirmed'),
  inTransit('In Transit'),
  delivered('Delivered'),
  invoiced('Invoiced'),
  paid('Paid'),
  cancelled('Cancelled');

  final String label;
  const OrderStatus(this.label);

  static OrderStatus fromString(String? value) {
    return OrderStatus.values.firstWhere(
      (s) => s.label == value || s.name == value,
      orElse: () => OrderStatus.pending,
    );
  }
}

class GeoPointLocation {
  final String address;
  final double lat;
  final double lng;

  const GeoPointLocation({
    required this.address,
    required this.lat,
    required this.lng,
  });

  factory GeoPointLocation.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const GeoPointLocation(address: '', lat: 0, lng: 0);
    }
    return GeoPointLocation(
      address: map['address'] as String? ?? '',
      lat: (map['lat'] as num?)?.toDouble() ?? 0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'lat': lat,
      'lng': lng,
    };
  }
}

class HaulageOrder {
  final String id;
  final String companyId;
  final String customerId;
  final String customerName;
  final OrderSource source;
  final GeoPointLocation pickup;
  final GeoPointLocation dropoff;
  final String routeName;
  final double distanceKm;
  final bool roundTrip;
  final double chargeableKm;
  final double ratePerKm;
  final double extras;
  final double discount;
  final double totalAmount;
  final String truckId;
  final String driverId;
  final String cargoDescription;
  final double cargoWeight;
  final DateTime tripDate;
  final OrderStatus status;
  final String? invoiceId;
  final String createdBy;
  final DateTime createdAt;

  const HaulageOrder({
    required this.id,
    required this.companyId,
    required this.customerId,
    required this.customerName,
    required this.source,
    required this.pickup,
    required this.dropoff,
    required this.routeName,
    required this.distanceKm,
    required this.roundTrip,
    required this.chargeableKm,
    required this.ratePerKm,
    this.extras = 0,
    this.discount = 0,
    required this.totalAmount,
    required this.truckId,
    required this.driverId,
    required this.cargoDescription,
    required this.cargoWeight,
    required this.tripDate,
    this.status = OrderStatus.pending,
    this.invoiceId,
    required this.createdBy,
    required this.createdAt,
  });

  factory HaulageOrder.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return HaulageOrder(
      id: doc.id,
      companyId: data['companyId'] as String? ?? '',
      customerId: data['customerId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      source: OrderSource.fromString(data['source'] as String?),
      pickup: GeoPointLocation.fromMap(data['pickup'] as Map<String, dynamic>?),
      dropoff:
          GeoPointLocation.fromMap(data['dropoff'] as Map<String, dynamic>?),
      routeName: data['routeName'] as String? ?? '',
      distanceKm: (data['distanceKm'] as num?)?.toDouble() ?? 0,
      roundTrip: data['roundTrip'] as bool? ?? true,
      chargeableKm: (data['chargeableKm'] as num?)?.toDouble() ?? 0,
      ratePerKm: (data['ratePerKm'] as num?)?.toDouble() ?? 1.75,
      extras: (data['extras'] as num?)?.toDouble() ?? 0,
      discount: (data['discount'] as num?)?.toDouble() ?? 0,
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0,
      truckId: data['truckId'] as String? ?? '',
      driverId: data['driverId'] as String? ?? '',
      cargoDescription: data['cargoDescription'] as String? ?? '',
      cargoWeight: (data['cargoWeight'] as num?)?.toDouble() ?? 0,
      tripDate: (data['tripDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: OrderStatus.fromString(data['status'] as String?),
      invoiceId: data['invoiceId'] as String?,
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'customerId': customerId,
      'customerName': customerName,
      'source': source.label,
      'pickup': pickup.toMap(),
      'dropoff': dropoff.toMap(),
      'routeName': routeName,
      'distanceKm': distanceKm,
      'roundTrip': roundTrip,
      'chargeableKm': chargeableKm,
      'ratePerKm': ratePerKm,
      'extras': extras,
      'discount': discount,
      'totalAmount': totalAmount,
      'truckId': truckId,
      'driverId': driverId,
      'cargoDescription': cargoDescription,
      'cargoWeight': cargoWeight,
      'tripDate': Timestamp.fromDate(tripDate),
      'status': status.label,
      'invoiceId': invoiceId,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  HaulageOrder copyWith({
    String? customerId,
    String? customerName,
    OrderSource? source,
    GeoPointLocation? pickup,
    GeoPointLocation? dropoff,
    String? routeName,
    double? distanceKm,
    bool? roundTrip,
    double? chargeableKm,
    double? ratePerKm,
    double? extras,
    double? discount,
    double? totalAmount,
    String? truckId,
    String? driverId,
    String? cargoDescription,
    double? cargoWeight,
    DateTime? tripDate,
    OrderStatus? status,
    String? invoiceId,
  }) {
    return HaulageOrder(
      id: id,
      companyId: companyId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      source: source ?? this.source,
      pickup: pickup ?? this.pickup,
      dropoff: dropoff ?? this.dropoff,
      routeName: routeName ?? this.routeName,
      distanceKm: distanceKm ?? this.distanceKm,
      roundTrip: roundTrip ?? this.roundTrip,
      chargeableKm: chargeableKm ?? this.chargeableKm,
      ratePerKm: ratePerKm ?? this.ratePerKm,
      extras: extras ?? this.extras,
      discount: discount ?? this.discount,
      totalAmount: totalAmount ?? this.totalAmount,
      truckId: truckId ?? this.truckId,
      driverId: driverId ?? this.driverId,
      cargoDescription: cargoDescription ?? this.cargoDescription,
      cargoWeight: cargoWeight ?? this.cargoWeight,
      tripDate: tripDate ?? this.tripDate,
      status: status ?? this.status,
      invoiceId: invoiceId ?? this.invoiceId,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }
}

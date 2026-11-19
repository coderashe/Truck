class TripPriceBreakdown {
  final double oneWayKm;
  final bool roundTrip;
  final double chargeableKm;
  final double ratePerKm;
  final double baseFreight;
  final double extras;
  final double discount;
  final double totalAmount;

  const TripPriceBreakdown({
    required this.oneWayKm,
    required this.roundTrip,
    required this.chargeableKm,
    required this.ratePerKm,
    required this.baseFreight,
    required this.extras,
    required this.discount,
    required this.totalAmount,
  });
}

class PriceCalculator {
  static TripPriceBreakdown calculate({
    required double distanceKm,
    required bool roundTrip,
    required double ratePerKm,
    double extras = 0,
    double discount = 0,
  }) {
    final safeDistance = distanceKm < 0 ? 0.0 : distanceKm;
    final safeRate = ratePerKm < 0 ? 0.0 : ratePerKm;
    final safeExtras = extras < 0 ? 0.0 : extras;
    final safeDiscount = discount < 0 ? 0.0 : discount;

    final chargeableKm = roundTrip ? safeDistance * 2 : safeDistance;
    final baseFreight = chargeableKm * safeRate;
    final total = (baseFreight + safeExtras - safeDiscount).clamp(0.0, double.infinity);

    return TripPriceBreakdown(
      oneWayKm: safeDistance,
      roundTrip: roundTrip,
      chargeableKm: chargeableKm,
      ratePerKm: safeRate,
      baseFreight: double.parse(baseFreight.toStringAsFixed(2)),
      extras: double.parse(safeExtras.toStringAsFixed(2)),
      discount: double.parse(safeDiscount.toStringAsFixed(2)),
      totalAmount: double.parse(total.toStringAsFixed(2)),
    );
  }
}

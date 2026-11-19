import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/customer.dart';
import '../../core/models/driver.dart';
import '../../core/models/expense.dart';
import '../../core/models/invoice.dart';
import '../../core/models/order.dart';
import '../../core/models/truck.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/price_calculator.dart';

class SeedDataUtility {
  static Future<void> seedZimbabweanDataset({
    required String companyId,
    required String ownerUid,
  }) async {
    final db = FirebaseFirestore.instance;
    final rng = Random(42);
    final now = DateTime.now();

    // 1. Update Company Profile with realistic Zimbabwean details
    await db.collection('companies').doc(companyId).update({
      'name': 'ZimHaul Freight & Logistics (Pvt) Ltd',
      'address': '42 Lytton Road, Workington, Harare, Zimbabwe',
      'phone': '+263 242 754 890',
      'email': 'dispatch@zimhaul.co.zw',
      'taxNumber': 'BPN 200489120 / TIN 10045219',
      'bankDetails':
          'Stanbic Bank Zimbabwe • Workington Branch • Acc: 9140004829103 (USD Nostro)',
      'currency': 'USD',
      'defaultRatePerKm': 1.75,
      'defaultRoundTrip': true,
      'invoiceFooter':
          'Thank you for choosing ZimHaul Freight. All accounts due within 14 days.',
      'setupCompleted': true,
    });

    // 2. Seed 5 Trucks
    final truckSpecs = [
      ('AFX 4821', 'Volvo FH16 6x4', 34.0, 'Diesel', TruckStatus.active),
      ('AFZ 9104', 'Scania R500 V8', 32.0, 'Diesel', TruckStatus.active),
      ('AGB 2219', 'Mercedes-Benz Actros 2645', 30.0, 'Diesel', TruckStatus.active),
      ('AGC 7730', 'Freightliner Argosy', 36.0, 'Diesel', TruckStatus.active),
      ('AGD 1158', 'MAN TGX 26.540', 30.0, 'Diesel', TruckStatus.maintenance),
    ];

    final truckIds = <String>[];
    for (final spec in truckSpecs) {
      final ref = db.collection('trucks').doc();
      truckIds.add(ref.id);
      await ref.set(
        Truck(
          id: ref.id,
          companyId: companyId,
          regNumber: spec.$1,
          makeModel: spec.$2,
          capacityTonnes: spec.$3,
          fuelType: spec.$4,
          status: spec.$5,
          createdAt: now.subtract(const Duration(days: 180)),
        ).toMap(),
      );
    }

    // 3. Seed 4 Drivers
    final driverSpecs = [
      ('Tendai Moyo', '+263 772 418 902', 'ZW-CE-88421', 0),
      ('Tatenda Chikwanda', '+263 773 912 440', 'ZW-CE-71209', 1),
      ('Farai Nyathi', '+263 712 604 318', 'ZW-CE-90315', 2),
      ('Blessing Sibanda', '+263 782 119 504', 'ZW-CE-66512', 3),
    ];

    final driverIds = <String>[];
    for (final d in driverSpecs) {
      final ref = db.collection('drivers').doc();
      driverIds.add(ref.id);
      await ref.set(
        Driver(
          id: ref.id,
          companyId: companyId,
          name: d.$1,
          phone: d.$2,
          licenceNumber: d.$3,
          licenceExpiry: now.add(Duration(days: 90 + rng.nextInt(300))),
          assignedTruckId: truckIds[d.$4],
          createdAt: now.subtract(const Duration(days: 180)),
        ).toMap(),
      );
    }

    // 4. Seed 12 Customers
    final customerSpecs = [
      ('Tinashe Gumbo', 'Lafarge Cement Zimbabwe', '+263 772 301 112', 'orders@lafargezim.co.zw', 'Manresa Works, Harare'),
      ('Rumbidzai Mupfumi', 'Delta Beverages Logistics', '+263 774 882 190', 'supply@delta.co.zw', 'Sable House, Southerton, Harare'),
      ('Kudzai Ndoro', 'National Foods Ltd', '+263 712 445 021', 'dispatch@natfoods.co.zw', '10 Stirling Rd, Workington, Harare'),
      ('Chengetai Dube', 'Tongaat Hulett Hippo Valley', '+263 773 519 884', 'logistics@tongaat.co.zw', 'Chiredzi Mill, Masvingo'),
      ('Nomsa Ncube', 'Zimplats Holdings', '+263 772 908 773', 'freight@zimplats.com', 'Ngezi Complex, Mhondoro'),
      ('TapiwaZvobgo', 'Innscor Africa Distribution', '+263 782 330 411', 'fleet@innscor.co.zw', 'Msasa Industrial, Harare'),
      ('Simbarashe Banda', 'Grain Marketing Board', '+263 712 889 201', 'transport@gmb.co.zw', 'Dura Building, Harare'),
      ('Chiedza Choto', 'Profeeds Zimbabwe', '+263 773 114 559', 'orders@profeeds.co.zw', 'Willowvale, Harare'),
      ('Mthokozisi Ndlovu', 'Treger Products', '+263 772 677 812', 'shipping@treger.co.zw', 'Belmont, Bulawayo'),
      ('Vimbai Kaseke', 'Mutare Board & Paper Mills', '+263 774 205 619', 'cargo@mbpm.co.zw', 'St Helen Drive, Mutare'),
      ('Garikai Sithole', 'Sable Chemicals', '+263 712 310 998', 'logistics@sablechem.co.zw', 'Kwekwe Industrial, Midlands'),
      ('Nyasha Makoni', 'Border Timbers Ltd', '+263 783 412 007', 'dispatch@bordertimbers.co.zw', 'Nyamhara, Mutare'),
    ];

    final customerIds = <String>[];
    for (final c in customerSpecs) {
      final ref = db.collection('customers').doc();
      customerIds.add(ref.id);
      await ref.set(
        Customer(
          id: ref.id,
          companyId: companyId,
          name: c.$1,
          business: c.$2,
          phone: c.$3,
          email: c.$4,
          address: c.$5,
          createdAt: now.subtract(const Duration(days: 180)),
        ).toMap(),
      );
    }

    // 5. 8 Realistic Zimbabwean Routes
    final routes = [
      (
        'Harare → Bulawayo',
        const GeoPointLocation(address: 'Workington, Harare', lat: -17.845, lng: 31.022),
        const GeoPointLocation(address: 'Belmont, Bulawayo', lat: -20.165, lng: 28.583),
        439.0,
      ),
      (
        'Harare → Mutare',
        const GeoPointLocation(address: 'Msasa, Harare', lat: -17.840, lng: 31.115),
        const GeoPointLocation(address: 'Nyamhara, Mutare', lat: -18.970, lng: 32.670),
        263.0,
      ),
      (
        'Harare → Beitbridge',
        const GeoPointLocation(address: 'Southerton, Harare', lat: -17.861, lng: 31.015),
        const GeoPointLocation(address: 'Beitbridge Border Post', lat: -22.216, lng: 29.999),
        580.0,
      ),
      (
        'Harare → Victoria Falls',
        const GeoPointLocation(address: 'Harare Depot', lat: -17.829, lng: 31.052),
        const GeoPointLocation(address: 'Victoria Falls Industrial', lat: -17.932, lng: 25.830),
        878.0,
      ),
      (
        'Harare → Gweru',
        const GeoPointLocation(address: 'Harare Depot', lat: -17.829, lng: 31.052),
        const GeoPointLocation(address: 'Gweru Heavy Industrial', lat: -19.450, lng: 29.816),
        275.0,
      ),
      (
        'Harare → Masvingo',
        const GeoPointLocation(address: 'Willowvale, Harare', lat: -17.882, lng: 30.985),
        const GeoPointLocation(address: 'Masvingo Depot', lat: -20.074, lng: 30.832),
        292.0,
      ),
      (
        'Bulawayo → Beitbridge',
        const GeoPointLocation(address: 'Belmont, Bulawayo', lat: -20.165, lng: 28.583),
        const GeoPointLocation(address: 'Beitbridge Border Post', lat: -22.216, lng: 29.999),
        321.0,
      ),
      (
        'Harare → Chirundu',
        const GeoPointLocation(address: 'Workington, Harare', lat: -17.845, lng: 31.022),
        const GeoPointLocation(address: 'Chirundu One-Stop Border', lat: -16.034, lng: 28.851),
        356.0,
      ),
    ];

    final cargos = [
      ('Bagged Portland Cement', 32.0),
      ('Bulk Maize Grain', 34.0),
      ('Packaged Beverages', 26.0),
      ('Mining Equipment & Spares', 29.5),
      ('Sawn Timber Loads', 28.0),
      ('Fertilizer & Agro Inputs', 33.0),
      ('Steel Coils & Hardware', 31.0),
    ];

    // 6. Seed 60 Orders across last 6 months (clustered around 25th-30th for realistic peak patterns)
    int invoiceCounter = 0;
    for (int i = 0; i < 60; i++) {
      final monthOffset = i % 6;
      // Bias ~45% of trips toward days 25-30
      final day = rng.nextDouble() < 0.45
          ? 25 + rng.nextInt(5)
          : 1 + rng.nextInt(24);
      final targetMonth = DateTime(now.year, now.month - monthOffset, 1);
      final maxDay = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
      final tripDate = DateTime(
        targetMonth.year,
        targetMonth.month,
        day.clamp(1, maxDay),
      );

      // Bias repeat customers (first 4 get more orders -> Loyal badge)
      final custIdx = i < 32 ? (i % 4) : rng.nextInt(customerIds.length);
      final route = routes[i % routes.length];
      final cargo = cargos[rng.nextInt(cargos.length)];
      final truckIdx = i % 4;
      final rate = 1.65 + (rng.nextInt(4) * 0.10);
      final roundTrip = rng.nextDouble() < 0.85;
      final extras = rng.nextDouble() < 0.25 ? 85.0 : 0.0;
      final discount = rng.nextDouble() < 0.1 ? 50.0 : 0.0;

      final price = PriceCalculator.calculate(
        distanceKm: route.$4,
        roundTrip: roundTrip,
        ratePerKm: rate,
        extras: extras,
        discount: discount,
      );

      final orderRef = db.collection('orders').doc();
      String? invoiceId;
      OrderStatus status;

      if (monthOffset == 0 && i < 4) {
        status = i.isEven ? OrderStatus.inTransit : OrderStatus.pending;
      } else if (i % 9 == 0) {
        status = OrderStatus.invoiced;
      } else {
        status = OrderStatus.paid;
      }

      if (status == OrderStatus.invoiced || status == OrderStatus.paid) {
        invoiceCounter++;
        final invRef = db.collection('invoices').doc();
        invoiceId = invRef.id;

        final payStatus = status == OrderStatus.paid
            ? PaymentStatus.paid
            : (i % 2 == 0 ? PaymentStatus.partiallyPaid : PaymentStatus.unpaid);
        final paidAmt = payStatus == PaymentStatus.paid
            ? price.totalAmount
            : (payStatus == PaymentStatus.partiallyPaid
                ? double.parse((price.totalAmount * 0.5).toStringAsFixed(2))
                : 0.0);

        await invRef.set(
          Invoice(
            id: invRef.id,
            companyId: companyId,
            orderId: orderRef.id,
            customerId: customerIds[custIdx],
            invoiceNumber: AppFormatters.invoiceNumber(invoiceCounter, tripDate),
            issueDate: tripDate,
            dueDate: tripDate.add(const Duration(days: 14)),
            totalAmount: price.totalAmount,
            amountPaid: paidAmt,
            paymentStatus: payStatus,
            paymentMethod: paidAmt > 0 ? 'Bank Transfer' : null,
            paidAt: paidAmt > 0 ? tripDate.add(const Duration(days: 5)) : null,
            createdAt: tripDate,
          ).toMap(),
        );
      }

      await orderRef.set(
        HaulageOrder(
          id: orderRef.id,
          companyId: companyId,
          customerId: customerIds[custIdx],
          customerName: customerSpecs[custIdx].$2,
          source: OrderSource.values[i % 4],
          pickup: route.$2,
          dropoff: route.$3,
          routeName: route.$1,
          distanceKm: route.$4,
          roundTrip: roundTrip,
          chargeableKm: price.chargeableKm,
          ratePerKm: rate,
          extras: extras,
          discount: discount,
          totalAmount: price.totalAmount,
          truckId: truckIds[truckIdx],
          driverId: driverIds[truckIdx],
          cargoDescription: cargo.$1,
          cargoWeight: cargo.$2,
          tripDate: tripDate,
          status: status,
          invoiceId: invoiceId,
          createdBy: ownerUid,
          createdAt: tripDate,
        ).toMap(),
      );
    }

    await db.collection('companies').doc(companyId).update({
      'invoiceCounter': invoiceCounter,
    });

    // 7. Seed 40 Expenses across all 9 categories
    final expenseTemplates = [
      (ExpenseCategory.fuel, 'Diesel refill at Zuva Masvingo Rd', 420.0),
      (ExpenseCategory.tolls, 'Beitbridge border & ZINARA tollgates', 145.0),
      (ExpenseCategory.maintenance, 'Routine 15,000km service & filters', 310.0),
      (ExpenseCategory.tyres, 'Steer axle tyre replacement', 540.0),
      (ExpenseCategory.driverWages, 'Monthly driver haulage allowance', 650.0),
      (ExpenseCategory.insurance, 'Comprehensive commercial fleet cover', 380.0),
      (ExpenseCategory.licences, 'COMESA & cross-border permit renewal', 210.0),
      (ExpenseCategory.office, 'Dispatch office airtime & internet', 95.0),
      (ExpenseCategory.other, 'Load tarpaulin & lashing straps', 130.0),
    ];

    for (int i = 0; i < 40; i++) {
      final tmpl = expenseTemplates[i % expenseTemplates.length];
      final expDate = now.subtract(Duration(days: rng.nextInt(175)));
      final truckId = (tmpl.$1 == ExpenseCategory.office)
          ? null
          : truckIds[i % truckIds.length];

      final ref = db.collection('expenses').doc();
      await ref.set(
        Expense(
          id: ref.id,
          companyId: companyId,
          category: tmpl.$1,
          amount: double.parse(
            (tmpl.$3 * (0.85 + rng.nextDouble() * 0.4)).toStringAsFixed(2),
          ),
          date: expDate,
          description: tmpl.$2,
          truckId: truckId,
          createdAt: expDate,
        ).toMap(),
      );
    }
  }
}

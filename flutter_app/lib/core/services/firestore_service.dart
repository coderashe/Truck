import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../models/company.dart';
import '../models/customer.dart';
import '../models/driver.dart';
import '../models/expense.dart';
import '../models/invoice.dart';
import '../models/order.dart';
import '../models/truck.dart';
import '../utils/formatters.dart';

class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // User & Company Onboarding
  // ---------------------------------------------------------------------------
  Future<AppUser?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  Stream<AppUser?> watchUserProfile(String uid) {
    return _db.collection('users').doc(uid).snapshots().map(
          (doc) => doc.exists ? AppUser.fromFirestore(doc) : null,
        );
  }

  Future<void> ensureOwnerAccount(User firebaseUser, {String? name}) async {
    final userRef = _db.collection('users').doc(firebaseUser.uid);
    final existing = await userRef.get();
    if (existing.exists) return;

    final companyRef = _db.collection('companies').doc();
    final now = DateTime.now();
    final batch = _db.batch();

    final codes = generateJoinCodes();
    final company = Company(
      id: companyRef.id,
      name: '',
      address: '',
      phone: '',
      email: firebaseUser.email ?? '',
      taxNumber: '',
      bankDetails: '',
      ownerId: firebaseUser.uid,
      setupCompleted: false,
      joinCodes: codes,
      createdAt: now,
    );

    final appUser = AppUser(
      uid: firebaseUser.uid,
      companyId: companyRef.id,
      name: name?.trim().isNotEmpty == true
          ? name!.trim()
          : (firebaseUser.displayName ?? 'Manager'),
      email: firebaseUser.email ?? '',
      role: UserRole.owner,
      createdAt: now,
    );

    batch.set(companyRef, company.toMap());
    batch.set(userRef, appUser.toMap());
    await batch.commit();
  }

  Stream<Company?> watchCompany(String companyId) {
    if (companyId.isEmpty) return Stream.value(null);
    return _db.collection('companies').doc(companyId).snapshots().map(
          (doc) => doc.exists ? Company.fromFirestore(doc) : null,
        );
  }

  Future<void> updateCompany(Company company) async {
    await _db.collection('companies').doc(company.id).update(company.toMap());
  }

  // ---------------------------------------------------------------------------
  // Trucks
  // ---------------------------------------------------------------------------
  Stream<List<Truck>> watchTrucks(String companyId) {
    return _db
        .collection('trucks')
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(Truck.fromFirestore).toList();
      list.sort((a, b) => a.regNumber.compareTo(b.regNumber));
      return list;
    });
  }

  Future<String> saveTruck(Truck truck) async {
    final ref = truck.id.isEmpty
        ? _db.collection('trucks').doc()
        : _db.collection('trucks').doc(truck.id);
    await ref.set(truck.toMap(), SetOptions(merge: true));
    return ref.id;
  }

  Future<void> deleteTruck(String truckId) async {
    await _db.collection('trucks').doc(truckId).delete();
  }

  // ---------------------------------------------------------------------------
  // Drivers
  // ---------------------------------------------------------------------------
  Stream<List<Driver>> watchDrivers(String companyId) {
    return _db
        .collection('drivers')
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(Driver.fromFirestore).toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  Future<String> saveDriver(Driver driver) async {
    final ref = driver.id.isEmpty
        ? _db.collection('drivers').doc()
        : _db.collection('drivers').doc(driver.id);
    await ref.set(driver.toMap(), SetOptions(merge: true));
    return ref.id;
  }

  Future<void> deleteDriver(String driverId) async {
    await _db.collection('drivers').doc(driverId).delete();
  }

  // ---------------------------------------------------------------------------
  // Customers
  // ---------------------------------------------------------------------------
  Stream<List<Customer>> watchCustomers(String companyId) {
    return _db
        .collection('customers')
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(Customer.fromFirestore).toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  Future<String> saveCustomer(Customer customer) async {
    final ref = customer.id.isEmpty
        ? _db.collection('customers').doc()
        : _db.collection('customers').doc(customer.id);
    await ref.set(customer.toMap(), SetOptions(merge: true));
    return ref.id;
  }

  Future<void> deleteCustomer(String customerId) async {
    await _db.collection('customers').doc(customerId).delete();
  }

  // ---------------------------------------------------------------------------
  // Orders
  // ---------------------------------------------------------------------------
  Stream<List<HaulageOrder>> watchOrders(String companyId) {
    return _db
        .collection('orders')
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(HaulageOrder.fromFirestore).toList();
      list.sort((a, b) => b.tripDate.compareTo(a.tripDate));
      return list;
    });
  }

  Future<String> saveOrder(HaulageOrder order) async {
    final ref = order.id.isEmpty
        ? _db.collection('orders').doc()
        : _db.collection('orders').doc(order.id);
    await ref.set(order.toMap(), SetOptions(merge: true));
    return ref.id;
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _db.collection('orders').doc(orderId).update({
      'status': status.label,
    });
  }

  Future<void> deleteOrder(String orderId) async {
    await _db.collection('orders').doc(orderId).delete();
  }

  // ---------------------------------------------------------------------------
  // Invoices
  // ---------------------------------------------------------------------------
  Stream<List<Invoice>> watchInvoices(String companyId) {
    return _db
        .collection('invoices')
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(Invoice.fromFirestore).toList();
      list.sort((a, b) => b.issueDate.compareTo(a.issueDate));
      return list;
    });
  }

  Future<Invoice> createInvoiceForOrder({
    required HaulageOrder order,
    int dueDays = 14,
  }) async {
    final companyRef = _db.collection('companies').doc(order.companyId);
    final orderRef = _db.collection('orders').doc(order.id);
    final invoiceRef = _db.collection('invoices').doc();
    final now = DateTime.now();

    return _db.runTransaction((tx) async {
      final companySnap = await tx.get(companyRef);
      final currentCounter =
          (companySnap.data()?['invoiceCounter'] as num?)?.toInt() ?? 0;
      final nextCounter = currentCounter + 1;
      final invNumber = AppFormatters.invoiceNumber(nextCounter, now);

      final invoice = Invoice(
        id: invoiceRef.id,
        companyId: order.companyId,
        orderId: order.id,
        customerId: order.customerId,
        invoiceNumber: invNumber,
        issueDate: now,
        dueDate: now.add(Duration(days: dueDays)),
        totalAmount: order.totalAmount,
        amountPaid: 0,
        paymentStatus: PaymentStatus.unpaid,
        createdAt: now,
      );

      tx.update(companyRef, {'invoiceCounter': nextCounter});
      tx.set(invoiceRef, invoice.toMap());
      tx.update(orderRef, {
        'invoiceId': invoiceRef.id,
        'status': OrderStatus.invoiced.label,
      });

      return invoice;
    });
  }

  Future<void> updateInvoicePdfUrl(String invoiceId, String pdfUrl) async {
    await _db.collection('invoices').doc(invoiceId).update({'pdfUrl': pdfUrl});
  }

  Future<void> recordInvoicePayment({
    required Invoice invoice,
    required double amountPaid,
    required String paymentMethod,
    required DateTime paidAt,
  }) async {
    final status = amountPaid >= invoice.totalAmount
        ? PaymentStatus.paid
        : (amountPaid > 0 ? PaymentStatus.partiallyPaid : PaymentStatus.unpaid);

    final batch = _db.batch();
    batch.update(_db.collection('invoices').doc(invoice.id), {
      'amountPaid': amountPaid,
      'paymentStatus': status.label,
      'paymentMethod': paymentMethod,
      'paidAt': Timestamp.fromDate(paidAt),
    });

    if (status == PaymentStatus.paid) {
      batch.update(_db.collection('orders').doc(invoice.orderId), {
        'status': OrderStatus.paid.label,
      });
    }

    await batch.commit();
  }

  // ---------------------------------------------------------------------------
  // Expenses
  // ---------------------------------------------------------------------------
  Stream<List<Expense>> watchExpenses(String companyId) {
    return _db
        .collection('expenses')
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(Expense.fromFirestore).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Future<String> saveExpense(Expense expense) async {
    final ref = expense.id.isEmpty
        ? _db.collection('expenses').doc()
        : _db.collection('expenses').doc(expense.id);
    await ref.set(expense.toMap(), SetOptions(merge: true));
    return ref.id;
  }

  Future<void> deleteExpense(String expenseId) async {
    await _db.collection('expenses').doc(expenseId).delete();
  }

  // ---------------------------------------------------------------------------
  // Team & Join Codes
  // ---------------------------------------------------------------------------

  /// Generate a random 4-char alphanumeric code with a role prefix.
  static String _generateCode(String prefix) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = DateTime.now().millisecondsSinceEpoch;
    final code =
        List.generate(4, (i) => chars[(rand >> (i * 4)) % chars.length])
            .join();
    return '$prefix-$code';
  }

  /// Called when a new company is created — generates all 3 join codes.
  Map<String, String> generateJoinCodes() => {
        'manager': _generateCode('MGR'),
        'accountant': _generateCode('ACC'),
        'driver': _generateCode('DRV'),
      };

  /// Regenerate a single role's join code.
  Future<String> regenerateJoinCode(String companyId, String role) async {
    final prefix =
        role == 'manager' ? 'MGR' : role == 'accountant' ? 'ACC' : 'DRV';
    final newCode = _generateCode(prefix);
    await _db.collection('companies').doc(companyId).update({
      'joinCodes.$role': newCode,
    });
    return newCode;
  }

  /// Look up a company by join code. Returns (companyId, role) or null.
  Future<({String companyId, String role})?> findCompanyByJoinCode(
      String code) async {
    final upperCode = code.trim().toUpperCase();
    // Determine which role field to query based on prefix
    String roleKey;
    if (upperCode.startsWith('MGR-')) {
      roleKey = 'manager';
    } else if (upperCode.startsWith('ACC-')) {
      roleKey = 'accountant';
    } else if (upperCode.startsWith('DRV-')) {
      roleKey = 'driver';
    } else {
      return null;
    }

    final snap = await _db
        .collection('companies')
        .where('joinCodes.$roleKey', isEqualTo: upperCode)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return (companyId: snap.docs.first.id, role: roleKey);
  }

  /// Join a company with a code — updates the user's document and adds them to
  /// the members list.
  Future<void> joinCompany({
    required String uid,
    required String companyId,
    required String role,
    required String name,
    required String email,
    String? driverId,
  }) async {
    final batch = _db.batch();
    final userRef = _db.collection('users').doc(uid);
    final companyRef = _db.collection('companies').doc(companyId);

    batch.update(userRef, {
      'companyId': companyId,
      'role': role,
      if (driverId != null) 'driverId': driverId,
    });

    final member = TeamMember(
      uid: uid,
      name: name,
      email: email,
      role: role,
      joinedAt: DateTime.now(),
    );

    batch.update(companyRef, {
      'members': FieldValue.arrayUnion([member.toMap()]),
    });

    await batch.commit();
  }

  /// Update a team member's role.
  Future<void> updateMemberRole({
    required String companyId,
    required String uid,
    required String newRole,
  }) async {
    // Update user document
    await _db.collection('users').doc(uid).update({'role': newRole});

    // Update in members array — Firestore doesn't support updating array
    // elements directly, so we read, modify, write.
    final companyDoc =
        await _db.collection('companies').doc(companyId).get();
    final company = Company.fromFirestore(companyDoc);
    final updatedMembers = company.members.map((m) {
      if (m.uid == uid) {
        return TeamMember(
            uid: m.uid,
            name: m.name,
            email: m.email,
            role: newRole,
            joinedAt: m.joinedAt);
      }
      return m;
    }).toList();
    await _db.collection('companies').doc(companyId).update({
      'members': updatedMembers.map((m) => m.toMap()).toList(),
    });
  }

  /// Remove a member from the company.
  Future<void> removeMember({
    required String companyId,
    required String uid,
  }) async {
    final companyDoc =
        await _db.collection('companies').doc(companyId).get();
    final company = Company.fromFirestore(companyDoc);
    final updatedMembers =
        company.members.where((m) => m.uid != uid).toList();

    final batch = _db.batch();
    batch.update(_db.collection('users').doc(uid),
        {'companyId': '', 'role': 'owner'});
    batch.update(_db.collection('companies').doc(companyId), {
      'members': updatedMembers.map((m) => m.toMap()).toList(),
    });
    await batch.commit();
  }

  /// Update the current user's personal profile.
  Future<void> updateUserProfile({
    required String uid,
    required String name,
    required String phone,
  }) async {
    await _db.collection('users').doc(uid).update({
      'name': name,
      'phone': phone,
    });
  }

  /// Watch all team members for a company (from the members array).
  Stream<List<TeamMember>> watchTeamMembers(String companyId) {
    return _db
        .collection('companies')
        .doc(companyId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return [];
      final company = Company.fromFirestore(doc);
      return company.members;
    });
  }
}

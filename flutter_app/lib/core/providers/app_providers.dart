import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../models/company.dart';
import '../models/customer.dart';
import '../models/driver.dart';
import '../models/expense.dart';
import '../models/invoice.dart';
import '../models/order.dart';
import '../models/truck.dart';
import '../services/firestore_service.dart';
import '../services/maps_service.dart';
import '../services/pdf_invoice_service.dart';
import '../services/storage_service.dart';

// -----------------------------------------------------------------------------
// Core Services
// -----------------------------------------------------------------------------
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final pdfInvoiceServiceProvider = Provider<PdfInvoiceService>((ref) {
  return PdfInvoiceService();
});

final mapsServiceProvider = Provider<MapsService>((ref) {
  return MapsService();
});

// -----------------------------------------------------------------------------
// Theme Mode
// -----------------------------------------------------------------------------
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

// -----------------------------------------------------------------------------
// Auth & Tenant Context
// -----------------------------------------------------------------------------
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final currentUserProfileProvider = StreamProvider<AppUser?>((ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) return Stream.value(null);
  return ref.watch(firestoreServiceProvider).watchUserProfile(authUser.uid);
});

final currentCompanyIdProvider = Provider<String?>((ref) {
  final profile = ref.watch(currentUserProfileProvider).valueOrNull;
  if (profile == null || profile.companyId.isEmpty) return null;
  return profile.companyId;
});

final currentCompanyProvider = StreamProvider<Company?>((ref) {
  final companyId = ref.watch(currentCompanyIdProvider);
  if (companyId == null) return Stream.value(null);
  return ref.watch(firestoreServiceProvider).watchCompany(companyId);
});

// -----------------------------------------------------------------------------
// Tenant-Isolated Collection Streams
// -----------------------------------------------------------------------------
final trucksProvider = StreamProvider<List<Truck>>((ref) {
  final companyId = ref.watch(currentCompanyIdProvider);
  if (companyId == null) return Stream.value(const []);
  return ref.watch(firestoreServiceProvider).watchTrucks(companyId);
});

final driversProvider = StreamProvider<List<Driver>>((ref) {
  final companyId = ref.watch(currentCompanyIdProvider);
  if (companyId == null) return Stream.value(const []);
  return ref.watch(firestoreServiceProvider).watchDrivers(companyId);
});

final customersProvider = StreamProvider<List<Customer>>((ref) {
  final companyId = ref.watch(currentCompanyIdProvider);
  if (companyId == null) return Stream.value(const []);
  return ref.watch(firestoreServiceProvider).watchCustomers(companyId);
});

final ordersProvider = StreamProvider<List<HaulageOrder>>((ref) {
  final companyId = ref.watch(currentCompanyIdProvider);
  if (companyId == null) return Stream.value(const []);
  return ref.watch(firestoreServiceProvider).watchOrders(companyId);
});

final invoicesProvider = StreamProvider<List<Invoice>>((ref) {
  final companyId = ref.watch(currentCompanyIdProvider);
  if (companyId == null) return Stream.value(const []);
  return ref.watch(firestoreServiceProvider).watchInvoices(companyId);
});

final expensesProvider = StreamProvider<List<Expense>>((ref) {
  final companyId = ref.watch(currentCompanyIdProvider);
  if (companyId == null) return Stream.value(const []);
  return ref.watch(firestoreServiceProvider).watchExpenses(companyId);
});

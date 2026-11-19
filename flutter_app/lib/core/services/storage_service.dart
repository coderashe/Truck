import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  Future<String> uploadCompanyLogo({
    required String companyId,
    required File file,
  }) async {
    final ref = _storage.ref('companies/$companyId/logo.jpg');
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<String> uploadTruckPhoto({
    required String companyId,
    required String truckId,
    required File file,
  }) async {
    final ref = _storage.ref('companies/$companyId/trucks/$truckId.jpg');
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<String> uploadExpenseReceipt({
    required String companyId,
    required String expenseId,
    required File file,
  }) async {
    final ref = _storage.ref('companies/$companyId/receipts/$expenseId.jpg');
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<String> uploadInvoicePdf({
    required String companyId,
    required String invoiceNumber,
    required Uint8List bytes,
  }) async {
    final ref = _storage.ref('companies/$companyId/invoices/$invoiceNumber.pdf');
    await ref.putData(bytes, SettableMetadata(contentType: 'application/pdf'));
    return ref.getDownloadURL();
  }
}

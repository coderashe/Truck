import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/models/invoice.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/status_chip.dart';

class InvoicePreviewScreen extends ConsumerStatefulWidget {
  final String invoiceId;

  const InvoicePreviewScreen({super.key, required this.invoiceId});

  @override
  ConsumerState<InvoicePreviewScreen> createState() =>
      _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends ConsumerState<InvoicePreviewScreen> {
  bool _isUploading = false;

  Future<Uint8List?> _buildBytes() async {
    final invoices = ref.read(invoicesProvider).valueOrNull ?? [];
    final orders = ref.read(ordersProvider).valueOrNull ?? [];
    final customers = ref.read(customersProvider).valueOrNull ?? [];
    final trucks = ref.read(trucksProvider).valueOrNull ?? [];
    final company = ref.read(currentCompanyProvider).valueOrNull;

    final invoice = invoices.where((i) => i.id == widget.invoiceId).firstOrNull;
    if (invoice == null || company == null) return null;

    final order = orders.where((o) => o.id == invoice.orderId).firstOrNull;
    if (order == null) return null;

    final customer =
        customers.where((c) => c.id == order.customerId).firstOrNull;
    final truck = trucks.where((t) => t.id == order.truckId).firstOrNull;

    return ref.read(pdfInvoiceServiceProvider).buildInvoicePdf(
          company: company,
          invoice: invoice,
          order: order,
          customer: customer,
          truck: truck,
        );
  }

  Future<void> _shareAndArchive(Invoice invoice) async {
    setState(() => _isUploading = true);
    try {
      final bytes = await _buildBytes();
      if (bytes == null) return;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${invoice.invoiceNumber}.pdf');
      await file.writeAsBytes(bytes);

      // Save copy to Firebase Storage if not yet archived
      if (invoice.pdfUrl == null || invoice.pdfUrl!.isEmpty) {
        try {
          final url = await ref.read(storageServiceProvider).uploadInvoicePdf(
                companyId: invoice.companyId,
                invoiceNumber: invoice.invoiceNumber,
                bytes: bytes,
              );
          await ref
              .read(firestoreServiceProvider)
              .updateInvoicePdfUrl(invoice.id, url);
        } catch (_) {
          // Offline fallback: local sharing still succeeds
        }
      }

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Invoice ${invoice.invoiceNumber}',
        text: 'Please find attached invoice ${invoice.invoiceNumber}.',
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _showPaymentDialog(Invoice invoice, String currency) async {
    final amountCtrl = TextEditingController(
      text: invoice.totalAmount.toStringAsFixed(2),
    );
    String method = invoice.paymentMethod ?? 'Bank Transfer';
    DateTime paidAt = DateTime.now();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Record Payment • ${invoice.invoiceNumber}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount Paid ($currency)',
                  helperText:
                      'Total due: ${AppFormatters.currency(invoice.totalAmount, code: currency)}',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: method,
                decoration: const InputDecoration(labelText: 'Payment Method'),
                items: const [
                  DropdownMenuItem(
                      value: 'Bank Transfer', child: Text('Bank Transfer')),
                  DropdownMenuItem(value: 'EcoCash', child: Text('EcoCash')),
                  DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'Card', child: Text('Card')),
                ],
                onChanged: (v) =>
                    setDialogState(() => method = v ?? 'Bank Transfer'),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Payment Date'),
                subtitle: Text(AppFormatters.date(paidAt)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: paidAt,
                    firstDate: DateTime(2023),
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                  );
                  if (picked != null) setDialogState(() => paidAt = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save Payment'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      final paid = double.tryParse(amountCtrl.text.trim()) ?? invoice.totalAmount;
      await ref.read(firestoreServiceProvider).recordInvoicePayment(
            invoice: invoice,
            amountPaid: paid,
            paymentMethod: method,
            paidAt: paidAt,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment recorded')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoices = ref.watch(invoicesProvider).valueOrNull ?? [];
    final company = ref.watch(currentCompanyProvider).valueOrNull;
    final currency = company?.currency ?? 'USD';

    final invoice =
        invoices.where((i) => i.id == widget.invoiceId).firstOrNull;
    if (invoice == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invoice')),
        body: const Center(child: Text('Invoice not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(invoice.invoiceNumber),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: StatusChip.payment(invoice.paymentStatus)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PdfPreview(
              canChangePageFormat: false,
              canChangeOrientation: false,
              allowPrinting: true,
              allowSharing: false,
              build: (_) async => (await _buildBytes()) ?? Uint8List(0),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showPaymentDialog(invoice, currency),
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('Record Payment'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed:
                          _isUploading ? null : () => _shareAndArchive(invoice),
                      icon: _isUploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.share),
                      label: const Text('Share PDF'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

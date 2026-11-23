import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/company.dart';
import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/order.dart';
import '../models/truck.dart';
import '../utils/formatters.dart';

class PdfInvoiceService {
  Future<Uint8List> buildInvoicePdf({
    required Company company,
    required Invoice invoice,
    required HaulageOrder order,
    Customer? customer,
    Truck? truck,
  }) async {
    final pdf = pw.Document();
    final accentColor = PdfColor.fromInt(company.invoiceAccentHex);
    const amberColor = PdfColor.fromInt(0xFFF59E0B);
    const lightGray = PdfColor.fromInt(0xFFF8FAFC);
    const borderGray = PdfColor.fromInt(0xFFE2E8F0);
    const mutedText = PdfColor.fromInt(0xFF475569);

    pw.MemoryImage? logoImage;
    if (company.logoUrl != null && company.logoUrl!.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(company.logoUrl!));
        if (response.statusCode == 200) {
          logoImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (_) {
        // Proceed gracefully without logo if offline
      }
    }

    final currency = company.currency;
    final baseFreight = order.chargeableKm * order.ratePerKm;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header Banner
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: accentColor,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (logoImage != null) ...[
                        pw.Container(
                          width: 52,
                          height: 52,
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            borderRadius: pw.BorderRadius.circular(6),
                          ),
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                        ),
                        pw.SizedBox(width: 14),
                      ],
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              company.name.isEmpty ? 'TruckFlow Haulage' : company.name,
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 18,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            if (company.address.isNotEmpty)
                              pw.Text(
                                company.address,
                                style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 9),
                              ),
                            pw.Text(
                              [company.phone, company.email]
                                  .where((e) => e.isNotEmpty)
                                  .join('  |  '),
                              style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 9),
                            ),
                            if (company.taxNumber.isNotEmpty)
                              pw.Text(
                                'TIN / Reg: ${company.taxNumber}',
                                style: const pw.TextStyle(color: amberColor, fontSize: 9),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'INVOICE',
                      style: pw.TextStyle(
                        color: amberColor,
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      invoice.invoiceNumber,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Status: ${invoice.paymentStatus.label}',
                      style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 9),
                    ),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Bill To & Invoice Metadata
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(14),
                  decoration: pw.BoxDecoration(
                    color: lightGray,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: borderGray),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BILL TO',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: mutedText,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        customer?.business.isNotEmpty == true
                            ? customer!.business
                            : order.customerName,
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (customer != null) ...[
                        pw.Text('Attn: ${customer.name}', style: const pw.TextStyle(fontSize: 10)),
                        if (customer.phone.isNotEmpty)
                          pw.Text(customer.phone, style: const pw.TextStyle(fontSize: 9, color: mutedText)),
                        if (customer.email.isNotEmpty)
                          pw.Text(customer.email, style: const pw.TextStyle(fontSize: 9, color: mutedText)),
                        if (customer.address.isNotEmpty)
                          pw.Text(customer.address, style: const pw.TextStyle(fontSize: 9, color: mutedText)),
                      ],
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(14),
                  decoration: pw.BoxDecoration(
                    color: lightGray,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: borderGray),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _metaRow('Issue Date:', AppFormatters.date(invoice.issueDate)),
                      _metaRow('Due Date:', AppFormatters.date(invoice.dueDate)),
                      _metaRow('Trip Date:', AppFormatters.date(order.tripDate)),
                      _metaRow('Route:', order.routeName),
                      if (truck != null)
                        _metaRow('Vehicle:', '${truck.regNumber} (${truck.makeModel})'),
                    ],
                  ),
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 18),

          // Trip Details Summary
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: borderGray),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'HAULAGE & ROUTE SUMMARY',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Pickup:', style: const pw.TextStyle(fontSize: 8, color: mutedText)),
                          pw.Text(order.pickup.address, style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Drop-off:', style: const pw.TextStyle(fontSize: 8, color: mutedText)),
                          pw.Text(order.dropoff.address, style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Cargo: ${order.cargoDescription} (${order.cargoWeight.toStringAsFixed(1)} tonnes)   •   One-Way Distance: ${AppFormatters.km(order.distanceKm)}   •   ${order.roundTrip ? 'Round-Trip Billing (2× Return Leg Included)' : 'One-Way Billing'}',
                  style: const pw.TextStyle(fontSize: 9, color: mutedText),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 18),

          // Line Items Table
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
            headerDecoration: pw.BoxDecoration(color: accentColor),
            cellStyle: const pw.TextStyle(fontSize: 9.5),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: pw.TableBorder.all(color: borderGray, width: 0.6),
            columnWidths: {
              0: const pw.FlexColumnWidth(4),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1.8),
            },
            headers: ['Description', 'Qty / Km', 'Rate', 'Amount'],
            data: [
              [
                'Haulage Service: ${order.routeName}\n${order.roundTrip ? 'Round-trip (${AppFormatters.km(order.distanceKm)} × 2 legs)' : 'One-way (${AppFormatters.km(order.distanceKm)})'}',
                '${order.chargeableKm.toStringAsFixed(0)} km',
                '${AppFormatters.currency(order.ratePerKm, code: currency)}/km',
                AppFormatters.currency(baseFreight, code: currency),
              ],
              if (order.extras > 0)
                [
                  'Extra Charges (Waiting / Border / Loading)',
                  '1',
                  AppFormatters.currency(order.extras, code: currency),
                  AppFormatters.currency(order.extras, code: currency),
                ],
              if (order.discount > 0)
                [
                  'Agreed Discount',
                  '1',
                  '-${AppFormatters.currency(order.discount, code: currency)}',
                  '-${AppFormatters.currency(order.discount, code: currency)}',
                ],
            ],
          ),

          pw.SizedBox(height: 16),

          // Totals Box
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 230,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: lightGray,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: borderGray),
              ),
              child: pw.Column(
                children: [
                  _totalRow('Subtotal', AppFormatters.currency(baseFreight, code: currency)),
                  if (order.extras > 0)
                    _totalRow('Extras', AppFormatters.currency(order.extras, code: currency)),
                  if (order.discount > 0)
                    _totalRow('Discount', '-${AppFormatters.currency(order.discount, code: currency)}'),
                  pw.Divider(color: borderGray),
                  _totalRow(
                    'TOTAL DUE',
                    AppFormatters.currency(invoice.totalAmount, code: currency),
                    bold: true,
                    fontSize: 12,
                  ),
                  if (invoice.amountPaid > 0) ...[
                    _totalRow('Amount Paid', AppFormatters.currency(invoice.amountPaid, code: currency)),
                    _totalRow(
                      'Balance Due',
                      AppFormatters.currency(invoice.balanceDue, code: currency),
                      bold: true,
                    ),
                  ],
                ],
              ),
            ),
          ),

          pw.SizedBox(height: 24),

          // Payment Instructions & Footer
          if (company.bankDetails.isNotEmpty)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: borderGray),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'PAYMENT INSTRUCTIONS / BANK DETAILS',
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(company.bankDetails, style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ),

          if (company.invoiceFooter.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Center(
              child: pw.Text(
                company.invoiceFooter,
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 9, color: mutedText),
              ),
            ),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _metaRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColor.fromInt(0xFF475569))),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _totalRow(String label, String value, {bool bold = false, double fontSize = 10}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

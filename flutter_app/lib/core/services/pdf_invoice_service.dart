import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/company.dart';
import '../models/customer.dart';
import '../models/expense.dart';
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

  // ─────────────────────────────────────────────────────────────────────────
  // Customer Account Statement
  // ─────────────────────────────────────────────────────────────────────────

  /// Generates a customer account statement PDF matching the Shorecape format.
  /// [transactions] = list of invoices + payments sorted by date ascending.
  /// Each entry: { date, ref, description, origAmt, unpaid }
  Future<Uint8List> buildCustomerStatement({
    required Company company,
    required Customer customer,
    required List<HaulageOrder> orders,
    required List<Invoice> invoices,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final pdf = pw.Document();
    final accentColor = PdfColor.fromInt(company.invoiceAccentHex);
    const lightGray = PdfColor.fromInt(0xFFF8FAFC);
    const borderGray = PdfColor.fromInt(0xFFE2E8F0);
    const mutedText = PdfColor.fromInt(0xFF475569);
    const redColor = PdfColor.fromInt(0xFFDC2626);

    pw.MemoryImage? logoImage;
    if (company.logoUrl != null && company.logoUrl!.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(company.logoUrl!));
        if (response.statusCode == 200) {
          logoImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (_) {}
    }

    final currency = company.currency;

    // Filter invoices for this customer in date range
    final custInvoices = invoices
        .where((inv) =>
            inv.customerId == customer.id &&
            !inv.issueDate.isBefore(fromDate) &&
            !inv.issueDate.isAfter(toDate))
        .toList()
      ..sort((a, b) => a.issueDate.compareTo(b.issueDate));

    // Build transaction rows: invoice rows + payment rows
    final List<_StatementRow> rows = [];
    for (final inv in custInvoices) {
      // Find matching order for description
      final order = orders.where((o) => o.id == inv.orderId).firstOrNull;
      final desc = order != null
          ? 'Haulage: ${order.routeName}'
          : 'Invoice ${inv.invoiceNumber}';

      rows.add(_StatementRow(
        date: inv.issueDate,
        ref: inv.invoiceNumber,
        description: desc,
        origAmt: inv.totalAmount,
        unpaid: inv.balanceDue,
        isPayment: false,
      ));

      // Add payment row if paid
      if (inv.amountPaid > 0) {
        rows.add(_StatementRow(
          date: inv.issueDate,
          ref: 'REC-${inv.invoiceNumber}',
          description: 'Payment Received',
          origAmt: -inv.amountPaid,
          unpaid: 0,
          isPayment: true,
        ));
      }
    }

    final totalOutstanding = custInvoices.fold<double>(0, (s, i) => s + i.balanceDue);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.all(18),
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
                          width: 48, height: 48,
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            borderRadius: pw.BorderRadius.circular(6),
                          ),
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                        ),
                        pw.SizedBox(width: 12),
                      ],
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              company.name.isEmpty ? 'TruckFlow Haulage' : company.name,
                              style: pw.TextStyle(color: PdfColors.white, fontSize: 16, fontWeight: pw.FontWeight.bold),
                            ),
                            if (company.address.isNotEmpty)
                              pw.Text(company.address, style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 8)),
                            pw.Text(
                              [company.phone, company.email].where((e) => e.isNotEmpty).join('  |  '),
                              style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 8),
                            ),
                            if (company.taxNumber.isNotEmpty)
                              pw.Text('TIN: ${company.taxNumber}', style: const pw.TextStyle(color: PdfColors.amber, fontSize: 8)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('ACCOUNT STATEMENT',
                        style: pw.TextStyle(color: PdfColors.amber, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('Date: ${AppFormatters.date(DateTime.now())}',
                        style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 9)),
                    pw.Text('Period: ${AppFormatters.date(fromDate)} – ${AppFormatters.date(toDate)}',
                        style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 9)),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 16),

          // Statement For block
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: lightGray,
              border: pw.Border.all(color: borderGray),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Statement For:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                _stmtMetaRow('Customer Name:', customer.business.isNotEmpty ? customer.business : customer.name),
                _stmtMetaRow('Contact:', customer.name),
                if (customer.phone.isNotEmpty) _stmtMetaRow('Phone:', customer.phone),
                if (customer.email.isNotEmpty) _stmtMetaRow('Email:', customer.email),
                if (customer.address.isNotEmpty) _stmtMetaRow('Address:', customer.address),
              ],
            ),
          ),

          pw.SizedBox(height: 16),

          // Transaction table
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8,
            ),
            headerDecoration: pw.BoxDecoration(color: accentColor),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            border: pw.TableBorder.all(color: borderGray, width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(60),
              1: const pw.FixedColumnWidth(90),
              2: const pw.FlexColumnWidth(3),
              3: const pw.FixedColumnWidth(70),
              4: const pw.FixedColumnWidth(70),
            },
            headers: ['Date', 'Inv / Pymnt', 'Description', 'Orig Amnt', 'Unpaid'],
            data: [
              // Brought forward row
              [
                AppFormatters.date(fromDate),
                '-',
                'BROUGHT FORWARD',
                '-',
                '-',
              ],
              ...rows.map((r) => [
                AppFormatters.date(r.date),
                r.ref,
                r.description,
                r.isPayment
                    ? '-${AppFormatters.currency(r.origAmt.abs(), code: currency)}'
                    : AppFormatters.currency(r.origAmt, code: currency),
                r.unpaid > 0
                    ? AppFormatters.currency(r.unpaid, code: currency)
                    : '-',
              ]),
            ],
          ),

          pw.SizedBox(height: 8),

          // Total outstanding
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: pw.BoxDecoration(
                color: totalOutstanding > 0 ? const PdfColor.fromInt(0xFFFEF2F2) : lightGray,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(
                  color: totalOutstanding > 0 ? redColor : borderGray,
                ),
              ),
              child: pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text('Total Amount Outstanding: ',
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                    AppFormatters.currency(totalOutstanding, code: currency),
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: totalOutstanding > 0 ? redColor : const PdfColor.fromInt(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ),
          ),

          pw.SizedBox(height: 20),

          // Bank details footer
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
                  pw.Text('PAYMENT DETAILS',
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: accentColor)),
                  pw.SizedBox(height: 4),
                  pw.Text(company.bankDetails, style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ),

          if (company.invoiceFooter.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Center(
              child: pw.Text(company.invoiceFooter,
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 8.5, color: mutedText)),
            ),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Business Position / Shareholder Report
  // ─────────────────────────────────────────────────────────────────────────

  Future<Uint8List> buildBusinessPositionReport({
    required Company company,
    required List<HaulageOrder> orders,
    required List<Invoice> invoices,
    required List<Expense> expenses,
    required List<dynamic> drivers, // List<Driver>
    required List<dynamic> trucks,  // List<Truck>
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final pdf = pw.Document();
    final accentColor = PdfColor.fromInt(company.invoiceAccentHex);
    const lightGray = PdfColor.fromInt(0xFFF8FAFC);
    const borderGray = PdfColor.fromInt(0xFFE2E8F0);
    const mutedText = PdfColor.fromInt(0xFF475569);
    const greenColor = PdfColor.fromInt(0xFF16A34A);
    const redColor = PdfColor.fromInt(0xFFDC2626);

    pw.MemoryImage? logoImage;
    if (company.logoUrl != null && company.logoUrl!.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(company.logoUrl!));
        if (response.statusCode == 200) {
          logoImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (_) {}
    }

    final currency = company.currency;

    // Filter by date range
    final filteredOrders = orders
        .where((o) =>
            o.status != OrderStatus.cancelled &&
            !o.tripDate.isBefore(fromDate) &&
            !o.tripDate.isAfter(toDate))
        .toList();

    final filteredExpenses = expenses
        .where((e) => !e.date.isBefore(fromDate) && !e.date.isAfter(toDate))
        .toList();

    final filteredInvoices = invoices
        .where((i) => !i.issueDate.isBefore(fromDate) && !i.issueDate.isAfter(toDate))
        .toList();

    // Revenue metrics
    final totalRevenue = filteredOrders.fold<double>(0, (s, o) => s + o.totalAmount);
    final totalCollected = filteredInvoices.fold<double>(0, (s, i) => s + i.amountPaid);
    final totalOutstanding = filteredInvoices.fold<double>(0, (s, i) => s + i.balanceDue);
    final totalExpenses = filteredExpenses.fold<double>(0, (s, e) => s + e.amount);
    final netProfit = totalCollected - totalExpenses;
    final totalKm = filteredOrders.fold<double>(0, (s, o) => s + o.chargeableKm);
    final completedTrips = filteredOrders
        .where((o) => o.status == OrderStatus.delivered || o.status == OrderStatus.paid)
        .length;

    // Top customers
    final custMap = <String, _CustAgg2>{};
    for (final o in filteredOrders) {
      final agg = custMap.putIfAbsent(o.customerId, () => _CustAgg2(name: o.customerName));
      agg.trips++;
      agg.revenue += o.totalAmount;
    }
    final topCustomers = custMap.values.toList()..sort((a, b) => b.revenue.compareTo(a.revenue));

    // Top routes
    final routeMap = <String, _RouteAgg2>{};
    for (final o in filteredOrders) {
      final agg = routeMap.putIfAbsent(o.routeName, () => _RouteAgg2(name: o.routeName));
      agg.trips++;
      agg.revenue += o.totalAmount;
    }
    final topRoutes = routeMap.values.toList()..sort((a, b) => b.revenue.compareTo(a.revenue));

    // Expenses by category
    final expByCat = <String, double>{};
    for (final e in filteredExpenses) {
      expByCat[e.category.label] = (expByCat[e.category.label] ?? 0) + e.amount;
    }
    final sortedExpCats = expByCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    // Driver performance
    final driverStats = (drivers as List).map((d) {
      final dOrders = filteredOrders.where((o) => o.driverId == d.id).toList();
      return _DriverAgg2(
        name: d.name as String,
        trips: dOrders.length,
        km: dOrders.fold(0.0, (s, o) => s + o.chargeableKm),
        revenue: dOrders.fold(0.0, (s, o) => s + o.totalAmount),
      );
    }).toList()
      ..sort((a, b) => b.trips.compareTo(a.trips));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.all(18),
            decoration: pw.BoxDecoration(
              color: accentColor,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (logoImage != null) ...[
                      pw.Container(
                        width: 48, height: 48,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                      ),
                      pw.SizedBox(width: 12),
                    ],
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          company.name.isEmpty ? 'TruckFlow Haulage' : company.name,
                          style: pw.TextStyle(color: PdfColors.white, fontSize: 16, fontWeight: pw.FontWeight.bold),
                        ),
                        if (company.address.isNotEmpty)
                          pw.Text(company.address, style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 8)),
                        pw.Text(
                          [company.phone, company.email].where((e) => e.isNotEmpty).join('  |  '),
                          style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 8),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('BUSINESS POSITION REPORT',
                        style: pw.TextStyle(color: PdfColors.amber, fontSize: 13, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('Period: ${AppFormatters.date(fromDate)} – ${AppFormatters.date(toDate)}',
                        style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 9)),
                    pw.Text('Generated: ${AppFormatters.date(DateTime.now())}',
                        style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 9)),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 16),

          // ── Executive Summary ──
          pw.Text('EXECUTIVE SUMMARY',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: accentColor)),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(color: lightGray, border: pw.Border.all(color: borderGray), borderRadius: pw.BorderRadius.circular(6)),
            child: pw.Row(
              children: [
                _summaryBox('Total Revenue', AppFormatters.currency(totalRevenue, code: currency), accentColor),
                pw.SizedBox(width: 10),
                _summaryBox('Collected', AppFormatters.currency(totalCollected, code: currency), greenColor),
                pw.SizedBox(width: 10),
                _summaryBox('Outstanding', AppFormatters.currency(totalOutstanding, code: currency), redColor),
                pw.SizedBox(width: 10),
                _summaryBox('Total Expenses', AppFormatters.currency(totalExpenses, code: currency), redColor),
                pw.SizedBox(width: 10),
                _summaryBox('Net Profit', AppFormatters.currency(netProfit, code: currency),
                    netProfit >= 0 ? greenColor : redColor),
              ],
            ),
          ),

          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(color: lightGray, border: pw.Border.all(color: borderGray), borderRadius: pw.BorderRadius.circular(6)),
            child: pw.Row(
              children: [
                _summaryBox('Total Trips', '$completedTrips completed', accentColor),
                pw.SizedBox(width: 10),
                _summaryBox('Total Km', AppFormatters.km(totalKm), accentColor),
                pw.SizedBox(width: 10),
                _summaryBox('Active Trucks', '${trucks.length}', accentColor),
                pw.SizedBox(width: 10),
                _summaryBox('Active Drivers', '${drivers.length}', accentColor),
              ],
            ),
          ),

          pw.SizedBox(height: 16),

          // ── Revenue vs Expenses ──
          pw.Text('FINANCIAL BREAKDOWN',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: accentColor)),
          pw.SizedBox(height: 8),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Expenses by category
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: borderGray), borderRadius: pw.BorderRadius.circular(6)),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Expenses by Category',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 8),
                      ...sortedExpCats.map((e) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 4),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(e.key, style: const pw.TextStyle(fontSize: 8.5)),
                            pw.Text(AppFormatters.currency(e.value, code: currency),
                                style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      )),
                      pw.Divider(color: borderGray),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('TOTAL', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                          pw.Text(AppFormatters.currency(totalExpenses, code: currency),
                              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: redColor)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              // Net position
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: borderGray), borderRadius: pw.BorderRadius.circular(6)),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Net Position',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 8),
                      _netRow('Total Collected', AppFormatters.currency(totalCollected, code: currency), greenColor),
                      _netRow('Less: Total Expenses', '- ${AppFormatters.currency(totalExpenses, code: currency)}', redColor),
                      pw.Divider(color: borderGray),
                      _netRow(
                        'NET PROFIT / (LOSS)',
                        AppFormatters.currency(netProfit, code: currency),
                        netProfit >= 0 ? greenColor : redColor,
                        bold: true,
                      ),
                      pw.SizedBox(height: 8),
                      if (totalRevenue > 0)
                        _netRow(
                          'Profit Margin',
                          '${(netProfit / totalRevenue * 100).toStringAsFixed(1)}%',
                          netProfit >= 0 ? greenColor : redColor,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 16),

          // ── Top Customers ──
          pw.Text('TOP CUSTOMERS BY REVENUE',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: accentColor)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8),
            headerDecoration: pw.BoxDecoration(color: accentColor),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            border: pw.TableBorder.all(color: borderGray, width: 0.5),
            headers: ['#', 'Customer', 'Trips', 'Revenue'],
            data: topCustomers.take(8).toList().asMap().entries.map((e) => [
              '${e.key + 1}',
              e.value.name,
              '${e.value.trips}',
              AppFormatters.currency(e.value.revenue, code: currency),
            ]).toList(),
          ),

          pw.SizedBox(height: 16),

          // ── Top Routes ──
          pw.Text('TOP ROUTES',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: accentColor)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8),
            headerDecoration: pw.BoxDecoration(color: accentColor),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            border: pw.TableBorder.all(color: borderGray, width: 0.5),
            headers: ['Route', 'Trips', 'Revenue'],
            data: topRoutes.take(8).map((r) => [
              r.name,
              '${r.trips}',
              AppFormatters.currency(r.revenue, code: currency),
            ]).toList(),
          ),

          if (driverStats.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text('DRIVER PERFORMANCE',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: accentColor)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8),
              headerDecoration: pw.BoxDecoration(color: accentColor),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              border: pw.TableBorder.all(color: borderGray, width: 0.5),
              headers: ['Driver', 'Trips', 'Km Driven', 'Revenue Generated'],
              data: driverStats.map((d) => [
                d.name,
                '${d.trips}',
                AppFormatters.km(d.km),
                AppFormatters.currency(d.revenue, code: currency),
              ]).toList(),
            ),
          ],

          pw.SizedBox(height: 20),
          pw.Center(
            child: pw.Text(
              company.invoiceFooter.isNotEmpty
                  ? company.invoiceFooter
                  : 'Confidential — For Internal Use / Shareholders Only',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 8, color: mutedText),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _stmtMetaRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(label, style: const pw.TextStyle(fontSize: 8.5, color: PdfColor.fromInt(0xFF475569))),
          ),
          pw.Text(value, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _summaryBox(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 7.5, color: PdfColor.fromInt(0xFF475569))),
          pw.SizedBox(height: 2),
          pw.Text(value, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  pw.Widget _netRow(String label, String value, PdfColor color, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 8.5, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _StatementRow {
  final DateTime date;
  final String ref;
  final String description;
  final double origAmt;
  final double unpaid;
  final bool isPayment;

  _StatementRow({
    required this.date,
    required this.ref,
    required this.description,
    required this.origAmt,
    required this.unpaid,
    required this.isPayment,
  });
}

class _CustAgg2 {
  final String name;
  int trips = 0;
  double revenue = 0;
  _CustAgg2({required this.name});
}

class _RouteAgg2 {
  final String name;
  int trips = 0;
  double revenue = 0;
  _RouteAgg2({required this.name});
}

class _DriverAgg2 {
  final String name;
  final int trips;
  final double km;
  final double revenue;
  _DriverAgg2({required this.name, required this.trips, required this.km, required this.revenue});
}

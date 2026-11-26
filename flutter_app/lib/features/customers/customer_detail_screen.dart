import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../core/models/invoice.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/status_chip.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  ConsumerState<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  bool _generatingStatement = false;

  // Default to current month
  DateTime _fromDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _toDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
    }
  }

  Future<void> _generateStatement() async {
    final company = ref.read(currentCompanyProvider).valueOrNull;
    final customers = ref.read(customersProvider).valueOrNull ?? [];
    final orders = ref.read(ordersProvider).valueOrNull ?? [];
    final invoices = ref.read(invoicesProvider).valueOrNull ?? [];

    final customer = customers.where((c) => c.id == widget.customerId).firstOrNull;
    if (company == null || customer == null) return;

    setState(() => _generatingStatement = true);
    try {
      final pdfService = ref.read(pdfInvoiceServiceProvider);
      final bytes = await pdfService.buildCustomerStatement(
        company: company,
        customer: customer,
        orders: orders,
        invoices: invoices,
        fromDate: _fromDate,
        toDate: _toDate,
      );

      // Share as PDF
      final dir = await getTemporaryDirectory();
      final name = '${customer.business.isNotEmpty ? customer.business : customer.name}'
          .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final file = File('${dir.path}/Statement_${name}_${AppFormatters.date(_fromDate).replaceAll('/', '-')}.pdf');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Account Statement — ${customer.business.isNotEmpty ? customer.business : customer.name}',
        text: 'Please find attached your account statement for ${AppFormatters.date(_fromDate)} – ${AppFormatters.date(_toDate)}.',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate statement: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingStatement = false);
    }
  }

  Future<void> _previewStatement() async {
    final company = ref.read(currentCompanyProvider).valueOrNull;
    final customers = ref.read(customersProvider).valueOrNull ?? [];
    final orders = ref.read(ordersProvider).valueOrNull ?? [];
    final invoices = ref.read(invoicesProvider).valueOrNull ?? [];

    final customer = customers.where((c) => c.id == widget.customerId).firstOrNull;
    if (company == null || customer == null) return;

    setState(() => _generatingStatement = true);
    try {
      final pdfService = ref.read(pdfInvoiceServiceProvider);
      final bytes = await pdfService.buildCustomerStatement(
        company: company,
        customer: customer,
        orders: orders,
        invoices: invoices,
        fromDate: _fromDate,
        toDate: _toDate,
      );

      if (mounted) {
        await Printing.layoutPdf(onLayout: (_) => bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to preview: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingStatement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersProvider).valueOrNull ?? [];
    final orders = ref.watch(ordersProvider).valueOrNull ?? [];
    final invoices = ref.watch(invoicesProvider).valueOrNull ?? [];
    final currency = ref.watch(currentCompanyProvider).valueOrNull?.currency ?? 'USD';

    final customer = customers.where((c) => c.id == widget.customerId).firstOrNull;
    if (customer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer')),
        body: const Center(child: Text('Customer not found')),
      );
    }

    final custOrders = orders.where((o) => o.customerId == customer.id).toList();
    final totalSpent = custOrders.fold<double>(0, (s, o) => s + o.totalAmount);
    final outstanding = invoices
        .where((i) => i.customerId == customer.id && i.paymentStatus != PaymentStatus.paid)
        .fold<double>(0, (s, i) => s + i.balanceDue);

    return Scaffold(
      appBar: AppBar(
        title: Text(customer.business.isNotEmpty ? customer.business : customer.name),
        actions: [
          IconButton(
            tooltip: 'Call',
            icon: const Icon(Icons.phone_outlined),
            onPressed: () => launchUrl(Uri(scheme: 'tel', path: customer.phone)),
          ),
          IconButton(
            tooltip: 'WhatsApp',
            icon: const Icon(Icons.chat_outlined, color: AppColors.profit),
            onPressed: () {
              final clean = customer.phone.replaceAll(RegExp(r'[^0-9]'), '');
              launchUrl(Uri.parse('https://wa.me/$clean'), mode: LaunchMode.externalApplication);
            },
          ),
          IconButton(
            tooltip: 'Generate Statement',
            icon: _generatingStatement
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.description_outlined),
            onPressed: _generatingStatement ? null : () => _showStatementBottomSheet(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  if (customer.phone.isNotEmpty) Text(customer.phone),
                  if (customer.email.isNotEmpty) Text(customer.email),
                  if (customer.address.isNotEmpty) Text(customer.address),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Total Spent',
                  value: AppFormatters.currency(totalSpent, code: currency),
                  subtitle: '${custOrders.length} orders',
                  icon: Icons.payments_outlined,
                  accentColor: AppColors.profit,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  label: 'Outstanding',
                  value: AppFormatters.currency(outstanding, code: currency),
                  subtitle: outstanding > 0 ? 'Unpaid invoices' : 'Settled',
                  icon: Icons.account_balance_outlined,
                  accentColor: outstanding > 0 ? AppColors.loss : AppColors.profit,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Order History',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...custOrders.map(
            (order) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  onTap: () => context.push('/orders/${order.id}'),
                  title: Text(order.routeName,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${AppFormatters.date(order.tripDate)} • ${order.cargoDescription}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(AppFormatters.currency(order.totalAmount, code: currency),
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      StatusChip.order(order.status),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStatementBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.description_outlined),
                const SizedBox(width: 10),
                Text('Generate Statement', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 16),
              const Text('Date Range', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2023),
                    lastDate: DateTime(2030),
                    initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
                  );
                  if (picked != null) {
                    setState(() { _fromDate = picked.start; _toDate = picked.end; });
                    setSheetState(() {});
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.date_range_outlined, size: 20),
                      const SizedBox(width: 10),
                      Text('${AppFormatters.date(_fromDate)}  →  ${AppFormatters.date(_toDate)}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Quick presets
              Wrap(
                spacing: 8,
                children: [
                  _presetChip('This Month', ctx, setSheetState, () {
                    final now = DateTime.now();
                    setState(() { _fromDate = DateTime(now.year, now.month, 1); _toDate = DateTime(now.year, now.month + 1, 0); });
                  }),
                  _presetChip('Last Month', ctx, setSheetState, () {
                    final now = DateTime.now();
                    setState(() { _fromDate = DateTime(now.year, now.month - 1, 1); _toDate = DateTime(now.year, now.month, 0); });
                  }),
                  _presetChip('This Year', ctx, setSheetState, () {
                    final now = DateTime.now();
                    setState(() { _fromDate = DateTime(now.year, 1, 1); _toDate = DateTime(now.year, 12, 31); });
                  }),
                ],
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () { Navigator.pop(ctx); _previewStatement(); },
                    icon: const Icon(Icons.preview_outlined),
                    label: const Text('Preview'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () { Navigator.pop(ctx); _generateStatement(); },
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share PDF'),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _presetChip(String label, BuildContext ctx, StateSetter setSheetState, VoidCallback onSelect) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: () { onSelect(); setSheetState(() {}); },
    );
  }
}

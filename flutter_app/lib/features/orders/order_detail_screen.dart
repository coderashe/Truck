import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/order.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/status_chip.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _isGeneratingInvoice = false;

  Future<void> _generateOrOpenInvoice(HaulageOrder order) async {
    if (order.invoiceId != null && order.invoiceId!.isNotEmpty) {
      context.push('/invoice/${order.invoiceId}');
      return;
    }

    setState(() => _isGeneratingInvoice = true);
    try {
      final invoice = await ref
          .read(firestoreServiceProvider)
          .createInvoiceForOrder(order: order);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invoice ${invoice.invoiceNumber} created')),
        );
        context.push('/invoice/${invoice.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not generate invoice: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingInvoice = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider).valueOrNull ?? [];
    final trucks = ref.watch(trucksProvider).valueOrNull ?? [];
    final drivers = ref.watch(driversProvider).valueOrNull ?? [];
    final company = ref.watch(currentCompanyProvider).valueOrNull;
    final currency = company?.currency ?? 'USD';

    final order = orders.where((o) => o.id == widget.orderId).firstOrNull;
    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: const Center(child: Text('Order not found')),
      );
    }

    final truck = trucks.where((t) => t.id == order.truckId).firstOrNull;
    final driver = drivers.where((d) => d.id == order.driverId).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(order.routeName),
        actions: [
          PopupMenuButton<OrderStatus>(
            tooltip: 'Change Status',
            onSelected: (status) async {
              await ref
                  .read(firestoreServiceProvider)
                  .updateOrderStatus(order.id, status);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Status updated to ${status.label}')),
                );
              }
            },
            itemBuilder: (_) => OrderStatus.values
                .map(
                  (s) => PopupMenuItem(
                    value: s,
                    child: Text('Mark as ${s.label}'),
                  ),
                )
                .toList(),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StatusChip.order(order.status),
                      Text(
                        AppFormatters.date(order.tripDate),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    order.customerName,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text('Booked via ${order.source.label}'),
                  const Divider(height: 24),
                  _InfoRow(label: 'Pickup', value: order.pickup.address),
                  _InfoRow(label: 'Drop-off', value: order.dropoff.address),
                  _InfoRow(
                    label: 'Cargo',
                    value:
                        '${order.cargoDescription} (${order.cargoWeight.toStringAsFixed(1)}t)',
                  ),
                  if (truck != null)
                    _InfoRow(
                      label: 'Truck',
                      value: '${truck.regNumber} • ${truck.makeModel}',
                    ),
                  if (driver != null)
                    _InfoRow(label: 'Driver', value: driver.name),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pricing Breakdown',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: 'One-Way Distance',
                    value: AppFormatters.km(order.distanceKm),
                  ),
                  _InfoRow(
                    label: 'Round-Trip Applied',
                    value: order.roundTrip ? 'Yes (× 2)' : 'No (One-way)',
                  ),
                  _InfoRow(
                    label: 'Chargeable Distance',
                    value: AppFormatters.km(order.chargeableKm),
                  ),
                  _InfoRow(
                    label: 'Rate per km',
                    value: AppFormatters.currency(order.ratePerKm, code: currency),
                  ),
                  if (order.extras > 0)
                    _InfoRow(
                      label: 'Extras',
                      value: AppFormatters.currency(order.extras, code: currency),
                    ),
                  if (order.discount > 0)
                    _InfoRow(
                      label: 'Discount',
                      value:
                          '-${AppFormatters.currency(order.discount, code: currency)}',
                    ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        AppFormatters.currency(order.totalAmount, code: currency),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _isGeneratingInvoice
                ? null
                : () => _generateOrOpenInvoice(order),
            icon: _isGeneratingInvoice
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
            label: Text(
              order.invoiceId != null
                  ? 'View / Share Invoice PDF'
                  : 'Generate Invoice',
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

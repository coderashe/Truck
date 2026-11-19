import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/invoice.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/status_chip.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = ref.watch(customersProvider).valueOrNull ?? [];
    final orders = ref.watch(ordersProvider).valueOrNull ?? [];
    final invoices = ref.watch(invoicesProvider).valueOrNull ?? [];
    final currency = ref.watch(currentCompanyProvider).valueOrNull?.currency ?? 'USD';

    final customer = customers.where((c) => c.id == customerId).firstOrNull;
    if (customer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer')),
        body: const Center(child: Text('Customer not found')),
      );
    }

    final custOrders = orders.where((o) => o.customerId == customer.id).toList();
    final totalSpent = custOrders.fold<double>(0, (s, o) => s + o.totalAmount);
    final outstanding = invoices
        .where((i) =>
            i.customerId == customer.id &&
            i.paymentStatus != PaymentStatus.paid)
        .fold<double>(0, (s, i) => s + i.balanceDue);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          customer.business.isNotEmpty ? customer.business : customer.name,
        ),
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
              launchUrl(
                Uri.parse('https://wa.me/$clean'),
                mode: LaunchMode.externalApplication,
              );
            },
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
                  Text(
                    customer.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
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
          Text(
            'Order History',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          ...custOrders.map(
            (order) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  onTap: () => context.push('/orders/${order.id}'),
                  title: Text(
                    order.routeName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${AppFormatters.date(order.tripDate)} • ${order.cargoDescription}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppFormatters.currency(order.totalAmount, code: currency),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
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
}

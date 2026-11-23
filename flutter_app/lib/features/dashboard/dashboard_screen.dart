import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/invoice.dart';
import '../../core/models/order.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/loading_shimmer.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/status_chip.dart';

import '../../core/extensions/color_extensions.dart';
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final company = ref.watch(currentCompanyProvider).valueOrNull;
    final user = ref.watch(currentUserProfileProvider).valueOrNull;
    final ordersAsync = ref.watch(ordersProvider);
    final invoicesAsync = ref.watch(invoicesProvider);
    final expensesAsync = ref.watch(expensesProvider);

    final currency = company?.currency ?? 'USD';
    final isOwner = user?.isOwner ?? true;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(company?.name.isNotEmpty == true ? company!.name : 'TruckFlow'),
            Text(
              'Operations Overview',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'New Order',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => context.push('/orders/new'),
          ),
        ],
      ),
      body: ordersAsync.when(
        loading: () => const LoadingShimmer(),
        error: (e, _) => Center(child: Text('Error loading dashboard: $e')),
        data: (orders) {
          final invoices = invoicesAsync.valueOrNull ?? [];
          final expenses = expensesAsync.valueOrNull ?? [];

          final now = DateTime.now();
          final monthStart = DateTime(now.year, now.month, 1);

          final activeTrips = orders
              .where((o) =>
                  o.status == OrderStatus.confirmed ||
                  o.status == OrderStatus.inTransit)
              .length;
          final pendingOrders =
              orders.where((o) => o.status == OrderStatus.pending || o.status == OrderStatus.requested).length;
          final unpaidInvoices = invoices
              .where((inv) => inv.paymentStatus != PaymentStatus.paid)
              .toList();
          final unpaidTotal = unpaidInvoices.fold<double>(
            0,
            (sum, inv) => sum + inv.balanceDue,
          );

          final monthRevenue = invoices
              .where((inv) =>
                  inv.paymentStatus == PaymentStatus.paid &&
                  !inv.issueDate.isBefore(monthStart))
              .fold<double>(0, (sum, inv) => sum + inv.amountPaid);

          final monthExpenses = expenses
              .where((e) => !e.date.isBefore(monthStart))
              .fold<double>(0, (sum, e) => sum + e.amount);

          final monthProfit = monthRevenue - monthExpenses;
          final recentOrders = orders.take(6).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(ordersProvider);
              ref.invalidate(invoicesProvider);
              ref.invalidate(expensesProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  "Today's Snapshot",
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Active Trips',
                        value: '$activeTrips',
                        subtitle: 'Confirmed & in transit',
                        icon: Icons.local_shipping_outlined,
                        accentColor: AppColors.info,
                        onTap: () => context.go('/orders'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatCard(
                        label: 'Pending Orders',
                        value: '$pendingOrders',
                        subtitle: 'Awaiting dispatch',
                        icon: Icons.pending_actions_outlined,
                        accentColor: AppColors.warning,
                        onTap: () => context.go('/orders'),
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 250.ms),
                const SizedBox(height: 10),
                StatCard(
                  label: 'Unpaid Invoices',
                  value: AppFormatters.currency(unpaidTotal, code: currency),
                  subtitle: '${unpaidInvoices.length} open receivables',
                  icon: Icons.receipt_long_outlined,
                  accentColor: AppColors.loss,
                  onTap: () => context.go('/orders'),
                ).animate().fadeIn(delay: 60.ms, duration: 250.ms),

                if (isOwner) ...[
                  const SizedBox(height: 22),
                  Text(
                    'This Month',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Revenue (Paid)',
                          value: AppFormatters.compactCurrency(
                            monthRevenue,
                            code: currency,
                          ),
                          icon: Icons.trending_up,
                          accentColor: AppColors.profit,
                          onTap: () => context.push('/more/expenses'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatCard(
                          label: 'Expenses',
                          value: AppFormatters.compactCurrency(
                            monthExpenses,
                            code: currency,
                          ),
                          icon: Icons.trending_down,
                          accentColor: AppColors.loss,
                          onTap: () => context.push('/more/expenses'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  StatCard(
                    label: 'Net Profit (This Month)',
                    value: AppFormatters.currency(monthProfit, code: currency),
                    subtitle: monthProfit >= 0 ? 'Positive margin' : 'Operating deficit',
                    icon: Icons.account_balance_wallet_outlined,
                    accentColor:
                        monthProfit >= 0 ? AppColors.profit : AppColors.loss,
                    onTap: () => context.push('/more/expenses'),
                  ),
                ],

                const SizedBox(height: 22),
                Text(
                  'Quick Actions',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => context.push('/orders/new'),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('New Order'),
                      ),
                    ),
                    if (isOwner) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/more/expenses'),
                          icon: const Icon(Icons.receipt_outlined, size: 18),
                          label: const Text('Add Expense'),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Orders',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    TextButton(
                      onPressed: () => context.go('/orders'),
                      child: const Text('View all'),
                    ),
                  ],
                ),
                if (recentOrders.isEmpty)
                  EmptyState(
                    icon: Icons.local_shipping_outlined,
                    title: 'No trips recorded yet',
                    message:
                        'Create your first haulage order or load sample data from Settings.',
                    actionLabel: 'Create Order',
                    onAction: () => context.push('/orders/new'),
                  )
                else
                  ...recentOrders.map(
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
                            '${order.customerName} • ${AppFormatters.shortDate(order.tripDate)} • ${AppFormatters.km(order.chargeableKm)}',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                AppFormatters.currency(
                                  order.totalAmount,
                                  code: currency,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
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
        },
      ),
    );
  }
}
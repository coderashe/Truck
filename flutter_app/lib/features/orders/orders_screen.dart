import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/order.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/loading_shimmer.dart';
import '../../shared/widgets/status_chip.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String _search = '';
  OrderStatus? _statusFilter;
  String? _truckFilter;

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersProvider);
    final trucks = ref.watch(trucksProvider).valueOrNull ?? [];
    final company = ref.watch(currentCompanyProvider).valueOrNull;
    final currency = company?.currency ?? 'USD';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          if (trucks.isNotEmpty)
            PopupMenuButton<String?>(
              icon: Icon(
                Icons.local_shipping_outlined,
                color: _truckFilter != null
                    ? Theme.of(context).colorScheme.secondary
                    : null,
              ),
              tooltip: 'Filter by Truck',
              onSelected: (val) => setState(() => _truckFilter = val),
              itemBuilder: (context) => [
                const PopupMenuItem(value: null, child: Text('All Trucks')),
                ...trucks.map(
                  (t) => PopupMenuItem(
                    value: t.id,
                    child: Text('${t.regNumber} (${t.makeModel})'),
                  ),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/orders/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Order'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search customer, route, or cargo...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('All'),
                    selected: _statusFilter == null,
                    onSelected: (_) => setState(() => _statusFilter = null),
                  ),
                ),
                ...OrderStatus.values.map(
                  (status) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(status.label),
                      selected: _statusFilter == status,
                      onSelected: (_) => setState(
                        () => _statusFilter =
                            _statusFilter == status ? null : status,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ordersAsync.when(
              loading: () => const LoadingShimmer(),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (orders) {
                final filtered = orders.where((o) {
                  if (_statusFilter != null && o.status != _statusFilter) {
                    return false;
                  }
                  if (_truckFilter != null && o.truckId != _truckFilter) {
                    return false;
                  }
                  if (_search.isNotEmpty) {
                    final haystack =
                        '${o.customerName} ${o.routeName} ${o.cargoDescription}'
                            .toLowerCase();
                    if (!haystack.contains(_search)) return false;
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No matching orders',
                    message:
                        'Adjust your search/filters or record a new haulage order.',
                    actionLabel: 'Create Order',
                    onAction: () => context.push('/orders/new'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(ordersProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 88),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final order = filtered[index];
                      return Card(
                        child: InkWell(
                          onTap: () => context.push('/orders/${order.id}'),
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        order.routeName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    StatusChip.order(order.status),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${order.customerName} • ${order.source.label}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${order.cargoDescription} (${order.cargoWeight.toStringAsFixed(1)}t) • ${AppFormatters.date(order.tripDate)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                ),
                                const Divider(height: 18),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${AppFormatters.km(order.chargeableKm)} ${order.roundTrip ? '(Round-trip)' : '(One-way)'}',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                    Text(
                                      AppFormatters.currency(
                                        order.totalAmount,
                                        code: currency,
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        fontFeatures: [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

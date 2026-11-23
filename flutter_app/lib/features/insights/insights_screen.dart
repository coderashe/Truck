import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/models/order.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/loading_shimmer.dart';

import '../../core/extensions/color_extensions.dart';
enum HeatmapLayerMode {
  both('Both'),
  pickups('Pickups'),
  dropoffs('Drop-offs');

  final String label;
  const HeatmapLayerMode(this.label);
}

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  HeatmapLayerMode _heatmapMode = HeatmapLayerMode.both;
  int _daysFilter = 180;

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersProvider);
    final expenses = ref.watch(expensesProvider).valueOrNull ?? [];
    final trucks = ref.watch(trucksProvider).valueOrNull ?? [];
    final company = ref.watch(currentCompanyProvider).valueOrNull;
    final currency = company?.currency ?? 'USD';

    return Scaffold(
      appBar: AppBar(title: const Text('Business Intelligence')),
      body: ordersAsync.when(
        loading: () => const LoadingShimmer(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (allOrders) {
          final cutoff = DateTime.now().subtract(Duration(days: _daysFilter));
          final orders = allOrders
              .where((o) =>
                  o.status != OrderStatus.cancelled &&
                  !o.tripDate.isBefore(cutoff))
              .toList();

          if (orders.isEmpty) {
            return const EmptyState(
              icon: Icons.insights_outlined,
              title: 'No trip data for insights yet',
              message:
                  'Record haulage orders or run the sample seeder in Settings to unlock route analytics and heatmaps.',
            );
          }

          // 1. Recurring customers
          final custMap = <String, _CustomerAgg>{};
          for (final o in orders) {
            final agg = custMap.putIfAbsent(
              o.customerId,
              () => _CustomerAgg(name: o.customerName),
            );
            agg.orders += 1;
            agg.revenue += o.totalAmount;
          }
          final topCustomers = custMap.values.toList()
            ..sort((a, b) => b.revenue.compareTo(a.revenue));

          // 2. Most profitable routes
          final totalKmAll =
              orders.fold<double>(0, (s, o) => s + o.chargeableKm);
          final totalExpAll = expenses
              .where((e) => !e.date.isBefore(cutoff))
              .fold<double>(0, (s, e) => s + e.amount);
          final avgCostPerKm = totalKmAll > 0 ? totalExpAll / totalKmAll : 0.75;

          final routeMap = <String, _RouteAgg>{};
          for (final o in orders) {
            final agg = routeMap.putIfAbsent(
              o.routeName,
              () => _RouteAgg(
                routeName: o.routeName,
                pickup: o.pickup,
                dropoff: o.dropoff,
              ),
            );
            agg.trips += 1;
            agg.revenue += o.totalAmount;
            agg.estimatedCost += o.chargeableKm * avgCostPerKm;
          }
          final topRoutes = routeMap.values.toList()
            ..sort((a, b) => b.profit.compareTo(a.profit));

          // 3. Peak days of month (1-31) & day of week (1-7)
          final dayOfMonthCounts = List<int>.filled(32, 0);
          final dayOfWeekCounts = List<int>.filled(8, 0);
          for (final o in orders) {
            dayOfMonthCounts[o.tripDate.day]++;
            dayOfWeekCounts[o.tripDate.weekday]++;
          }

          int peakDom = 1;
          for (int d = 2; d <= 31; d++) {
            if (dayOfMonthCounts[d] > dayOfMonthCounts[peakDom]) peakDom = d;
          }

          // 4. Top performing trucks
          final truckStats = trucks.map((truck) {
            final tOrders = orders.where((o) => o.truckId == truck.id).toList();
            final rev = tOrders.fold<double>(0, (s, o) => s + o.totalAmount);
            final km = tOrders.fold<double>(0, (s, o) => s + o.chargeableKm);
            final exp = expenses
                .where((e) => e.truckId == truck.id && !e.date.isBefore(cutoff))
                .fold<double>(0, (s, e) => s + e.amount);
            return _TruckAgg(
              regNumber: truck.regNumber,
              makeModel: truck.makeModel,
              trips: tOrders.length,
              km: km,
              revenue: rev,
              expenses: exp,
            );
          }).toList()
            ..sort((a, b) => b.netProfit.compareTo(a.netProfit));

          // 5. Heatmap points & tappable route polylines
          final heatPoints = <WeightedLatLng>[];
          for (final o in orders) {
            if (_heatmapMode == HeatmapLayerMode.pickups ||
                _heatmapMode == HeatmapLayerMode.both) {
              if (o.pickup.lat != 0) {
                heatPoints.add(
                  WeightedLatLng(LatLng(o.pickup.lat, o.pickup.lng)),
                );
              }
            }
            if (_heatmapMode == HeatmapLayerMode.dropoffs ||
                _heatmapMode == HeatmapLayerMode.both) {
              if (o.dropoff.lat != 0) {
                heatPoints.add(
                  WeightedLatLng(LatLng(o.dropoff.lat, o.dropoff.lng)),
                );
              }
            }
          }

          final polylines = topRoutes.take(8).map((r) {
            return Polyline(
              polylineId: PolylineId(r.routeName),
              points: [
                LatLng(r.pickup.lat, r.pickup.lng),
                LatLng(r.dropoff.lat, r.dropoff.lng),
              ],
              color: AppColors.accentDark,
              width: 4,
              consumeTapEvents: true,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) => Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.routeName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Trips completed: ${r.trips}'),
                        Text(
                          'Revenue: ${AppFormatters.currency(r.revenue, code: currency)}',
                        ),
                        Text(
                          'Est. Profit: ${AppFormatters.currency(r.profit, code: currency)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.profit,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }).toSet();

          final bestRoute = topRoutes.isNotEmpty ? topRoutes.first : null;
          final topCustomer = topCustomers.isNotEmpty ? topCustomers.first : null;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Date range filter
              Row(
                children: [
                  const Text('Window: ',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  ...[
                    (30, '30 Days'),
                    (90, '90 Days'),
                    (180, '6 Months'),
                  ].map((opt) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(opt.$2),
                        selected: _daysFilter == opt.$1,
                        onSelected: (_) => setState(() => _daysFilter = opt.$1),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 14),

              // Locally computed Insight Cards
              if (bestRoute != null)
                _InsightBanner(
                  icon: Icons.auto_graph,
                  text:
                      'Route ${bestRoute.routeName} is your most profitable corridor (${AppFormatters.currency(bestRoute.profit, code: currency)} est. profit across ${bestRoute.trips} trips).',
                ),
              const SizedBox(height: 8),
              _InsightBanner(
                icon: Icons.calendar_month,
                text:
                    'Your busiest dispatch day is day $peakDom of the month (${dayOfMonthCounts[peakDom]} trips booked).',
              ),
              if (topCustomer != null) ...[
                const SizedBox(height: 8),
                _InsightBanner(
                  icon: Icons.workspace_premium_outlined,
                  text:
                      '${topCustomer.name} leads revenue with ${topCustomer.orders} orders (${AppFormatters.currency(topCustomer.revenue, code: currency)}).',
                ),
              ],

              const SizedBox(height: 20),
              // Route Heatmap Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pickup & Drop-off Heatmap',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  SegmentedButton<HeatmapLayerMode>(
                    segments: HeatmapLayerMode.values
                        .map(
                          (m) => ButtonSegment(
                            value: m,
                            label: Text(m.label, style: const TextStyle(fontSize: 11)),
                          ),
                        )
                        .toList(),
                    selected: {_heatmapMode},
                    onSelectionChanged: (s) =>
                        setState(() => _heatmapMode = s.first),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 250,
                  child: GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(-19.0154, 29.1549), // Zimbabwe center
                      zoom: 5.8,
                    ),
                    heatmaps: heatPoints.isNotEmpty
                        ? {
                            Heatmap(
                              heatmapId: const HeatmapId('orders_heatmap'),
                              data: heatPoints,
                              radius: const HeatmapRadius.fromPixels(35),
                            ),
                          }
                        : {},
                    polylines: polylines,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: true,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap any route line on the map to inspect corridor revenue and profit.',
                style: Theme.of(context).textTheme.bodySmall,
              ),

              const SizedBox(height: 22),
              const Text(
                'Most Profitable Routes',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 10),
              ...topRoutes.take(5).map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        child: ListTile(
                          title: Text(
                            r.routeName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${r.trips} trips • Revenue ${AppFormatters.compactCurrency(r.revenue, code: currency)}',
                          ),
                          trailing: Text(
                            AppFormatters.currency(r.profit, code: currency),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.profit,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

              const SizedBox(height: 20),
              const Text(
                'Peak Order Days (Day of Month)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: SizedBox(
                    height: 150,
                    child: BarChart(
                      BarChartData(
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 5,
                              getTitlesWidget: (v, _) => Text(
                                '${v.toInt()}',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                        ),
                        barGroups: List.generate(31, (i) {
                          final day = i + 1;
                          return BarChartGroupData(
                            x: day,
                            barRods: [
                              BarChartRodData(
                                toY: dayOfMonthCounts[day].toDouble(),
                                color: day >= 25
                                    ? AppColors.accent
                                    : AppColors.primary,
                                width: 5,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                'Recurring Customers',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 10),
              ...topCustomers.take(6).map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        child: ListTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  c.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              if (c.orders >= 3)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Loyal',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.accentDark,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text('${c.orders} orders'),
                          trailing: Text(
                            AppFormatters.currency(c.revenue, code: currency),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ),

              const SizedBox(height: 20),
              const Text(
                'Top Performing Trucks',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 10),
              ...truckStats.map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: ListTile(
                      title: Text(
                        '${t.regNumber} • ${t.makeModel}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${t.trips} trips • ${AppFormatters.km(t.km)} • Exp ${AppFormatters.compactCurrency(t.expenses, code: currency)}',
                      ),
                      trailing: Text(
                        AppFormatters.currency(t.netProfit, code: currency),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: t.netProfit >= 0
                              ? AppColors.profit
                              : AppColors.loss,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InsightBanner extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InsightBanner({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accentDark, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerAgg {
  final String name;
  int orders = 0;
  double revenue = 0;
  _CustomerAgg({required this.name});
}

class _RouteAgg {
  final String routeName;
  final GeoPointLocation pickup;
  final GeoPointLocation dropoff;
  int trips = 0;
  double revenue = 0;
  double estimatedCost = 0;
  double get profit => revenue - estimatedCost;

  _RouteAgg({
    required this.routeName,
    required this.pickup,
    required this.dropoff,
  });
}

class _TruckAgg {
  final String regNumber;
  final String makeModel;
  final int trips;
  final double km;
  final double revenue;
  final double expenses;
  double get netProfit => revenue - expenses;

  const _TruckAgg({
    required this.regNumber,
    required this.makeModel,
    required this.trips,
    required this.km,
    required this.revenue,
    required this.expenses,
  });
}
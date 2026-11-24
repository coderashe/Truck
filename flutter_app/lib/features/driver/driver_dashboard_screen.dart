import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/order.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

enum LeaderboardMetric { trips, distance, revenue }

class DriverDashboardScreen extends ConsumerStatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  ConsumerState<DriverDashboardScreen> createState() =>
      _DriverDashboardScreenState();
}

class _DriverDashboardScreenState
    extends ConsumerState<DriverDashboardScreen> {
  LeaderboardMetric _metric = LeaderboardMetric.trips;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProfileProvider).valueOrNull;
    final allOrders = ref.watch(ordersProvider).valueOrNull ?? [];
    final drivers = ref.watch(driversProvider).valueOrNull ?? [];
    final company = ref.watch(currentCompanyProvider).valueOrNull;
    final currency = company?.currency ?? 'USD';

    final driverId = user?.driverId ?? '';
    final myOrders =
        allOrders.where((o) => o.driverId == driverId).toList();
    final completedOrders = myOrders
        .where((o) =>
            o.status == OrderStatus.delivered ||
            o.status == OrderStatus.paid)
        .toList();

    final myTrips = completedOrders.length;
    final myKm = completedOrders.fold<double>(
        0, (s, o) => s + o.chargeableKm);
    final myRevenue = completedOrders.fold<double>(
        0, (s, o) => s + o.totalAmount);

    // Leaderboard data
    final leaderboard = drivers.map((d) {
      final dOrders = allOrders
          .where((o) =>
              o.driverId == d.id &&
              (o.status == OrderStatus.delivered ||
                  o.status == OrderStatus.paid))
          .toList();
      return _DriverStats(
        driverId: d.id,
        name: d.name,
        trips: dOrders.length,
        km: dOrders.fold(0.0, (s, o) => s + o.chargeableKm),
        revenue: dOrders.fold(0.0, (s, o) => s + o.totalAmount),
      );
    }).toList();

    leaderboard.sort((a, b) {
      switch (_metric) {
        case LeaderboardMetric.trips:
          return b.trips.compareTo(a.trips);
        case LeaderboardMetric.distance:
          return b.km.compareTo(a.km);
        case LeaderboardMetric.revenue:
          return b.revenue.compareTo(a.revenue);
      }
    });

    final myRankIndex =
        leaderboard.indexWhere((d) => d.driverId == driverId);
    final myRank = myRankIndex >= 0 ? myRankIndex + 1 : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Hi, ${user?.name.split(' ').first ?? 'Driver'} 👋'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // My stats
          Text(
            'My Performance',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: _StatCard(
                  label: 'Trips',
                  value: '$myTrips',
                  icon: Icons.route,
                  color: Colors.blue),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                  label: 'Km Driven',
                  value: AppFormatters.km(myKm),
                  icon: Icons.speed,
                  color: Colors.orange),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                  label: 'Revenue',
                  value: AppFormatters.currency(myRevenue,
                      code: currency),
                  icon: Icons.attach_money,
                  color: Colors.green),
            ),
          ]),

          const SizedBox(height: 20),

          // My recent trips
          Text(
            'My Trips',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (myOrders.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('No trips assigned yet.',
                    style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ...myOrders.take(10).map((o) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          _statusColor(o.status).withOpacity(0.15),
                      child: Icon(_statusIcon(o.status),
                          size: 16, color: _statusColor(o.status)),
                    ),
                    title: Text(
                      o.routeName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                    subtitle:
                        Text(AppFormatters.date(o.tripDate)),
                    trailing: Text(
                      AppFormatters.currency(o.totalAmount,
                          code: currency),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ),
                  ),
                )),

          const SizedBox(height: 20),

          // Leaderboard
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Driver Leaderboard',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (myRank > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'You: #$myRank',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: AppColors.accentDark),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Metric filter
          SegmentedButton<LeaderboardMetric>(
            segments: const [
              ButtonSegment(
                  value: LeaderboardMetric.trips,
                  label: Text('Trips')),
              ButtonSegment(
                  value: LeaderboardMetric.distance,
                  label: Text('Km')),
              ButtonSegment(
                  value: LeaderboardMetric.revenue,
                  label: Text('Revenue')),
            ],
            selected: {_metric},
            onSelectionChanged: (s) =>
                setState(() => _metric = s.first),
          ),
          const SizedBox(height: 12),
          ...leaderboard.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final d = entry.value;
            final isMe = d.driverId == driverId;
            final medal = rank == 1
                ? '🥇'
                : rank == 2
                    ? '🥈'
                    : rank == 3
                        ? '🥉'
                        : '#$rank';
            final metricValue =
                _metric == LeaderboardMetric.trips
                    ? '${d.trips} trips'
                    : _metric == LeaderboardMetric.distance
                        ? AppFormatters.km(d.km)
                        : AppFormatters.currency(d.revenue,
                            code: currency);

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: isMe
                  ? AppColors.primary.withOpacity(0.08)
                  : null,
              shape: isMe
                  ? RoundedRectangleBorder(
                      side: const BorderSide(
                          color: AppColors.accent, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    )
                  : null,
              child: ListTile(
                dense: true,
                leading: Text(medal,
                    style: const TextStyle(fontSize: 20)),
                title: Text(
                  d.name,
                  style: TextStyle(
                      fontWeight: isMe
                          ? FontWeight.w700
                          : FontWeight.normal),
                ),
                trailing: Text(
                  metricValue,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.inTransit:
        return Colors.blue;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.paid:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
        return Icons.schedule;
      case OrderStatus.inTransit:
        return Icons.local_shipping;
      case OrderStatus.delivered:
        return Icons.check_circle_outline;
      case OrderStatus.paid:
        return Icons.payment;
      default:
        return Icons.info_outline;
    }
  }
}

class _DriverStats {
  final String driverId;
  final String name;
  final int trips;
  final double km;
  final double revenue;

  _DriverStats({
    required this.driverId,
    required this.name,
    required this.trips,
    required this.km,
    required this.revenue,
  });
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: color),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

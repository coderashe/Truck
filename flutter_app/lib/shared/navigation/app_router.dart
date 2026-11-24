import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/app_user.dart';
import '../../core/providers/app_providers.dart';
import '../../features/auth/login_screen.dart';
import '../../features/customers/customer_detail_screen.dart';
import '../../features/customers/customers_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/driver/driver_dashboard_screen.dart';
import '../../features/expenses/expenses_screen.dart';
import '../../features/fleet/fleet_screen.dart';
import '../../features/insights/insights_screen.dart';
import '../../features/invoices/invoice_preview_screen.dart';
import '../../features/orders/order_detail_screen.dart';
import '../../features/orders/order_form_screen.dart';
import '../../features/orders/orders_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/team_screen.dart';
import '../../features/setup/company_gate_screen.dart';
import '../../features/setup/join_company_screen.dart';
import '../../features/setup/setup_wizard_screen.dart';
import 'scaffold_with_nav.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final userState = ref.watch(currentUserProfileProvider);
  final companyState = ref.watch(currentCompanyProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isLoading = authState.isLoading || userState.isLoading;
      if (isLoading) return null;

      final user = authState.valueOrNull;
      final appUser = userState.valueOrNull;
      final company = companyState.valueOrNull;
      final loc = state.matchedLocation;

      // Not logged in
      if (user == null) return loc == '/login' ? null : '/login';

      // Logged in but no company yet
      if (appUser != null && appUser.companyId.isEmpty) {
        return (loc == '/gate' || loc == '/join') ? null : '/gate';
      }

      // Driver role → driver dashboard
      if (appUser?.role == UserRole.driver) {
        return loc == '/driver' ? null : '/driver';
      }

      // Setup not completed
      if (company != null && !company.setupCompleted && loc != '/setup') {
        return '/setup';
      }

      if (loc == '/login' || loc == '/gate') return '/dashboard';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/gate',
        builder: (_, __) => const CompanyGateScreen(),
      ),
      GoRoute(
        path: '/join',
        builder: (_, __) => const JoinCompanyScreen(),
      ),
      GoRoute(
        path: '/setup',
        builder: (_, __) => const SetupWizardScreen(),
      ),
      GoRoute(
        path: '/driver',
        builder: (_, __) => const DriverDashboardScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNav(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/dashboard',
              builder: (_, __) => const DashboardScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/orders',
              builder: (_, __) => const OrdersScreen(),
              routes: [
                GoRoute(
                  path: 'new',
                  builder: (_, __) => const OrderFormScreen(),
                ),
                GoRoute(
                  path: ':orderId',
                  builder: (_, state) => OrderDetailScreen(
                    orderId: state.pathParameters['orderId']!,
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/fleet',
              builder: (_, __) => const FleetScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/insights',
              builder: (_, __) => const InsightsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/more',
              builder: (_, __) => const MoreMenuScreen(),
              routes: [
                GoRoute(
                  path: 'expenses',
                  builder: (_, __) => const ExpensesScreen(),
                ),
                GoRoute(
                  path: 'customers',
                  builder: (_, __) => const CustomersScreen(),
                  routes: [
                    GoRoute(
                      path: ':customerId',
                      builder: (_, state) => CustomerDetailScreen(
                        customerId:
                            state.pathParameters['customerId']!,
                      ),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'settings',
                  builder: (_, __) => const SettingsScreen(),
                ),
                GoRoute(
                  path: 'team',
                  builder: (_, __) => const TeamScreen(),
                ),
              ],
            ),
          ]),
        ],
      ),
      GoRoute(
        path: '/invoice/:invoiceId',
        builder: (_, state) => InvoicePreviewScreen(
          invoiceId: state.pathParameters['invoiceId']!,
        ),
      ),
    ],
  );
});

class MoreMenuScreen extends ConsumerWidget {
  const MoreMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProfileProvider).valueOrNull;
    final company = ref.watch(currentCompanyProvider).valueOrNull;
    final isOwner = user?.isOwner ?? false;
    final canEdit = user?.canEditData ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile card
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor:
                    Theme.of(context).colorScheme.secondary,
                child: Text(
                  (user?.name.isNotEmpty == true
                          ? user!.name[0]
                          : 'T')
                      .toUpperCase(),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A)),
                ),
              ),
              title: Text(
                company?.name.isNotEmpty == true
                    ? company!.name
                    : 'TruckFlow',
                style:
                    const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                  '${user?.name ?? ''} • ${user?.role.label ?? ''}'),
            ),
          ),
          const SizedBox(height: 16),

          if (canEdit || user?.isAccountant == true)
            _MenuTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Expenses & Financial Position',
              subtitle:
                  'Fuel, repairs, wages, net profit & charts',
              onTap: () => context.push('/more/expenses'),
            ),
          const SizedBox(height: 10),

          if (canEdit)
            _MenuTile(
              icon: Icons.people_outline,
              title: 'Customers',
              subtitle:
                  'Client history, balances, WhatsApp & calls',
              onTap: () => context.push('/more/customers'),
            ),
          const SizedBox(height: 10),

          if (isOwner) ...[
            _MenuTile(
              icon: Icons.group_outlined,
              title: 'Manage Team',
              subtitle:
                  'Join codes, roles, add & remove members',
              onTap: () => context.push('/more/team'),
            ),
            const SizedBox(height: 10),
            _MenuTile(
              icon: Icons.settings_outlined,
              title: 'Settings & Business Setup',
              subtitle:
                  'Company profile, pricing rates, theme',
              onTap: () => context.push('/more/settings'),
            ),
          ],
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon,
            color: Theme.of(context).colorScheme.secondary),
        title: Text(title,
            style:
                const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/customer.dart';
import '../../core/models/invoice.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/loading_shimmer.dart';

import '../../core/extensions/color_extensions.dart';
class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  String _search = '';

  Future<void> _launchCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.trim());
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _showAddCustomerDialog() async {
    final companyId = ref.read(currentCompanyIdProvider);
    if (companyId == null) return;

    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final bizCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final addrCtrl = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Customer'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Contact Name *'),
                  validator: (v) => AppValidators.requiredField(v, 'Name'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: bizCtrl,
                  decoration: const InputDecoration(labelText: 'Business / Company'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone *'),
                  validator: AppValidators.phone,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: addrCtrl,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              await ref.read(firestoreServiceProvider).saveCustomer(
                    Customer(
                      id: '',
                      companyId: companyId,
                      name: nameCtrl.text.trim(),
                      business: bizCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      address: addrCtrl.text.trim(),
                      createdAt: DateTime.now(),
                    ),
                  );
              if (ctx.mounted) Navigator.pop(ctx, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer added')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);
    final orders = ref.watch(ordersProvider).valueOrNull ?? [];
    final invoices = ref.watch(invoicesProvider).valueOrNull ?? [];
    final currency = ref.watch(currentCompanyProvider).valueOrNull?.currency ?? 'USD';

    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCustomerDialog,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add Customer'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search customer name, business, or phone...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: customersAsync.when(
              loading: () => const LoadingShimmer(),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (customers) {
                final filtered = customers.where((c) {
                  if (_search.isEmpty) return true;
                  return '${c.name} ${c.business} ${c.phone}'
                      .toLowerCase()
                      .contains(_search);
                }).toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.people_outline,
                    title: 'No customers yet',
                    message: 'Add clients you haul cargo for to track orders & balances.',
                    actionLabel: 'Add Customer',
                    onAction: _showAddCustomerDialog,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(customersProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 88),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final customer = filtered[index];
                      final custOrders =
                          orders.where((o) => o.customerId == customer.id).toList();
                      final totalSpent = custOrders.fold<double>(
                        0,
                        (sum, o) => sum + o.totalAmount,
                      );
                      final outstanding = invoices
                          .where((inv) =>
                              inv.customerId == customer.id &&
                              inv.paymentStatus != PaymentStatus.paid)
                          .fold<double>(0, (sum, inv) => sum + inv.balanceDue);

                      return Card(
                        child: ListTile(
                          onTap: () =>
                              context.push('/more/customers/${customer.id}'),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  customer.business.isNotEmpty
                                      ? customer.business
                                      : customer.name,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                              if (custOrders.length >= 3)
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
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text('${customer.name} • ${custOrders.length} orders'),
                              const SizedBox(height: 4),
                              Text(
                                'Billed: ${AppFormatters.currency(totalSpent, code: currency)}'
                                '${outstanding > 0 ? ' • Due: ${AppFormatters.currency(outstanding, code: currency)}' : ''}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: outstanding > 0
                                      ? AppColors.loss
                                      : AppColors.profit,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Call',
                                icon: const Icon(Icons.phone_outlined),
                                onPressed: () => _launchCall(customer.phone),
                              ),
                              IconButton(
                                tooltip: 'WhatsApp',
                                icon: const Icon(
                                  Icons.chat_outlined,
                                  color: AppColors.profit,
                                ),
                                onPressed: () => _launchWhatsApp(customer.phone),
                              ),
                            ],
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
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/models/expense.dart';
import '../../core/models/invoice.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/loading_shimmer.dart';
import '../../shared/widgets/stat_card.dart';

enum FinancialPeriod {
  thisMonth('This Month'),
  lastMonth('Last Month'),
  thisYear('This Year'),
  custom('Custom');

  final String label;
  const FinancialPeriod(this.label);
}

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  FinancialPeriod _period = FinancialPeriod.thisYear;
  DateTimeRange? _customRange;
  String _search = '';

  DateTimeRange _resolveRange() {
    final now = DateTime.now();
    return switch (_period) {
      FinancialPeriod.thisMonth => DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        ),
      FinancialPeriod.lastMonth => DateTimeRange(
          start: DateTime(now.year, now.month - 1, 1),
          end: DateTime(now.year, now.month, 0, 23, 59, 59),
        ),
      FinancialPeriod.thisYear => DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: now,
        ),
      FinancialPeriod.custom => _customRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 90)),
            end: now,
          ),
    };
  }

  Future<void> _showAddExpenseDialog() async {
    final companyId = ref.read(currentCompanyIdProvider);
    if (companyId == null) return;
    final trucks = ref.read(trucksProvider).valueOrNull ?? [];

    final formKey = GlobalKey<FormState>();
    ExpenseCategory category = ExpenseCategory.fuel;
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime date = DateTime.now();
    String? truckId;
    File? receipt;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Expense'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<ExpenseCategory>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: ExpenseCategory.values
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.label),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => category = v ?? ExpenseCategory.fuel),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Amount *'),
                    validator: (v) => AppValidators.positiveNumber(v, 'Amount'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description *'),
                    validator: (v) =>
                        AppValidators.requiredField(v, 'Description'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String?>(
                    value: truckId,
                    decoration:
                        const InputDecoration(labelText: 'Link to Truck (Optional)'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('General / Company-wide'),
                      ),
                      ...trucks.map(
                        (t) => DropdownMenuItem(
                          value: t.id,
                          child: Text(t.regNumber),
                        ),
                      ),
                    ],
                    onChanged: (v) => setDialogState(() => truckId = v),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Expense Date'),
                    subtitle: Text(AppFormatters.date(date)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: date,
                        firstDate: DateTime(2023),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                      );
                      if (picked != null) setDialogState(() => date = picked);
                    },
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 1000,
                      );
                      if (picked != null) {
                        setDialogState(() => receipt = File(picked.path));
                      }
                    },
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: Text(
                      receipt == null
                          ? 'Attach Receipt Photo'
                          : 'Receipt Attached ✓',
                    ),
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
                final fs = ref.read(firestoreServiceProvider);
                final id = await fs.saveExpense(
                  Expense(
                    id: '',
                    companyId: companyId,
                    category: category,
                    amount: double.parse(amountCtrl.text.trim()),
                    date: date,
                    description: descCtrl.text.trim(),
                    truckId: truckId,
                    createdAt: DateTime.now(),
                  ),
                );
                if (receipt != null) {
                  try {
                    final url = await ref
                        .read(storageServiceProvider)
                        .uploadExpenseReceipt(
                          companyId: companyId,
                          expenseId: id,
                          file: receipt!,
                        );
                    await fs.saveExpense(
                      Expense(
                        id: id,
                        companyId: companyId,
                        category: category,
                        amount: double.parse(amountCtrl.text.trim()),
                        date: date,
                        description: descCtrl.text.trim(),
                        truckId: truckId,
                        receiptUrl: url,
                        createdAt: DateTime.now(),
                      ),
                    );
                  } catch (_) {}
                }
                if (ctx.mounted) Navigator.pop(ctx, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense recorded')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesProvider);
    final invoices = ref.watch(invoicesProvider).valueOrNull ?? [];
    final trucks = ref.watch(trucksProvider).valueOrNull ?? [];
    final currency = ref.watch(currentCompanyProvider).valueOrNull?.currency ?? 'USD';

    final range = _resolveRange();

    return Scaffold(
      appBar: AppBar(title: const Text('Expenses & Financials')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
      body: expensesAsync.when(
        loading: () => const LoadingShimmer(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (allExpenses) {
          final periodExpenses = allExpenses.where((e) {
            final inRange = !e.date.isBefore(range.start) &&
                !e.date.isAfter(range.end);
            if (!inRange) return false;
            if (_search.isNotEmpty) {
              return '${e.category.label} ${e.description}'
                  .toLowerCase()
                  .contains(_search);
            }
            return true;
          }).toList();

          final periodInvoices = invoices.where((i) =>
              !i.issueDate.isBefore(range.start) &&
              !i.issueDate.isAfter(range.end));

          final totalRevenue = periodInvoices.fold<double>(
            0,
            (s, i) => s + i.amountPaid,
          );
          final outstanding = invoices
              .where((i) => i.paymentStatus != PaymentStatus.paid)
              .fold<double>(0, (s, i) => s + i.balanceDue);
          final totalExpenses = periodExpenses.fold<double>(
            0,
            (s, e) => s + e.amount,
          );
          final netProfit = totalRevenue - totalExpenses;

          // Build category totals for pie chart
          final categoryTotals = <ExpenseCategory, double>{};
          for (final exp in periodExpenses) {
            categoryTotals[exp.category] =
                (categoryTotals[exp.category] ?? 0) + exp.amount;
          }

          // Monthly income vs expense (last 6 months)
          final now = DateTime.now();
          final monthKeys = List.generate(6, (i) {
            final dt = DateTime(now.year, now.month - (5 - i), 1);
            return dt;
          });

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(expensesProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: FinancialPeriod.values.map((p) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(p.label),
                          selected: _period == p,
                          onSelected: (_) async {
                            if (p == FinancialPeriod.custom) {
                              final picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2023),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  _customRange = picked;
                                  _period = p;
                                });
                              }
                            } else {
                              setState(() => _period = p);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.55,
                  children: [
                    StatCard(
                      label: 'Revenue (Paid)',
                      value: AppFormatters.compactCurrency(totalRevenue, code: currency),
                      icon: Icons.trending_up,
                      accentColor: AppColors.profit,
                    ),
                    StatCard(
                      label: 'Outstanding',
                      value: AppFormatters.compactCurrency(outstanding, code: currency),
                      icon: Icons.hourglass_bottom,
                      accentColor: AppColors.warning,
                    ),
                    StatCard(
                      label: 'Total Expenses',
                      value: AppFormatters.compactCurrency(totalExpenses, code: currency),
                      icon: Icons.trending_down,
                      accentColor: AppColors.loss,
                    ),
                    StatCard(
                      label: 'Net Profit',
                      value: AppFormatters.compactCurrency(netProfit, code: currency),
                      icon: Icons.account_balance_wallet,
                      accentColor:
                          netProfit >= 0 ? AppColors.profit : AppColors.loss,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Monthly Income vs Expense Bar Chart
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Monthly Income vs Expenses (6 Months)',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 180,
                          child: BarChart(
                            BarChartData(
                              borderData: FlBorderData(show: false),
                              gridData: const FlGridData(show: false),
                              titlesData: FlTitlesData(
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (val, _) {
                                      final idx = val.toInt();
                                      if (idx < 0 || idx >= monthKeys.length) {
                                        return const SizedBox.shrink();
                                      }
                                      return Text(
                                        AppFormatters.shortDate(monthKeys[idx])
                                            .split(' ')
                                            .last,
                                        style: const TextStyle(fontSize: 10),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              barGroups: List.generate(monthKeys.length, (i) {
                                final m = monthKeys[i];
                                final mInc = invoices
                                    .where((inv) =>
                                        inv.issueDate.year == m.year &&
                                        inv.issueDate.month == m.month)
                                    .fold<double>(0, (s, x) => s + x.amountPaid);
                                final mExp = allExpenses
                                    .where((exp) =>
                                        exp.date.year == m.year &&
                                        exp.date.month == m.month)
                                    .fold<double>(0, (s, x) => s + x.amount);
                                return BarChartGroupData(
                                  x: i,
                                  barRods: [
                                    BarChartRodData(
                                      toY: mInc,
                                      color: AppColors.profit,
                                      width: 8,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    BarChartRodData(
                                      toY: mExp,
                                      color: AppColors.loss,
                                      width: 8,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (categoryTotals.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Expenses by Category',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 160,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 34,
                                sections: categoryTotals.entries.map((entry) {
                                  final colors = [
                                    AppColors.primary,
                                    AppColors.accent,
                                    AppColors.info,
                                    AppColors.loss,
                                    AppColors.profit,
                                    Colors.teal,
                                    Colors.indigo,
                                    Colors.brown,
                                    Colors.blueGrey,
                                  ];
                                  final color = colors[entry.key.index % colors.length];
                                  final pct = totalExpenses > 0
                                      ? (entry.value / totalExpenses) * 100
                                      : 0;
                                  return PieChartSectionData(
                                    value: entry.value,
                                    color: color,
                                    radius: 46,
                                    title: '${pct.toStringAsFixed(0)}%',
                                    titleStyle: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 12,
                            runSpacing: 6,
                            children: categoryTotals.entries.map((e) {
                              return Text(
                                '${e.key.label}: ${AppFormatters.compactCurrency(e.value, code: currency)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 18),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search expenses...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) =>
                      setState(() => _search = v.trim().toLowerCase()),
                ),
                const SizedBox(height: 12),

                if (periodExpenses.isEmpty)
                  EmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'No expenses in this period',
                    message: 'Record fuel, tolls, repairs, or wages to track true profit.',
                    actionLabel: 'Add Expense',
                    onAction: _showAddExpenseDialog,
                  )
                else
                  ...periodExpenses.map((exp) {
                    final truck =
                        trucks.where((t) => t.id == exp.truckId).firstOrNull;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        child: ListTile(
                          title: Text(
                            exp.description,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${exp.category.label} • ${AppFormatters.date(exp.date)}${truck != null ? ' • ${truck.regNumber}' : ''}',
                          ),
                          trailing: Text(
                            AppFormatters.currency(exp.amount, code: currency),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.loss,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

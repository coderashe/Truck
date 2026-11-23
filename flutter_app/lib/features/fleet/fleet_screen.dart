import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/models/driver.dart';
import '../../core/models/truck.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/loading_shimmer.dart';
import '../../shared/widgets/status_chip.dart';

import '../../core/extensions/color_extensions.dart';
class FleetScreen extends ConsumerStatefulWidget {
  const FleetScreen({super.key});

  @override
  ConsumerState<FleetScreen> createState() => _FleetScreenState();
}

class _FleetScreenState extends ConsumerState<FleetScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showAddTruckDialog() async {
    final companyId = ref.read(currentCompanyIdProvider);
    if (companyId == null) return;

    final formKey = GlobalKey<FormState>();
    final regCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final capCtrl = TextEditingController(text: '34');
    String fuel = 'Diesel';
    TruckStatus status = TruckStatus.active;
    File? photo;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Truck'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final picked = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 1000,
                        imageQuality: 85,
                      );
                      if (picked != null) {
                        setDialogState(() => photo = File(picked.path));
                      }
                    },
                    child: Container(
                      height: 90,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(ctx).dividerColor),
                        image: photo != null
                            ? DecorationImage(
                                image: FileImage(photo!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: photo == null
                          ? const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_a_photo_outlined),
                                  SizedBox(height: 4),
                                  Text('Add Truck Photo (Optional)'),
                                ],
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: regCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration:
                        const InputDecoration(labelText: 'Registration No. *'),
                    validator: (v) =>
                        AppValidators.requiredField(v, 'Registration number'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: modelCtrl,
                    decoration: const InputDecoration(labelText: 'Make & Model *'),
                    validator: (v) =>
                        AppValidators.requiredField(v, 'Make & model'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: capCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'Capacity (Tonnes) *'),
                    validator: (v) =>
                        AppValidators.positiveNumber(v, 'Capacity'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: fuel,
                    decoration: const InputDecoration(labelText: 'Fuel Type'),
                    items: const [
                      DropdownMenuItem(value: 'Diesel', child: Text('Diesel')),
                      DropdownMenuItem(value: 'Petrol', child: Text('Petrol')),
                    ],
                    onChanged: (v) => setDialogState(() => fuel = v ?? 'Diesel'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<TruckStatus>(
                    value: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: TruckStatus.values
                        .map(
                          (s) =>
                              DropdownMenuItem(value: s, child: Text(s.label)),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => status = v ?? TruckStatus.active),
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
                final truckId = await fs.saveTruck(
                  Truck(
                    id: '',
                    companyId: companyId,
                    regNumber: regCtrl.text.trim().toUpperCase(),
                    makeModel: modelCtrl.text.trim(),
                    capacityTonnes: double.tryParse(capCtrl.text.trim()) ?? 30,
                    fuelType: fuel,
                    status: status,
                    createdAt: DateTime.now(),
                  ),
                );
                if (photo != null) {
                  try {
                    final url = await ref
                        .read(storageServiceProvider)
                        .uploadTruckPhoto(
                          companyId: companyId,
                          truckId: truckId,
                          file: photo!,
                        );
                    await fs.saveTruck(
                      Truck(
                        id: truckId,
                        companyId: companyId,
                        regNumber: regCtrl.text.trim().toUpperCase(),
                        makeModel: modelCtrl.text.trim(),
                        capacityTonnes:
                            double.tryParse(capCtrl.text.trim()) ?? 30,
                        fuelType: fuel,
                        status: status,
                        photoUrl: url,
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
        const SnackBar(content: Text('Truck added to fleet')),
      );
    }
  }

  Future<void> _showAddDriverDialog() async {
    final companyId = ref.read(currentCompanyIdProvider);
    if (companyId == null) return;
    final trucks = ref.read(trucksProvider).valueOrNull ?? [];

    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final licenceCtrl = TextEditingController();
    DateTime expiry = DateTime.now().add(const Duration(days: 365));
    String? assignedTruckId;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Driver'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Driver Name *'),
                    validator: (v) => AppValidators.requiredField(v, 'Name'),
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
                    controller: licenceCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Licence Number *'),
                    validator: (v) =>
                        AppValidators.requiredField(v, 'Licence number'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: assignedTruckId,
                    decoration:
                        const InputDecoration(labelText: 'Assigned Truck'),
                    items: trucks
                        .map(
                          (t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(t.regNumber),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setDialogState(() => assignedTruckId = v),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Licence Expiry'),
                    subtitle: Text(AppFormatters.date(expiry)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: expiry,
                        firstDate: DateTime(2023),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) setDialogState(() => expiry = picked);
                    },
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
                await ref.read(firestoreServiceProvider).saveDriver(
                      Driver(
                        id: '',
                        companyId: companyId,
                        name: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        licenceNumber: licenceCtrl.text.trim(),
                        licenceExpiry: expiry,
                        assignedTruckId: assignedTruckId,
                        createdAt: DateTime.now(),
                      ),
                    );
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
        const SnackBar(content: Text('Driver added')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final trucksAsync = ref.watch(trucksProvider);
    final driversAsync = ref.watch(driversProvider);
    final isOwner = ref.watch(currentUserProfileProvider).valueOrNull?.isOwner ?? true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Trucks'),
            Tab(text: 'Drivers'),
          ],
        ),
      ),
      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
              onPressed: () {
                if (_tabController.index == 0) {
                  _showAddTruckDialog();
                } else {
                  _showAddDriverDialog();
                }
              },
              icon: const Icon(Icons.add),
              label: AnimatedBuilder(
                animation: _tabController,
                builder: (_, __) => Text(
                  _tabController.index == 0 ? 'Add Truck' : 'Add Driver',
                ),
              ),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search registration, make, or driver...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                trucksAsync.when(
                  loading: () => const LoadingShimmer(),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (trucks) {
                    final filtered = trucks.where((t) {
                      if (_search.isEmpty) return true;
                      return '${t.regNumber} ${t.makeModel}'
                          .toLowerCase()
                          .contains(_search);
                    }).toList();

                    if (filtered.isEmpty) {
                      return EmptyState(
                        icon: Icons.local_shipping_outlined,
                        title: 'No trucks in fleet',
                        message: 'Add your trucks to assign trips and track profitability.',
                        actionLabel: isOwner ? 'Add Truck' : null,
                        onAction: isOwner ? _showAddTruckDialog : null,
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async => ref.invalidate(trucksProvider),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 88),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final truck = filtered[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.1),
                                backgroundImage: truck.photoUrl != null
                                    ? NetworkImage(truck.photoUrl!)
                                    : null,
                                child: truck.photoUrl == null
                                    ? const Icon(Icons.local_shipping)
                                    : null,
                              ),
                              title: Text(
                                truck.regNumber,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                '${truck.makeModel} • ${truck.capacityTonnes.toStringAsFixed(0)}t • ${truck.fuelType}',
                              ),
                              trailing: StatusChip.truck(truck.status),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                driversAsync.when(
                  loading: () => const LoadingShimmer(),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (drivers) {
                    final filtered = drivers.where((d) {
                      if (_search.isEmpty) return true;
                      return '${d.name} ${d.licenceNumber}'
                          .toLowerCase()
                          .contains(_search);
                    }).toList();

                    if (filtered.isEmpty) {
                      return EmptyState(
                        icon: Icons.badge_outlined,
                        title: 'No drivers added',
                        message: 'Add drivers with licence details to assign trips.',
                        actionLabel: isOwner ? 'Add Driver' : null,
                        onAction: isOwner ? _showAddDriverDialog : null,
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async => ref.invalidate(driversProvider),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 88),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final driver = filtered[index];
                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.person_outline),
                              ),
                              title: Text(
                                driver.name,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                '${driver.phone} • Licence: ${driver.licenceNumber}\nExpires: ${AppFormatters.date(driver.licenceExpiry)}',
                              ),
                              isThreeLine: true,
                              trailing: driver.isLicenceExpiringSoon
                                  ? const Icon(
                                      Icons.warning_amber_rounded,
                                      color: AppColors.warning,
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/customer.dart';
import '../../core/models/order.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/price_calculator.dart';
import '../../core/utils/validators.dart';
import '../../shared/widgets/location_picker_screen.dart';

class OrderFormScreen extends ConsumerStatefulWidget {
  const OrderFormScreen({super.key});

  @override
  ConsumerState<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends ConsumerState<OrderFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedCustomerId;
  OrderSource _source = OrderSource.whatsapp;
  String? _selectedTruckId;
  String? _selectedDriverId;

  final _pickupCtrl = TextEditingController();
  final _dropoffCtrl = TextEditingController();
  final _routeNameCtrl = TextEditingController();
  final _distanceCtrl = TextEditingController(text: '439');
  final _rateCtrl = TextEditingController(text: '1.75');
  final _extrasCtrl = TextEditingController(text: '0');
  final _discountCtrl = TextEditingController(text: '0');
  final _cargoDescCtrl = TextEditingController();
  final _cargoWeightCtrl = TextEditingController(text: '28');

  GeoPointLocation _pickupGeo = const GeoPointLocation(
    address: 'Harare, Zimbabwe',
    lat: -17.8292,
    lng: 31.0522,
  );
  GeoPointLocation _dropoffGeo = const GeoPointLocation(
    address: 'Bulawayo, Zimbabwe',
    lat: -20.1325,
    lng: 28.6265,
  );

  bool _roundTrip = true;
  DateTime _tripDate = DateTime.now();
  bool _isSaving = false;
  bool _isCalculatingDistance = false;

  @override
  void initState() {
    super.initState();
    final company = ref.read(currentCompanyProvider).valueOrNull;
    if (company != null) {
      _rateCtrl.text = company.defaultRatePerKm.toStringAsFixed(2);
      _roundTrip = company.defaultRoundTrip;
    }
  }

  @override
  void dispose() {
    _pickupCtrl.dispose();
    _dropoffCtrl.dispose();
    _routeNameCtrl.dispose();
    _distanceCtrl.dispose();
    _rateCtrl.dispose();
    _extrasCtrl.dispose();
    _discountCtrl.dispose();
    _cargoDescCtrl.dispose();
    _cargoWeightCtrl.dispose();
    super.dispose();
  }

  TripPriceBreakdown get _livePrice {
    return PriceCalculator.calculate(
      distanceKm: double.tryParse(_distanceCtrl.text.trim()) ?? 0,
      roundTrip: _roundTrip,
      ratePerKm: double.tryParse(_rateCtrl.text.trim()) ?? 0,
      extras: double.tryParse(_extrasCtrl.text.trim()) ?? 0,
      discount: double.tryParse(_discountCtrl.text.trim()) ?? 0,
    );
  }

  Future<void> _openLocationPicker({required bool isPickup}) async {
    final result = await Navigator.of(context).push<GeoPointLocation>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => LocationPickerScreen(
          title: isPickup ? 'Pickup' : 'Drop-off',
          initial: isPickup ? _pickupGeo : _dropoffGeo,
        ),
      ),
    );
    if (result == null) return;
    setState(() {
      if (isPickup) {
        _pickupGeo = result;
        _pickupCtrl.text = result.address;
      } else {
        _dropoffGeo = result;
        _dropoffCtrl.text = result.address;
      }
    });
  }

  Future<void> _autoCalculateDistance() async {
    setState(() => _isCalculatingDistance = true);
    try {
      final maps = ref.read(mapsServiceProvider);
      final km = await maps.calculateDrivingDistanceKm(
        pickup: _pickupGeo,
        dropoff: _dropoffGeo,
      );
      _distanceCtrl.text = km.toStringAsFixed(0);
      setState(() {});
    } finally {
      if (mounted) setState(() => _isCalculatingDistance = false);
    }
  }

  Future<void> _openCreateCustomerDialog() async {
    final companyId = ref.read(currentCompanyIdProvider);
    if (companyId == null) return;

    final nameCtrl = TextEditingController();
    final bizCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final dialogKey = GlobalKey<FormState>();

    final createdId = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Customer'),
        content: SingleChildScrollView(
          child: Form(
            key: dialogKey,
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
                  decoration: const InputDecoration(labelText: 'Business Name'),
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!(dialogKey.currentState?.validate() ?? false)) return;
              final id = await ref.read(firestoreServiceProvider).saveCustomer(
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
              if (ctx.mounted) Navigator.pop(ctx, id);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (createdId != null) {
      setState(() => _selectedCustomerId = createdId);
    }
  }

  Future<void> _saveOrder() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final companyId = ref.read(currentCompanyIdProvider);
    final user = ref.read(currentUserProfileProvider).valueOrNull;
    final customers = ref.read(customersProvider).valueOrNull ?? [];
    if (companyId == null || user == null) return;

    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or create a customer')),
      );
      return;
    }

    final customer = customers.firstWhere(
      (c) => c.id == _selectedCustomerId,
      orElse: () => Customer(
        id: _selectedCustomerId!,
        companyId: companyId,
        name: 'Customer',
        business: '',
        phone: '',
        email: '',
        address: '',
        createdAt: DateTime.now(),
      ),
    );

    setState(() => _isSaving = true);
    try {
      final breakdown = _livePrice;
      final order = HaulageOrder(
        id: '',
        companyId: companyId,
        customerId: customer.id,
        customerName: customer.business.isNotEmpty
            ? customer.business
            : customer.name,
        source: _source,
        pickup: GeoPointLocation(
          address: _pickupCtrl.text.trim(),
          lat: _pickupGeo.lat,
          lng: _pickupGeo.lng,
        ),
        dropoff: GeoPointLocation(
          address: _dropoffCtrl.text.trim(),
          lat: _dropoffGeo.lat,
          lng: _dropoffGeo.lng,
        ),
        routeName: _routeNameCtrl.text.trim().isNotEmpty
            ? _routeNameCtrl.text.trim()
            : '${_pickupCtrl.text.trim()} → ${_dropoffCtrl.text.trim()}',
        distanceKm: breakdown.oneWayKm,
        roundTrip: breakdown.roundTrip,
        chargeableKm: breakdown.chargeableKm,
        ratePerKm: breakdown.ratePerKm,
        extras: breakdown.extras,
        discount: breakdown.discount,
        totalAmount: breakdown.totalAmount,
        truckId: _selectedTruckId ?? '',
        driverId: _selectedDriverId ?? '',
        cargoDescription: _cargoDescCtrl.text.trim(),
        cargoWeight: double.tryParse(_cargoWeightCtrl.text.trim()) ?? 0,
        tripDate: _tripDate,
        status: OrderStatus.pending,
        createdBy: user.uid,
        createdAt: DateTime.now(),
      );

      final orderId = await ref.read(firestoreServiceProvider).saveOrder(order);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order created successfully')),
        );
        context.go('/orders/$orderId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create order: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersProvider).valueOrNull ?? [];
    final trucks = ref.watch(trucksProvider).valueOrNull ?? [];
    final drivers = ref.watch(driversProvider).valueOrNull ?? [];
    final company = ref.watch(currentCompanyProvider).valueOrNull;
    final currency = company?.currency ?? 'USD';
    final price = _livePrice;

    return Scaffold(
      appBar: AppBar(title: const Text('New Haulage Order')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCustomerId,
                    decoration: const InputDecoration(labelText: 'Customer *'),
                    items: customers
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              c.displayName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCustomerId = v),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  tooltip: 'Add New Customer',
                  onPressed: _openCreateCustomerDialog,
                  icon: const Icon(Icons.person_add_alt_1),
                ),
              ],
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<OrderSource>(
              value: _source,
              decoration: const InputDecoration(labelText: 'Order Source'),
              items: OrderSource.values
                  .where((s) => s != OrderSource.portal)
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (v) => setState(() => _source = v ?? OrderSource.whatsapp),
            ),
            const SizedBox(height: 14),
            // Pickup — tap to open map picker
            _LocationTile(
              label: 'Pickup Location *',
              icon: Icons.trip_origin,
              iconColor: Colors.green,
              onTap: () => _openLocationPicker(isPickup: true),
              validator: (v) => AppValidators.requiredField(v, 'Pickup location'),
              controller: _pickupCtrl,
            ),
            const SizedBox(height: 12),
            // Drop-off — tap to open map picker
            _LocationTile(
              label: 'Drop-off Location *',
              icon: Icons.location_on,
              iconColor: Colors.red,
              onTap: () => _openLocationPicker(isPickup: false),
              validator: (v) => AppValidators.requiredField(v, 'Drop-off location'),
              controller: _dropoffCtrl,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _routeNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Route Name / Corridor',
                hintText: 'e.g. Harare → Bulawayo',
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _distanceCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'One-Way Distance (km) *',
                    ),
                    validator: (v) => AppValidators.positiveNumber(v, 'Distance'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed:
                      _isCalculatingDistance ? null : _autoCalculateDistance,
                  icon: _isCalculatingDistance
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.route),
                  label: const Text('Auto km'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Round-Trip Billing (× 2)'),
              subtitle: Text(
                'Chargeable distance: ${AppFormatters.km(price.chargeableKm)}',
              ),
              value: _roundTrip,
              onChanged: (v) => setState(() => _roundTrip = v),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _rateCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Rate / km *'),
                    validator: (v) => AppValidators.positiveNumber(v, 'Rate'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _extrasCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Extras (\$)'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _discountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Discount (\$)'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedTruckId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Assign Truck'),
                    items: trucks
                        .map((t) => DropdownMenuItem(
                              value: t.id,
                              child: Text(t.regNumber, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedTruckId = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedDriverId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Assign Driver'),
                    items: drivers
                        .map((d) => DropdownMenuItem(
                              value: d.id,
                              child: Text(d.name, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedDriverId = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _cargoDescCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Cargo Description *',
                      hintText: 'e.g. Bagged Cement / Maize',
                    ),
                    validator: (v) =>
                        AppValidators.requiredField(v, 'Cargo description'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cargoWeightCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Tonnes'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).dividerColor),
              ),
              title: const Text('Trip Date'),
              subtitle: Text(AppFormatters.date(_tripDate)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _tripDate,
                  firstDate: DateTime(2023),
                  lastDate: DateTime(2030),
                );
                if (picked != null) setState(() => _tripDate = picked);
              },
            ),
            const SizedBox(height: 20),

            // Live Price Calculation Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LIVE TRIP QUOTE',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${AppFormatters.km(price.chargeableKm)} × ${AppFormatters.currency(price.ratePerKm, code: currency)}/km',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        AppFormatters.currency(price.baseFreight, code: currency),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Order Value',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        AppFormatters.currency(price.totalAmount, code: currency),
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _isSaving ? null : _saveOrder,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Haulage Order'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Location tile widget ─────────────────────────────────────────────────────

class _LocationTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final String? Function(String?)? validator;
  final TextEditingController controller;

  const _LocationTile({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    required this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FormField<String>(
      initialValue: controller.text,
      validator: (_) => validator?.call(controller.text),
      builder: (state) {
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon, color: iconColor),
              suffixIcon: const Icon(Icons.map_outlined),
              errorText: state.errorText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              controller.text.isNotEmpty ? controller.text : 'Tap to select on map',
              style: controller.text.isNotEmpty
                  ? theme.textTheme.bodyMedium
                  : theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        );
      },
    );
  }
}

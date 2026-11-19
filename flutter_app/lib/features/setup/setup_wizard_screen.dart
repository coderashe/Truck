import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/models/driver.dart';
import '../../core/models/truck.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/validators.dart';

class SetupWizardScreen extends ConsumerStatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  ConsumerState<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends ConsumerState<SetupWizardScreen> {
  int _step = 0;
  bool _isSaving = false;

  // Step 1: Company
  final _companyFormKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _taxCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _footerCtrl = TextEditingController(
    text: 'Thank you for your business. Payment is due within 14 days.',
  );
  String _currency = 'USD';
  File? _logoFile;

  // Step 2: Pricing Defaults
  final _rateCtrl = TextEditingController(text: '1.75');
  bool _defaultRoundTrip = true;

  // Step 3: First Truck (optional quick add)
  final _truckRegCtrl = TextEditingController();
  final _truckModelCtrl = TextEditingController();
  final _truckCapCtrl = TextEditingController(text: '34');
  String _fuelType = 'Diesel';

  // Step 4: First Driver (optional quick add)
  final _driverNameCtrl = TextEditingController();
  final _driverPhoneCtrl = TextEditingController();
  final _driverLicenceCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final company = ref.read(currentCompanyProvider).valueOrNull;
    if (company != null) {
      _nameCtrl.text = company.name;
      _addressCtrl.text = company.address;
      _phoneCtrl.text = company.phone;
      _emailCtrl.text = company.email;
      _taxCtrl.text = company.taxNumber;
      _bankCtrl.text = company.bankDetails;
      _currency = company.currency;
      _rateCtrl.text = company.defaultRatePerKm.toStringAsFixed(2);
      _defaultRoundTrip = company.defaultRoundTrip;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _taxCtrl.dispose();
    _bankCtrl.dispose();
    _footerCtrl.dispose();
    _rateCtrl.dispose();
    _truckRegCtrl.dispose();
    _truckModelCtrl.dispose();
    _truckCapCtrl.dispose();
    _driverNameCtrl.dispose();
    _driverPhoneCtrl.dispose();
    _driverLicenceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _logoFile = File(picked.path));
    }
  }

  Future<void> _finishSetup() async {
    final company = ref.read(currentCompanyProvider).valueOrNull;
    if (company == null) return;

    setState(() => _isSaving = true);
    try {
      final fs = ref.read(firestoreServiceProvider);
      final storage = ref.read(storageServiceProvider);

      String? logoUrl = company.logoUrl;
      if (_logoFile != null) {
        logoUrl = await storage.uploadCompanyLogo(
          companyId: company.id,
          file: _logoFile!,
        );
      }

      final updated = company.copyWith(
        name: _nameCtrl.text.trim(),
        logoUrl: logoUrl,
        address: _addressCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        taxNumber: _taxCtrl.text.trim(),
        bankDetails: _bankCtrl.text.trim(),
        currency: _currency,
        invoiceFooter: _footerCtrl.text.trim(),
        defaultRatePerKm: double.tryParse(_rateCtrl.text.trim()) ?? 1.75,
        defaultRoundTrip: _defaultRoundTrip,
        setupCompleted: true,
      );

      await fs.updateCompany(updated);

      String? createdTruckId;
      if (_truckRegCtrl.text.trim().isNotEmpty) {
        createdTruckId = await fs.saveTruck(
          Truck(
            id: '',
            companyId: company.id,
            regNumber: _truckRegCtrl.text.trim().toUpperCase(),
            makeModel: _truckModelCtrl.text.trim(),
            capacityTonnes: double.tryParse(_truckCapCtrl.text.trim()) ?? 30,
            fuelType: _fuelType,
            createdAt: DateTime.now(),
          ),
        );
      }

      if (_driverNameCtrl.text.trim().isNotEmpty) {
        await fs.saveDriver(
          Driver(
            id: '',
            companyId: company.id,
            name: _driverNameCtrl.text.trim(),
            phone: _driverPhoneCtrl.text.trim(),
            licenceNumber: _driverLicenceCtrl.text.trim(),
            licenceExpiry: DateTime.now().add(const Duration(days: 365)),
            assignedTruckId: createdTruckId,
            createdAt: DateTime.now(),
          ),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business setup complete!')),
        );
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving setup: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Setup Wizard'),
        actions: [
          TextButton(
            onPressed: _isSaving
                ? null
                : () async {
                    final company = ref.read(currentCompanyProvider).valueOrNull;
                    if (company != null) {
                      await ref.read(firestoreServiceProvider).updateCompany(
                            company.copyWith(
                              name: company.name.isEmpty
                                  ? 'My Haulage Co.'
                                  : company.name,
                              setupCompleted: true,
                            ),
                          );
                    }
                    if (context.mounted) context.go('/dashboard');
                  },
            child: const Text('Skip'),
          ),
        ],
      ),
      body: Stepper(
        currentStep: _step,
        onStepContinue: () {
          if (_step == 0 && !(_companyFormKey.currentState?.validate() ?? false)) {
            return;
          }
          if (_step < 3) {
            setState(() => _step++);
          } else {
            _finishSetup();
          }
        },
        onStepCancel: () {
          if (_step > 0) setState(() => _step--);
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _isSaving ? null : details.onStepContinue,
                    child: _isSaving && _step == 3
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_step == 3 ? 'Complete Setup' : 'Continue'),
                  ),
                ),
                if (_step > 0) ...[
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Company Details'),
            isActive: _step >= 0,
            content: Form(
              key: _companyFormKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _pickLogo,
                        child: CircleAvatar(
                          radius: 30,
                          backgroundImage:
                              _logoFile != null ? FileImage(_logoFile!) : null,
                          child: _logoFile == null
                              ? const Icon(Icons.add_a_photo_outlined)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Company Name *',
                          ),
                          validator: (v) =>
                              AppValidators.requiredField(v, 'Company Name'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone Number *'),
                    validator: AppValidators.phone,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Company Email'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressCtrl,
                    decoration: const InputDecoration(labelText: 'Physical Address'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _taxCtrl,
                          decoration:
                              const InputDecoration(labelText: 'Tax / Reg No.'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _currency,
                          decoration: const InputDecoration(labelText: 'Currency'),
                          items: const [
                            DropdownMenuItem(value: 'USD', child: Text('USD (\$)')),
                            DropdownMenuItem(value: 'ZAR', child: Text('ZAR (R)')),
                            DropdownMenuItem(value: 'ZiG', child: Text('ZiG')),
                          ],
                          onChanged: (v) => setState(() => _currency = v ?? 'USD'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bankCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Bank / Payment Details (shown on invoices)',
                    ),
                  ),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Pricing Defaults'),
            isActive: _step >= 1,
            content: Column(
              children: [
                TextFormField(
                  controller: _rateCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Default Rate per km',
                    helperText: 'Typical range: \$1.50 – \$2.00 per km',
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Charge Round-Trip by Default'),
                  subtitle: const Text(
                    'Doubles distance (× 2) to cover the return leg.',
                  ),
                  value: _defaultRoundTrip,
                  onChanged: (v) => setState(() => _defaultRoundTrip = v),
                ),
                TextFormField(
                  controller: _footerCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Invoice Footer Note'),
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Add First Truck'),
            isActive: _step >= 2,
            content: Column(
              children: [
                TextFormField(
                  controller: _truckRegCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Registration Number (e.g. AFX 4821)',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _truckModelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Make & Model (e.g. Volvo FH16)',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _truckCapCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Capacity (Tonnes)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _fuelType,
                        decoration: const InputDecoration(labelText: 'Fuel'),
                        items: const [
                          DropdownMenuItem(value: 'Diesel', child: Text('Diesel')),
                          DropdownMenuItem(value: 'Petrol', child: Text('Petrol')),
                        ],
                        onChanged: (v) => setState(() => _fuelType = v ?? 'Diesel'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Add First Driver'),
            isActive: _step >= 3,
            content: Column(
              children: [
                TextFormField(
                  controller: _driverNameCtrl,
                  decoration: const InputDecoration(labelText: 'Driver Full Name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _driverPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Driver Phone'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _driverLicenceCtrl,
                  decoration: const InputDecoration(labelText: 'Licence Number'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

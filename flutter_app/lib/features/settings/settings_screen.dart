import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import 'seed_data.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _footerCtrl = TextEditingController();
  bool _defaultRoundTrip = true;
  int _accentHex = 0xFF0F172A;

  // Personal profile controllers
  final _profileNameCtrl = TextEditingController();
  final _profilePhoneCtrl = TextEditingController();
  bool _profileInitialized = false;

  int _versionTapCount = 0;
  bool _devMenuVisible = false;
  bool _isSeeding = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _rateCtrl.dispose();
    _bankCtrl.dispose();
    _footerCtrl.dispose();
    _profileNameCtrl.dispose();
    _profilePhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final user = ref.read(currentUserProfileProvider).valueOrNull;
    if (user == null) return;
    await ref.read(firestoreServiceProvider).updateUserProfile(
          uid: user.uid,
          name: _profileNameCtrl.text.trim(),
          phone: _profilePhoneCtrl.text.trim(),
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    }
  }

  Future<void> _saveSettings() async {
    final company = ref.read(currentCompanyProvider).valueOrNull;
    if (company == null) return;

    await ref.read(firestoreServiceProvider).updateCompany(
          company.copyWith(
            name: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            address: _addressCtrl.text.trim(),
            defaultRatePerKm:
                double.tryParse(_rateCtrl.text.trim()) ?? company.defaultRatePerKm,
            defaultRoundTrip: _defaultRoundTrip,
            bankDetails: _bankCtrl.text.trim(),
            invoiceFooter: _footerCtrl.text.trim(),
            invoiceAccentHex: _accentHex,
          ),
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company settings updated')),
      );
    }
  }

  Future<void> _runSeeder() async {
    final companyId = ref.read(currentCompanyIdProvider);
    final user = ref.read(currentUserProfileProvider).valueOrNull;
    if (companyId == null || user == null) return;

    setState(() => _isSeeding = true);
    try {
      await SeedDataUtility.seedZimbabweanDataset(
        companyId: companyId,
        ownerUid: user.uid,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Seeded 5 trucks, 4 drivers, 12 customers, 60 orders & 40 expenses!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Seed error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final company = ref.watch(currentCompanyProvider).valueOrNull;
    final user = ref.watch(currentUserProfileProvider).valueOrNull;
    final themeMode = ref.watch(themeModeProvider);

    if (company != null && !_initialized) {
      _nameCtrl.text = company.name;
      _phoneCtrl.text = company.phone;
      _addressCtrl.text = company.address;
      _rateCtrl.text = company.defaultRatePerKm.toStringAsFixed(2);
      _bankCtrl.text = company.bankDetails;
      _footerCtrl.text = company.invoiceFooter;
      _defaultRoundTrip = company.defaultRoundTrip;
      _accentHex = company.invoiceAccentHex;
      _initialized = true;
    }

    if (user != null && !_profileInitialized) {
      _profileNameCtrl.text = user.name;
      _profilePhoneCtrl.text = user.phone;
      _profileInitialized = true;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'My Profile',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _profileNameCtrl,
            decoration: const InputDecoration(labelText: 'Your Name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _profilePhoneCtrl,
            keyboardType: TextInputType.phone,
            decoration:
                const InputDecoration(labelText: 'Your Phone'),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: _saveProfile,
            child: const Text('Update Profile'),
          ),
          const Divider(height: 32),
          const Text(
            'Company & Pricing Defaults',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Company Name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneCtrl,
            decoration: const InputDecoration(labelText: 'Phone'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _addressCtrl,
            decoration: const InputDecoration(labelText: 'Address'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _rateCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Default Rate per km'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Round-Trip Default'),
            value: _defaultRoundTrip,
            onChanged: (v) => setState(() => _defaultRoundTrip = v),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _bankCtrl,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Bank / Payment Details'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _footerCtrl,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Invoice Footer Note'),
          ),
          const SizedBox(height: 14),
          const Text('Invoice Accent Colour'),
          const SizedBox(height: 8),
          Row(
            children: [
              0xFF0F172A,
              0xFF1E3A8A,
              0xFF065F46,
              0xFFB45309,
            ].map((hex) {
              final selected = _accentHex == hex;
              return GestureDetector(
                onTap: () => setState(() => _accentHex = hex),
                child: Container(
                  width: 34,
                  height: 34,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: Color(hex),
                    shape: BoxShape.circle,
                    border: selected
                        ? Border.all(color: AppColors.accent, width: 3)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saveSettings,
            child: const Text('Save Changes'),
          ),
          const Divider(height: 32),
          const Text(
            'Appearance',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('System')),
              ButtonSegment(value: ThemeMode.light, label: Text('Light')),
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
            ],
            selected: {themeMode},
            onSelectionChanged: (s) =>
                ref.read(themeModeProvider.notifier).state = s.first,
          ),
          const Divider(height: 32),
          OutlinedButton.icon(
            onPressed: () async => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout, color: AppColors.loss),
            label: const Text(
              'Sign Out',
              style: TextStyle(color: AppColors.loss),
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            title: const Text('TruckFlow Version 1.0.0'),
            subtitle: const Text('Tap 5 times to unlock developer seed tools'),
            onTap: () {
              _versionTapCount++;
              if (_versionTapCount >= 5) {
                setState(() => _devMenuVisible = true);
              }
            },
          ),
          if (_devMenuVisible)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Developer Tools',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Seeds 1 Zimbabwean company profile, 5 trucks, 4 drivers, 12 customers, 60 orders across 8 routes, mixed invoices, and 40 expenses.',
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _isSeeding ? null : _runSeeder,
                      icon: _isSeeding
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.dataset_outlined),
                      label: const Text('Seed Sample Data'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

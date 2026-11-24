import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/app_providers.dart';

class JoinCompanyScreen extends ConsumerStatefulWidget {
  const JoinCompanyScreen({super.key});

  @override
  ConsumerState<JoinCompanyScreen> createState() => _JoinCompanyScreenState();
}

class _JoinCompanyScreenState extends ConsumerState<JoinCompanyScreen> {
  final _codeCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  // After code validated — awaiting driver selection
  String? _pendingCompanyId;
  String? _pendingRole;
  String? _pendingCompanyName;
  String? _selectedDriverId;
  List<dynamic> _drivers = [];

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _validateCode() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final fs = ref.read(firestoreServiceProvider);
      final result = await fs.findCompanyByJoinCode(code);
      if (result == null) {
        setState(() {
          _error = 'Invalid code. Please check and try again.';
          _isLoading = false;
        });
        return;
      }

      // Fetch company name and drivers if driver role
      final companySnap = await fs.watchCompany(result.companyId).first;
      final driversSnap = result.role == 'driver'
          ? await fs.watchDrivers(result.companyId).first
          : <dynamic>[];

      setState(() {
        _pendingCompanyId = result.companyId;
        _pendingRole = result.role;
        _pendingCompanyName = companySnap?.name ?? 'Company';
        _drivers = driversSnap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmJoin() async {
    final user = ref.read(currentUserProfileProvider).valueOrNull;
    if (user == null || _pendingCompanyId == null || _pendingRole == null) {
      return;
    }

    if (_pendingRole == 'driver' && _selectedDriverId == null) {
      setState(() => _error = 'Please select your driver profile.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(firestoreServiceProvider).joinCompany(
            uid: user.uid,
            companyId: _pendingCompanyId!,
            role: _pendingRole!,
            name: user.name,
            email: user.email,
            driverId:
                _pendingRole == 'driver' ? _selectedDriverId : null,
          );
      if (mounted) context.go('/dashboard');
    } catch (e) {
      setState(() {
        _error = 'Failed to join: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Join a Company')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your join code',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask your company owner for a code. It looks like MGR-XXXX, ACC-XXXX, or DRV-XXXX.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            if (_pendingCompanyId == null) ...[
              TextField(
                controller: _codeCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Join Code',
                  hintText: 'e.g. MGR-K3P9',
                  prefixIcon: Icon(Icons.vpn_key_outlined),
                ),
                onChanged: (_) => setState(() => _error = null),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!,
                    style:
                        TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _validateCode,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Validate Code'),
                ),
              ),
            ] else ...[
              // Confirmation card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.business, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _pendingCompanyName!,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.badge_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text('You are joining as: ',
                            style: theme.textTheme.bodyMedium),
                        Text(
                          _pendingRole!.toUpperCase(),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.blue),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),

              // Driver profile selector
              if (_pendingRole == 'driver' && _drivers.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Select your driver profile',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedDriverId,
                  decoration: const InputDecoration(
                      labelText: 'Your Name in the System'),
                  items: _drivers.map((d) {
                    return DropdownMenuItem<String>(
                      value: d.id as String,
                      child: Text(d.name as String),
                    );
                  }).toList(),
                  onChanged: (v) =>
                      setState(() => _selectedDriverId = v),
                ),
              ],

              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!,
                    style:
                        TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _pendingCompanyId = null;
                      _pendingRole = null;
                    }),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _isLoading ? null : _confirmJoin,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2),
                          )
                        : const Text('Join Company'),
                  ),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CompanyGateScreen extends StatelessWidget {
  const CompanyGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.local_shipping, size: 72, color: Colors.blue),
              const SizedBox(height: 24),
              Text(
                'Welcome to TruckFlow',
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Are you setting up a new company, or joining an existing one?',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.go('/setup'),
                  icon: const Icon(Icons.add_business_outlined),
                  label: const Text('Create My Company'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/join'),
                  icon: const Icon(Icons.vpn_key_outlined),
                  label: const Text('Join with a Code'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

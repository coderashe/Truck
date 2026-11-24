import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/app_user.dart';
import '../../core/models/company.dart';
import '../../core/providers/app_providers.dart';

class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyAsync = ref.watch(currentCompanyProvider);
    final companyId = ref.watch(currentCompanyIdProvider) ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Team')),
      body: companyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (company) {
          if (company == null) return const SizedBox();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Join codes section
              Text(
                'Join Codes',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'Share these codes with your team. Each code is role-specific.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ...['manager', 'accountant', 'driver'].map((role) {
                final code = company.joinCodes[role] ?? '—';
                final label =
                    role[0].toUpperCase() + role.substring(1);
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          _roleColor(role).withOpacity(0.15),
                      child: Icon(_roleIcon(role),
                          color: _roleColor(role), size: 20),
                    ),
                    title: Text(label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      code,
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          letterSpacing: 1.5),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Copy code',
                          icon: const Icon(Icons.copy_outlined,
                              size: 20),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: code));
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(
                              content: Text('$label code copied'),
                            ));
                          },
                        ),
                        IconButton(
                          tooltip: 'Regenerate code',
                          icon: const Icon(Icons.refresh, size: 20),
                          onPressed: () => _confirmRegenerate(
                              context, ref, companyId, role, label),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const Divider(height: 32),

              // Members section
              Text(
                'Team Members',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (company.members.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'No team members yet. Share a join code to invite people.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...company.members.map((member) => _MemberTile(
                      member: member,
                      companyId: companyId,
                    )),
            ],
          );
        },
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'manager':
        return Colors.blue;
      case 'accountant':
        return Colors.green;
      case 'driver':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'manager':
        return Icons.manage_accounts_outlined;
      case 'accountant':
        return Icons.account_balance_outlined;
      case 'driver':
        return Icons.local_shipping_outlined;
      default:
        return Icons.person_outline;
    }
  }

  Future<void> _confirmRegenerate(BuildContext context, WidgetRef ref,
      String companyId, String role, String label) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Regenerate $label Code?'),
        content: const Text(
            'The old code will stop working for new joins. Existing members keep their access.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Regenerate')),
        ],
      ),
    );
    if (confirmed != true) return;
    final newCode = await ref
        .read(firestoreServiceProvider)
        .regenerateJoinCode(companyId, role);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('New $label code: $newCode')),
      );
    }
  }
}

class _MemberTile extends ConsumerWidget {
  final TeamMember member;
  final String companyId;

  const _MemberTile({required this.member, required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser =
        ref.watch(currentUserProfileProvider).valueOrNull;
    final isCurrentUser = currentUser?.uid == member.uid;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(member.name.isNotEmpty
              ? member.name[0].toUpperCase()
              : '?'),
        ),
        title: Text(member.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(member.email),
        trailing: isCurrentUser
            ? const Chip(label: Text('You'))
            : PopupMenuButton<String>(
                onSelected: (action) async {
                  if (action == 'remove') {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Remove Member?'),
                        content: Text(
                            'Remove ${member.name} from the company?'),
                        actions: [
                          TextButton(
                              onPressed: () =>
                                  Navigator.pop(ctx, false),
                              child: const Text('Cancel')),
                          FilledButton(
                              onPressed: () =>
                                  Navigator.pop(ctx, true),
                              child: const Text('Remove')),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      await ref
                          .read(firestoreServiceProvider)
                          .removeMember(
                              companyId: companyId, uid: member.uid);
                    }
                  } else {
                    // change role
                    await ref
                        .read(firestoreServiceProvider)
                        .updateMemberRole(
                          companyId: companyId,
                          uid: member.uid,
                          newRole: action,
                        );
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'manager',
                      child: Text('Set as Manager')),
                  const PopupMenuItem(
                      value: 'accountant',
                      child: Text('Set as Accountant')),
                  const PopupMenuItem(
                      value: 'driver',
                      child: Text('Set as Driver')),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Text('Remove from Company',
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
                child: const Icon(Icons.more_vert),
              ),
      ),
    );
  }
}

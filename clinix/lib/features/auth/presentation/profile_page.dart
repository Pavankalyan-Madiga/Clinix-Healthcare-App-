import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/auth_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(authStateProvider);

    if (staff == null) {
      return const Scaffold(
        body: Center(child: Text('No authenticated staff session.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 44,
              child: Text(
                _initials(staff.name),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Center(
            child: Text(
              staff.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
          ),

          const SizedBox(height: 6),

          Center(
            child: Text(
              staff.role,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
          ),

          const SizedBox(height: 32),

          _sectionTitle('Personal Information'),

          _infoCard(context, [
            _InfoItem(
              icon: Icons.badge_outlined,
              title: 'Staff ID',
              value: staff.id,
            ),
            _InfoItem(
              icon: Icons.person_outline,
              title: 'Name',
              value: staff.name,
            ),
            _InfoItem(
              icon: Icons.email_outlined,
              title: 'Email',
              value: staff.email,
            ),
            _InfoItem(
              icon: Icons.work_outline,
              title: 'Role',
              value: staff.role,
            ),
          ]),

          const SizedBox(height: 24),

          _sectionTitle('Work Information'),

          _infoCard(context, [
            _InfoItem(
              icon: Icons.business_outlined,
              title: 'Department',
              value: staff.department,
            ),
            _InfoItem(
              icon: Icons.circle_outlined,
              title: 'Status',
              value: staff.status,
            ),
          ]),

          const SizedBox(height: 32),

          FilledButton.tonalIcon(
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();

              if (!context.mounted) {
                return;
              }

              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.logout_outlined),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _infoCard(BuildContext context, List<_InfoItem> items) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            ListTile(
              leading: Icon(items[i].icon),
              title: Text(
                items[i].title,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              subtitle: Text(
                items[i].value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (i < items.length - 1)
              Divider(height: 1, color: Colors.grey.shade200),
          ],
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');

    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _InfoItem {
  final IconData icon;
  final String title;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.title,
    required this.value,
  });
}

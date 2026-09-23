import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/auth_providers.dart';
import '../data/staff_directory.dart';
import '../data/staff_option.dart';

class NewMessagePage extends ConsumerWidget {
  const NewMessagePage({
    super.key,
  });

  String _initials(String name) {
    final parts = name.trim().split(' ');

    if (parts.length == 1) {
      return parts.first.isNotEmpty
          ? parts.first[0].toUpperCase()
          : '?';
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final currentStaff = ref.watch(
      authStateProvider,
    );

    if (currentStaff == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Please sign in again.',
          ),
        ),
      );
    }

    final availableStaff = StaffDirectory.getOtherStaff(
      currentStaff.id,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'New Message',
        ),
      ),
      body: ListView.separated(
        itemCount: availableStaff.length,
        separatorBuilder: (_, index) {
          return const Divider(
            height: 1,
          );
        },
        itemBuilder: (context, index) {
          final staff = availableStaff[index];

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 9,
            ),
            leading: CircleAvatar(
              radius: 25,
              child: Text(
                _initials(staff.name),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            title: Text(
              staff.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '${staff.id} • ${staff.role}',
            ),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: () {
              Navigator.pop(
                context,
                StaffOption(
                  id: staff.id,
                  name: staff.name,
                  role: staff.role,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
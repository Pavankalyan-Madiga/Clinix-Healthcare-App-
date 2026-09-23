import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/auth_providers.dart';

class MorePage extends ConsumerWidget {
  const MorePage({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final staff = ref.watch(
      authStateProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'More',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          12,
          16,
          32,
        ),
        children: [
          if (staff != null)
            _ProfileHeader(
              name: staff.name,
              role: staff.role,
              department: staff.department,
            ),

          const SizedBox(height: 24),

          const _SectionTitle(
            title: 'Account',
          ),

          _MoreTile(
            icon: Icons.person_outline,
            title: 'Staff Profile',
            subtitle: 'View your staff information',
            onTap: () {
              context.push('/profile');
            },
          ),

          const SizedBox(height: 24),

          const _SectionTitle(
            title: 'Application',
          ),

          _MoreTile(
            icon: Icons.settings_outlined,
            title: 'Settings',
            subtitle: 'Manage application preferences',
            onTap: () {
              context.push('/settings');
            },
          ),

          const SizedBox(height: 8),

          _MoreTile(
            icon: Icons.info_outline,
            title: 'About Clinix',
            subtitle: 'Application information',
            onTap: () {
              context.push('/about');
            },
          ),

          const SizedBox(height: 24),

          const _SectionTitle(
            title: 'Session',
          ),

          _MoreTile(
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Sign out of Clinix',
            iconColor: Colors.red,
            titleColor: Colors.red,
            onTap: () {
              _showLogoutDialog(
                context,
                ref,
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showLogoutDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final shouldLogout =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Logout',
          ),
          content: const Text(
            'Are you sure you want to sign out of Clinix?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Logout',
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true ||
        !context.mounted) {
      return;
    }

    await ref
        .read(authStateProvider.notifier)
        .logout();

    if (!context.mounted) {
      return;
    }

    context.go('/login');
  }
}

class _ProfileHeader
    extends StatelessWidget {
  final String name;
  final String role;
  final String department;

  const _ProfileHeader({
    required this.name,
    required this.role,
    required this.department,
  });

  String _initials(String name) {
    final parts =
        name.trim().split(' ');

    if (parts.length == 1) {
      return parts.first.isNotEmpty
          ? parts.first[0].toUpperCase()
          : '?';
    }

    return '${parts.first[0]}${parts.last[0]}'
        .toUpperCase();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            child: Text(
              _initials(name),
              style: const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  style: TextStyle(
                    color:
                        Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  department,
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle
    extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        left: 4,
        bottom: 10,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight:
              FontWeight.w600,
          color:
              Colors.grey.shade600,
        ),
      ),
    );
  }
}

class _MoreTile
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? titleColor;

  const _MoreTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: Theme.of(context)
          .colorScheme
          .surface,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(16),
            border: Border.all(
              color:
                  Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration:
                    BoxDecoration(
                  color: (iconColor ??
                          Theme.of(context)
                              .colorScheme
                              .primary)
                      .withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  icon,
                  color: iconColor ??
                      Theme.of(context)
                          .colorScheme
                          .primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w600,
                        color:
                            titleColor,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            Colors.grey
                                .shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color:
                    Colors.grey.shade500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
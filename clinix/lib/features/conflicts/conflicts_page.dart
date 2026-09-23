import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../providers/sync_providers.dart';
import 'conflict_details_page.dart';

class ConflictsPage extends ConsumerStatefulWidget {
  const ConflictsPage({super.key});

  @override
  ConsumerState<ConflictsPage> createState() =>
      _ConflictsPageState();
}

class _ConflictsPageState
    extends ConsumerState<ConflictsPage> {
  List<SyncConflict> _conflicts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConflicts();
  }

  Future<void> _loadConflicts() async {
    final repository =
        ref.read(conflictRepositoryProvider);

    final conflicts = await repository.getConflicts();

    if (!mounted) return;

    setState(() {
      _conflicts = conflicts
          .where(
            (conflict) => conflict.status == 'PENDING',
          )
          .toList();
      _loading = false;
    });
  }

  Future<void> _openConflict(
    SyncConflict conflict,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConflictDetailsPage(
          conflict: conflict,
        ),
      ),
    );

    _loadConflicts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Conflicts'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _conflicts.isEmpty
              ? const Center(
                  child: Text(
                    'No conflicts',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF667494),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _conflicts.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final conflict = _conflicts[index];

                    return _ConflictCard(
                      conflict: conflict,
                      onTap: () =>
                          _openConflict(conflict),
                    );
                  },
                ),
    );
  }
}

class _ConflictCard extends StatelessWidget {
  final SyncConflict conflict;
  final VoidCallback onTap;

  const _ConflictCard({
    required this.conflict,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: Color(0xFFE3E8F0),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF3E0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFEF8C00),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${conflict.entityType} ${conflict.entityId}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF152A5B),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Your version ${conflict.clientVersion} '
                      '• Server version ${conflict.serverVersion}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF667494),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF9AA5B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
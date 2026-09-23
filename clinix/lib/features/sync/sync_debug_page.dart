import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../providers/sync_providers.dart';

class SyncDebugPage extends ConsumerStatefulWidget {
  const SyncDebugPage({super.key});

  @override
  ConsumerState<SyncDebugPage> createState() =>
      _SyncDebugPageState();
}

class _SyncDebugPageState
    extends ConsumerState<SyncDebugPage> {
  List<SyncOperation> _operations = [];
  bool _loading = true;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _loadOperations();
  }

  Future<void> _loadOperations() async {
    final repository =
        ref.read(syncRepositoryProvider);

    final operations =
        await repository.getAllOperations();

    if (!mounted) return;

    setState(() {
      _operations = operations;
      _loading = false;
    });
  }

  Future<void> _runSync() async {
    if (_syncing) return;

    setState(() {
      _syncing = true;
    });

    try {
      final syncEngine =
          ref.read(syncEngineProvider);

      await syncEngine.sync();

      await _loadOperations();
    } finally {
      if (mounted) {
        setState(() {
          _syncing = false;
        });
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return const Color(0xFF1A9B5F);

      case 'FAILED':
        return const Color(0xFFE5484D);

      case 'CONFLICT':
        return const Color(0xFFEF8C00);

      case 'SYNCING':
        return const Color(0xFF147DE5);

      case 'PENDING':
        return const Color(0xFF667494);

      default:
        return const Color(0xFF667494);
    }
  }

  Color _statusBackground(String status) {
    switch (status) {
      case 'COMPLETED':
        return const Color(0xFFEAF8F1);

      case 'FAILED':
        return const Color(0xFFFFEEEE);

      case 'CONFLICT':
        return const Color(0xFFFFF3E0);

      case 'SYNCING':
        return const Color(0xFFEAF4FF);

      case 'PENDING':
        return const Color(0xFFF1F3F7);

      default:
        return const Color(0xFFF1F3F7);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Sync Debug',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF152A5B),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _syncing
                ? null
                : _runSync,
            tooltip: 'Sync Now',
            icon: _syncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.sync,
                    color: Color(0xFF147DE5),
                  ),
          ),
          IconButton(
            onPressed: _loadOperations,
            tooltip: 'Refresh',
            icon: const Icon(
              Icons.refresh,
              color: Color(0xFF147DE5),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _operations.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadOperations,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: _operations.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 12),
                    itemBuilder: (
                      context,
                      index,
                    ) {
                      final operation =
                          _operations[index];

                      return _buildOperationCard(
                        operation,
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildOperationCard(
    SyncOperation operation,
  ) {
    final statusColor =
        _statusColor(operation.status);

    final statusBackground =
        _statusBackground(operation.status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE3E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  operation.operationType,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF152A5B),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusBackground,
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Text(
                  operation.status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _infoRow(
            'Entity',
            operation.entityType,
          ),
          _infoRow(
            'ID',
            operation.entityId,
          ),
          _infoRow(
            'Retries',
            operation.retryCount.toString(),
          ),
          _infoRow(
            'Base Version',
            operation.baseVersion?.toString() ??
                'None',
          ),
          const SizedBox(height: 12),
          const Text(
            'Operation ID',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF667494),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            operation.operationId,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF152A5B),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Payload',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF667494),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Text(
              operation.payload,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Color(0xFF152A5B),
              ),
            ),
          ),
          if (operation.lastError != null &&
              operation.lastError!.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Last Error',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF667494),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              operation.lastError!,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFE5484D),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 7,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF667494),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF152A5B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _loadOperations,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 220),
          Center(
            child: Text(
              'No sync operations',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF667494),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
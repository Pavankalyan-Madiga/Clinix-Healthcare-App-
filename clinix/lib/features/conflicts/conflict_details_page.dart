import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/network/api_client.dart';
import '../../providers/sync_providers.dart';

class ConflictDetailsPage extends ConsumerStatefulWidget {
  final SyncConflict conflict;

  const ConflictDetailsPage({
    super.key,
    required this.conflict,
  });

  @override
  ConsumerState<ConflictDetailsPage> createState() =>
      _ConflictDetailsPageState();
}

class _ConflictDetailsPageState
    extends ConsumerState<ConflictDetailsPage> {
  bool _resolving = false;

  Map<String, dynamic>? get _clientPayload {
    final payload = widget.conflict.clientPayload;

    if (payload == null || payload.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(payload);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}

    return null;
  }

  Map<String, dynamic>? get _serverPayload {
    final payload = widget.conflict.serverPayload;

    if (payload == null || payload.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(payload);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}

    return null;
  }

  Future<void> _keepMyChanges() async {
    final payload = _clientPayload;

    if (payload == null) {
      _showError('Your changes are not available.');
      return;
    }

    await _resolveLocalChoice(
      resolution: 'KEEP_LOCAL',
      payload: payload,
      sendToServer: true,
    );
  }

  Future<void> _keepServerChanges() async {
    final payload = _serverPayload;

    if (payload == null) {
      _showError('Server changes are not available.');
      return;
    }

    await _resolveLocalChoice(
      resolution: 'KEEP_SERVER',
      payload: payload,
      sendToServer: false,
    );
  }

  Future<void> _resolveLocalChoice({
    required String resolution,
    required Map<String, dynamic> payload,
    required bool sendToServer,
  }) async {
    if (_resolving) {
      return;
    }

    setState(() {
      _resolving = true;
    });

    try {
      final conflictResolver =
          ref.read(conflictResolverProvider);

      if (sendToServer) {
        final apiClient =
            ref.read(apiClientProvider);

        final response =
            await apiClient.resolveConflict(
          operationId:
              widget.conflict.operationId,
          entityType:
              widget.conflict.entityType,
          entityId:
              widget.conflict.entityId,
          payload: payload,
          baseVersion:
              widget.conflict.serverVersion,
          resolution: resolution,
        );

        final serverVersion =
            response['server_version'] as int;

        await conflictResolver.applyServerPayload(
          operationId:
              widget.conflict.operationId,
          entityType:
              widget.conflict.entityType,
          entityId:
              widget.conflict.entityId,
          payload: payload,
          serverVersion: serverVersion,
        );
      } else {
        await conflictResolver.applyServerPayload(
          operationId:
              widget.conflict.operationId,
          entityType:
              widget.conflict.entityType,
          entityId:
              widget.conflict.entityId,
          payload: payload,
          serverVersion:
              widget.conflict.serverVersion,
        );
      }

      final conflictRepository =
          ref.read(conflictRepositoryProvider);

      await conflictRepository.resolveConflict(
        widget.conflict.operationId,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resolution == 'KEEP_LOCAL'
                ? 'Your changes were kept'
                : 'Server changes were kept',
          ),
        ),
      );

      Navigator.pop(context);
    } on ConflictException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _resolving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'The record changed again: ${error.message}',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _resolving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to resolve conflict: $error',
          ),
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientPayload = _clientPayload;
    final serverPayload = _serverPayload;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Resolve Conflict',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF152A5B),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildVersionRow(),
          const SizedBox(height: 24),
          _buildChangesCard(
            title: 'Your Changes',
            icon: Icons.phone_android,
            payload: clientPayload,
          ),
          const SizedBox(height: 14),
          _buildChangesCard(
            title: 'Server Changes',
            icon: Icons.cloud_outlined,
            payload: serverPayload,
          ),
          const SizedBox(height: 28),
          _buildActions(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7EA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFFE2B5),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFEF8C00),
            size: 30,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Conflict Detected',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF152A5B),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${widget.conflict.entityType} '
                  '${widget.conflict.entityId}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF667494),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionRow() {
    return Row(
      children: [
        Expanded(
          child: _buildVersionCard(
            title: 'Your Version',
            version:
                widget.conflict.clientVersion,
            icon: Icons.phone_android,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildVersionCard(
            title: 'Server Version',
            version:
                widget.conflict.serverVersion,
            icon: Icons.cloud_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildVersionCard({
    required String title,
    required int version,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE3E8F0),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(0xFF147DE5),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF667494),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'v$version',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF152A5B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangesCard({
    required String title,
    required IconData icon,
    required Map<String, dynamic>? payload,
  }) {
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
              Icon(
                icon,
                color: const Color(0xFF147DE5),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF152A5B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (payload == null || payload.isEmpty)
            const Text(
              'No payload available',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF667494),
              ),
            )
          else
            ...payload.entries.map(
              (entry) => _buildPayloadRow(
                entry.key,
                entry.value,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPayloadRow(
    String key,
    dynamic value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              _formatKey(key),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF667494),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? '-',
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

  String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}'
                  '${word.substring(1)}',
        )
        .join(' ');
  }

  Widget _buildActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed:
                _resolving ? null : _keepMyChanges,
            style: FilledButton.styleFrom(
              minimumSize:
                  const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Keep My Changes',
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed:
                _resolving
                    ? null
                    : _keepServerChanges,
            style: OutlinedButton.styleFrom(
              minimumSize:
                  const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(16),
              ),
              side: const BorderSide(
                color: Color(0xFFD8DEE8),
              ),
            ),
            child: const Text(
              'Keep Server Changes',
            ),
          ),
        ),
      ],
    );
  }
}
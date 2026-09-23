class SyncConflictInfo {
  final String operationId;
  final String entityType;
  final String entityId;
  final int clientVersion;
  final int serverVersion;
  final Map<String, dynamic>? clientPayload;
  final Map<String, dynamic>? serverPayload;

  const SyncConflictInfo({
    required this.operationId,
    required this.entityType,
    required this.entityId,
    required this.clientVersion,
    required this.serverVersion,
    this.clientPayload,
    this.serverPayload,
  });

  factory SyncConflictInfo.fromJson(
    Map<String, dynamic> json,
  ) {
    final clientPayload = json['client_payload'];
    final serverPayload = json['server_payload'];

    return SyncConflictInfo(
      operationId: json['operation_id'],
      entityType: json['entity_type'],
      entityId: json['entity_id'],
      clientVersion: json['client_version'],
      serverVersion: json['server_version'],
      clientPayload:
          clientPayload is Map<String, dynamic>
              ? clientPayload
              : null,
      serverPayload:
          serverPayload is Map<String, dynamic>
              ? serverPayload
              : null,
    );
  }
}
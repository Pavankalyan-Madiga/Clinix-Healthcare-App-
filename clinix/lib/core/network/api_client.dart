import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl;
  final http.Client _client;

  ApiClient({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      final responseBody = _decodeResponse(response.body);

      if (response.statusCode == 409) {
        final detail = responseBody['detail'];

        if (detail is Map<String, dynamic>) {
          throw ConflictException(
            response.statusCode,
            'Sync conflict detected',
            detail,
          );
        }
      }

      throw ApiException(
        response.statusCode,
        response.body,
      );
    }

    return _decodeResponse(response.body);
  }

  Future<Map<String, dynamic>> uploadFile({
    required String path,
    required File file,
    String fieldName = 'file',
  }) async {
    if (!await file.exists()) {
      throw const ApiException(
        404,
        'File does not exist',
      );
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl$path'),
    );

    request.files.add(
      await http.MultipartFile.fromPath(
        fieldName,
        file.path,
      ),
    );

    final streamedResponse = await _client.send(request);

    final response = await http.Response.fromStream(
      streamedResponse,
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw ApiException(
        response.statusCode,
        response.body,
      );
    }

    return _decodeResponse(response.body);
  }

  Future<Map<String, dynamic>> resolveConflict({
    required String operationId,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
    required int baseVersion,
    required String resolution,
  }) async {
    return post(
      '/sync/resolve',
      {
        'operation_id': operationId,
        'entity_type': entityType,
        'entity_id': entityId,
        'payload': payload,
        'base_version': baseVersion,
        'resolution': resolution,
      },
    );
  }

  Future<Map<String, dynamic>> get(
    String path,
  ) async {
    final response = await _client.get(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw ApiException(
        response.statusCode,
        response.body,
      );
    }

    return _decodeResponse(response.body);
  }

  Future<List<Map<String, dynamic>>> getChanges() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/sync/changes?since=0'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw ApiException(
        response.statusCode,
        response.body,
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const ApiException(
        500,
        'Invalid changes response',
      );
    }

    final changes = decoded['changes'];

    if (changes is! List) {
      return [];
    }

    return changes
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Map<String, dynamic> _decodeResponse(
    String body,
  ) {
    final decoded = jsonDecode(body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw const ApiException(
      500,
      'Invalid server response',
    );
  }

  void dispose() {
    _client.close();
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(
    this.statusCode,
    this.message,
  );

  @override
  String toString() {
    return 'ApiException: $statusCode - $message';
  }
}

class ConflictException extends ApiException {
  final Map<String, dynamic> conflict;

  const ConflictException(
    super.statusCode,
    super.message,
    this.conflict,
  );

  Map<String, dynamic>? get serverPayload {
    final payload = conflict['server_payload'];

    if (payload is Map<String, dynamic>) {
      return payload;
    }

    return null;
  }
}
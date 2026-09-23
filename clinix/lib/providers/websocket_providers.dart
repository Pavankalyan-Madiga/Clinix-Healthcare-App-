import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/websocket/websocket_event_handler.dart';
import '../core/websocket/websocket_service.dart';
import 'database_providers.dart';
import 'sync_providers.dart';

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService(url: 'ws://172.29.180.139:8000/ws');

  ref.onDispose(service.dispose);

  return service;
});

final webSocketEventHandlerProvider = Provider<WebSocketEventHandler>((ref) {
  final database = ref.watch(databaseProvider);
  final webSocketService = ref.watch(webSocketServiceProvider);
  final apiClient = ref.watch(apiClientProvider);

  final handler = WebSocketEventHandler(database, webSocketService, apiClient);

  handler.start();

  ref.onDispose(handler.dispose);

  return handler;
});

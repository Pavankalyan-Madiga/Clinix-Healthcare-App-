import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  final String url;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;

  bool _manuallyDisconnected = false;
  bool _connecting = false;

  final StreamController<Map<String, dynamic>>
      _eventController =
      StreamController<Map<String, dynamic>>.broadcast();

  final StreamController<void>
      _reconnectedController =
      StreamController<void>.broadcast();

  WebSocketService({
    required this.url,
  });

  Stream<Map<String, dynamic>> get events =>
      _eventController.stream;

  Stream<void> get reconnected =>
      _reconnectedController.stream;

  bool get isConnected => _channel != null;

  Future<void> connect() async {
    if (_connecting || isConnected) {
      return;
    }

    _manuallyDisconnected = false;
    _connecting = true;

    print('[WebSocket] Connecting to $url');

    try {
      final channel = WebSocketChannel.connect(
        Uri.parse(url),
      );

      _channel = channel;

      await channel.ready;

      print('[WebSocket] Connected');

      _subscription = channel.stream.listen(
        _handleMessage,
        onError: (error) {
          print('[WebSocket] Error: $error');
          _handleDisconnect();
        },
        onDone: () {
          print('[WebSocket] Disconnected');
          _handleDisconnect();
        },
        cancelOnError: true,
      );

      _reconnectedController.add(null);
    } catch (error) {
      print(
        '[WebSocket] Connection failed: $error',
      );

      _channel = null;
      _scheduleReconnect();
    } finally {
      _connecting = false;
    }
  }

  void _handleMessage(dynamic message) {
    print(
      '[WebSocket] Message received: $message',
    );

    try {
      final decoded =
          jsonDecode(message.toString());

      if (decoded is Map<String, dynamic>) {
        _eventController.add(decoded);
      }
    } catch (error) {
      print(
        '[WebSocket] Invalid message: $error',
      );
    }
  }

  void _handleDisconnect() {
    _subscription?.cancel();
    _subscription = null;
    _channel = null;

    if (!_manuallyDisconnected) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_manuallyDisconnected ||
        _reconnectTimer?.isActive == true) {
      return;
    }

    print(
      '[WebSocket] Reconnecting in 3 seconds',
    );

    _reconnectTimer = Timer(
      const Duration(seconds: 3),
      () {
        _reconnectTimer = null;
        connect();
      },
    );
  }

  Future<void> disconnect() async {
    _manuallyDisconnected = true;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    await _subscription?.cancel();
    _subscription = null;

    await _channel?.sink.close();
    _channel = null;

    print(
      '[WebSocket] Disconnected manually',
    );
  }

  Future<void> dispose() async {
    await disconnect();
    await _eventController.close();
    await _reconnectedController.close();
  }
}
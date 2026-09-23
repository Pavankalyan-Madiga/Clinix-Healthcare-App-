import 'package:flutter/widgets.dart';

import '../websocket/websocket_service.dart';

class AppLifecycleObserver
    with WidgetsBindingObserver {
  final WebSocketService _webSocketService;

  AppLifecycleObserver(
    this._webSocketService,
  );

  void start() {
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.resumed) {
      _handleResume();
    }
  }

  Future<void> _handleResume() async {
    await _webSocketService.connect();
  }
}
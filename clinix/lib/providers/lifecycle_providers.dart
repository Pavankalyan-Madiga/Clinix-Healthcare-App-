import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/lifecycle/app_lifecycle_observer.dart';
import 'websocket_providers.dart';

final appLifecycleObserverProvider =
    Provider<AppLifecycleObserver>((ref) {
  final webSocketService =
      ref.watch(webSocketServiceProvider);

  final observer = AppLifecycleObserver(
    webSocketService,
  );

  observer.start();

  ref.onDispose(observer.dispose);

  return observer;
});
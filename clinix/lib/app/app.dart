import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/lifecycle_providers.dart';
import '../providers/sync_providers.dart';
import '../providers/websocket_providers.dart';
import 'router.dart';
import 'theme.dart';

class ClinixApp extends ConsumerStatefulWidget {
  const ClinixApp({super.key});

  @override
  ConsumerState<ClinixApp> createState() =>
      _ClinixAppState();
}

class _ClinixAppState extends ConsumerState<ClinixApp> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) async {
        ref.read(syncEngineProvider).start();

        ref.read(webSocketEventHandlerProvider);

        ref.read(appLifecycleObserverProvider);

        ref
            .read(webSocketServiceProvider)
            .connect();

        final conflicts =
            await ref
                .read(conflictRepositoryProvider)
                .getConflicts();

        print(
          '[Conflict] Found '
          '${conflicts.length} local conflicts',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Clinix',
      theme: ClinixTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
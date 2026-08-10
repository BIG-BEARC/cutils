// Wave A1 — medium-severity fixes for `log_interceptor`.
//
// Strict TDD: each test was first observed to FAIL for the right reason,
// then the minimal fix was applied under `lib/log_collector/log_interceptor.dart`.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cutils/log_collector/log_collector.dart';
import 'package:cutils/log_collector/log_interceptor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ---------- A1-interceptor: restore PlatformDispatcher.onError ----------
  group('ExceptionInterceptor handler restoration', () {
    test('restores the original PlatformDispatcher.onError on stop (not null)',
        () async {
      final originalPlatformOnError = PlatformDispatcher.instance.onError;

      // Install a sentinel handler that we expect to be restored after stop().
      bool sentinelCalled = false;
      bool sentinelHandler(Object error, StackTrace stack) {
        sentinelCalled = true;
        return true;
      }

      PlatformDispatcher.instance.onError = sentinelHandler;

      try {
        final interceptor = ExceptionInterceptor();
        await interceptor.start(logCollector);

        // While started, the interceptor installs its own handler.
        expect(
          identical(PlatformDispatcher.instance.onError, sentinelHandler),
          isFalse,
          reason: 'Interceptor should install its own handler while started.',
        );

        await interceptor.stop();

        // After stop the sentinel must be restored, not nulled out.
        expect(
          identical(PlatformDispatcher.instance.onError, sentinelHandler),
          isTrue,
          reason: 'PlatformDispatcher.instance.onError must be restored to the '
              'original sentinel, not set to null.',
        );

        // Prove it is actually wired up: dispatch an error to the restored
        // handler and verify the sentinel fires.
        PlatformDispatcher.instance.onError
            ?.call(StateError('probe'), StackTrace.current);
        expect(sentinelCalled, isTrue);
      } finally {
        PlatformDispatcher.instance.onError = originalPlatformOnError;
      }
    });

    test('restores the original FlutterError.onError on stop', () async {
      final originalFlutterOnError = FlutterError.onError;

      int sentinelCalls = 0;
      void sentinelHandler(FlutterErrorDetails details) {
        sentinelCalls++;
      }

      FlutterError.onError = sentinelHandler;

      try {
        final interceptor = ExceptionInterceptor();
        await interceptor.start(logCollector);
        await interceptor.stop();

        expect(
          identical(FlutterError.onError, sentinelHandler),
          isTrue,
          reason: 'FlutterError.onError must be restored to the original.',
        );

        // Prove the restored handler is wired up: dispatch an error.
        FlutterError.onError?.call(
          FlutterErrorDetails(
              exception: Exception('probe'), stack: StackTrace.current),
        );
        expect(sentinelCalls, 1);
      } finally {
        FlutterError.onError = originalFlutterOnError;
      }
    });
  });
}

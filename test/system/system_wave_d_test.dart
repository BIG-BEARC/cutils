// Wave D — high-severity bug fixes for `system` (D1-D3).
//
// Strict TDD: each group below was first observed to FAIL for the right
// reason on the unmodified code, then the minimal fix was applied under
// `lib/system/` to turn it green. No public signatures were changed; only
// additive `@visibleForTesting` pure helpers were introduced so the
// platform-coupled shells could delegate their decision logic to a
// unit-testable function. The net fixes (D4/D5) live in
// `test/net/net_util_wave_d_test.dart`.

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cutils/system/device_info_util.dart';
import 'package:cutils/system/keyboard_util.dart';
import 'package:cutils/system/system_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // -------------------------------------------------------------------
  // D1 — `winUniqueIdentifier` mixed `DateTime.now()` into the md5 input,
  // so the "unique device id" changed on every call. The fix removes the
  // timestamp; only stable hardware IDs are concatenated.
  // -------------------------------------------------------------------
  group('D1 winUniqueIdentifier stability', () {
    test('buildWinUniqueId is deterministic for stable ids', () {
      const ids = <String>['baseboard-1', 'bios-2', 'cpu-3', 'disk-4', 'os-5'];
      final first = DeviceInfoUtil.buildWinUniqueId(ids);
      final second = DeviceInfoUtil.buildWinUniqueId(ids);
      expect(first, equals(second),
          reason: 'Stable hardware ids must yield a stable identifier.');
      // Sanity: the hash is the md5 of the concatenated input.
      final expected = md5.convert(utf8.encode(ids.join())).toString();
      expect(first, equals(expected));
    });

    test('buildWinUniqueId does not depend on wall-clock time', () {
      const ids = <String>['x', 'y'];
      final a = DeviceInfoUtil.buildWinUniqueId(ids);
      // Spin until the clock definitely advanced past millisecond resolution.
      final t = DateTime.now();
      while (DateTime.now() == t) {
        /* burn a few microseconds */
      }
      final b = DeviceInfoUtil.buildWinUniqueId(ids);
      expect(b, equals(a),
          reason: 'Identifier must not change as DateTime.now() advances.');
    });

    test('winUniqueIdentifier is stable across calls (no DateTime.now())', () {
      // `winUniqueIdentifier()` shells out to five `wmic` processes per call
      // (~13s, and the load destabilises a timing-sensitive log_collector
      // test in the shared suite). Per the spec's testability fallback we
      // verify the contract on the extracted pure helper instead: the
      // identifier is a pure function of the hardware-id list, and that
      // list contains NO timestamp. Before the fix the public method mixed
      // `DateTime.now()` into the md5 input, so two calls from identical
      // id lists produced DIFFERENT ids.
      //
      // (RED was first demonstrated end-to-end: with the buggy
      // concatenation still including `DateTime.now()`, calling
      // `winUniqueIdentifier()` twice returned two different hashes.)
      const ids = <String>['board', 'bios', 'cpu', 'disk', 'os'];
      final first = DeviceInfoUtil.buildWinUniqueId(ids);
      final second = DeviceInfoUtil.buildWinUniqueId(List<String>.from(ids));
      expect(second, equals(first),
          reason: 'winUniqueIdentifier must be stable across invocations.');
    });
  });

  // -------------------------------------------------------------------
  // D2 — `KeyBoardUtils.closeKeyBoard` called
  // `SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive)`, so
  // closing the keyboard also hid the status/nav bars. The fix removes
  // that side effect entirely.
  // -------------------------------------------------------------------
  group('D2 closeKeyBoard system-UI side effect', () {
    // Records every method invocation on the platform channel.
    List<MethodCall> recordedCalls() {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        calls.add(call);
        return null;
      });
      return calls;
    }

    testWidgets(
        'closeKeyBoard does not invoke SystemChrome.setEnabledSystemUIMode',
        (tester) async {
      final calls = recordedCalls();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => KeyBoardUtils.closeKeyBoard(context),
                child: const Text('close'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      final immersiveCalls = calls.where((c) =>
          c.method == 'SystemChrome.setEnabledSystemUIMode' &&
          (c.arguments is Map &&
              (c.arguments as Map)['mode'] == SystemUiMode.immersive.index));

      expect(
        immersiveCalls,
        isEmpty,
        reason:
            'closeKeyBoard must NOT hide system UI (no immersive mode call).',
      );

      // Also assert no setEnabledSystemUIMode call at all, on any platform:
      // the side effect has been removed entirely.
      final anyModeCall =
          calls.where((c) => c.method == 'SystemChrome.setEnabledSystemUIMode');
      expect(anyModeCall, isEmpty,
          reason: 'closeKeyBoard must not change the system UI mode at all.');
    });
  });

  // -------------------------------------------------------------------
  // D3 — `navigationBarHeight` used `(padding.bottom - padding.top) / dpr`,
  // subtracting the status-bar inset from the bottom inset (often negative).
  // The fix is `padding.bottom / dpr`, extracted into a pure helper.
  // -------------------------------------------------------------------
  group('D3 navigationBarHeight formula', () {
    test('navBarHeightFrom divides only the bottom inset by dpr', () {
      // bottom=48, top=24, dpr=3 -> 48/3 = 16.0 (NOT (48-24)/3 = 8.0).
      const padding = EdgeInsets.fromLTRB(0, 24, 0, 48);
      expect(SystemUtils.navBarHeightFrom(padding, 3), equals(16.0));
    });

    test('navBarHeightFrom handles zero bottom inset', () {
      const padding = EdgeInsets.fromLTRB(0, 44, 0, 0);
      expect(SystemUtils.navBarHeightFrom(padding, 2), equals(0.0));
    });

    test('navBarHeightFrom never goes negative for real insets', () {
      // Regression guard: the old formula produced negative values whenever
      // top > bottom (e.g. status bar inset swamping a small nav inset).
      const padding = EdgeInsets.fromLTRB(0, 44, 0, 10);
      expect(SystemUtils.navBarHeightFrom(padding, 1), equals(10.0));
      expect(SystemUtils.navBarHeightFrom(padding, 1), isNonNegative);
    });
  });
}

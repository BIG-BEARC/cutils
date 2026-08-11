// Wave D — high-severity bug fixes for `net` (D4 + D5).
//
// Strict TDD: each case below was first observed to FAIL for the right
// reason on the unmodified code, then the minimal fix was applied under
// `lib/net/net_util.dart` to turn it green. No public signatures were
// changed; one additive `@visibleForTesting` pure helper
// (`NetUtil.isConnectedFromResults`) was introduced so the connectivity
// decision is unit-testable without a live platform plugin or a mocked
// `dart:io Platform`.
//
// D4: `Platform.isWindows -> return true` assumed desktops are always
//     online. The fix runs the same connectivity path on Windows, so the
//     decision no longer special-cases any platform.
// D5: only `result[0]` was inspected (dropping wifi+vpn), and bluetooth
//     was treated as disconnected. The fix iterates the whole list and
//     treats "any result != none" as connected (bluetooth included).

import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:cutils/net/net_util.dart';

void main() {
  group('D4/D5 NetUtil.isConnectedFromResults', () {
    test('D5 wifi+vpn multi-result is connected', () {
      expect(
        NetUtil.isConnectedFromResults(
          [ConnectivityResult.wifi, ConnectivityResult.vpn],
        ),
        isTrue,
        reason: 'A list with wifi must be online even if not at index 0.',
      );
    });

    test('D5 bluetooth is treated as connected', () {
      expect(
        NetUtil.isConnectedFromResults([ConnectivityResult.bluetooth]),
        isTrue,
        reason: 'Bluetooth must be treated as connected per project policy.',
      );
    });

    test('D5 none is disconnected', () {
      expect(
        NetUtil.isConnectedFromResults([ConnectivityResult.none]),
        isFalse,
      );
    });

    test('D5 empty list is disconnected', () {
      expect(NetUtil.isConnectedFromResults(<ConnectivityResult>[]), isFalse);
    });

    test('D5 vpn-only is connected', () {
      expect(
        NetUtil.isConnectedFromResults([ConnectivityResult.vpn]),
        isTrue,
      );
    });

    test('D4 mixed list containing none alongside wifi stays connected', () {
      expect(
        NetUtil.isConnectedFromResults(
          [ConnectivityResult.none, ConnectivityResult.wifi],
        ),
        isTrue,
        reason:
            'A single live result must keep the device online regardless of '
            'platform or result ordering.',
      );
    });

    test('D4 none-only is disconnected (Windows no longer hardcodes online)',
        () {
      // Before the fix `isConnectedNet` short-circuited `Platform.isWindows`
      // to `return true`. The pure decision now says a `none`-only list is
      // offline on every platform, Windows included.
      expect(
        NetUtil.isConnectedFromResults([ConnectivityResult.none]),
        isFalse,
        reason: 'Windows with no connectivity must report offline.',
      );
    });
  });
}

// Dart imports:
import 'dart:async';

// Package imports:
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:cutils/storage/sp_util.dart';

/// Wave G — SpUtil 日志 PII 泄露回归测试。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 每个测试前重置 SpUtil 单例持有的 SharedPreferences 缓存，并装填 mock 初始值，
  // 保证 getString 等读到的就是本测试塞入的值。
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('G4: getString/putString do NOT log the secret value (key-only logging)',
      () async {
    const secret = 'SUPER_SECRET_TOKEN_42';
    // 通过 mock 让 sp 读到 secret；同时 putString 也会落地到 mock。
    SharedPreferences.setMockInitialValues({'token': secret});
    await spUtil.init();

    final logged = <String>[];
    // PrettyPrinter 的 ConsoleOutput 最终调用顶层 print；在 zone 内拦截即可捕获。
    await runZoned(
      () async {
        await spUtil.putString('token', secret);
        final value = spUtil.getString('token');
        expect(value, equals(secret));
      },
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) {
          logged.add(line);
        },
      ),
    );

    // 关键断言：日志里不得出现敏感值本体。
    final leaked = logged.where((line) => line.contains(secret)).toList();
    expect(
      leaked,
      isEmpty,
      reason: 'PII/secret value must not be interpolated into log output. '
          'Leaking lines: $leaked',
    );
  });
}

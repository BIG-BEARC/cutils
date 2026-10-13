// SpUtils.init 自愈路径契约 — landed per review finding R6② (log-spy 方案).
//
// 覆盖三条 init 行为契约（log-spy 局限说明：sp_backup 的日志只在
// `dart:io` 文件路径上产生，非 Windows 宿主上 backupSpFile / restoreSpFile
// 是纯 no-op、无可拦截输出，故本文件不架 print 拦截，直接断言行为契约；
// Windows 真实文件行为由 sp_backup_io_test.dart 以路径参数化全量覆盖）：
// - I1 init 失败 rethrow 保真：底层 store 的原错误对象原样上抛（不被
//   catchError 包装 / 替换），且单例不进入已初始化态；
// - I2 失败后可重试：失败路径清空 in-flight Future，换回正常 store 后
//   不调 reset 也能直接重试成功并读出数据；
// - I3 非 Windows 平台门冒烟：backupSpFile / restoreSpFile 入口 no-op
//   不抛（Platform.isWindows 早退契约）。

// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter_test/flutter_test.dart';

// Package imports:
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

// Project imports:
import 'package:cutils/storage/sp_backup_io.dart' as sp_backup;
import 'package:cutils/storage/sp_util.dart';

/// 注入式故障 store：数据方法调用一律抛同一个预建错误，
/// 便于用 `same()` 断言错误对象原样穿透（rethrow 未被包装）。
/// 必须 extends（plugin_platform_interface 的 token 校验拒绝 implements
/// 冒充）；数据方法为抽象成员，统一经 noSuchMethod 抛错。
class _ThrowingStore extends SharedPreferencesStorePlatform {
  final error = StateError('injected store failure');

  @override
  dynamic noSuchMethod(Invocation invocation) => throw error;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'k': 'v0'});
    SpUtils().resetInstanceForTesting();
  });

  group('I1 init 失败 rethrow 保真', () {
    test('底层原错误对象原样上抛，单例保持未初始化', () async {
      final store = _ThrowingStore();
      SharedPreferencesStorePlatform.instance = store;

      Object? caught;
      await SpUtils().init().catchError((Object e) {
        caught = e;
        return false;
      });

      // 保真断言：与注入 store 预建错误做同一性比较——init 的失败路径
      // 只 rethrow、不包装，捕获到的必须是同一个对象。
      expect(caught, same(store.error));
      expect(SpUtils().isInitialized(), isFalse);
    });
  });

  group('I2 失败后可重试', () {
    test('失败清空 in-flight，换回正常 store 后无需 reset 直接重试成功', () async {
      SharedPreferencesStorePlatform.instance = _ThrowingStore();
      await SpUtils().init().catchError((Object e) => false);
      expect(SpUtils().isInitialized(), isFalse);

      // 换回正常 mock store（不调 resetInstanceForTesting——重试语义
      // 依赖失败路径已自行清空 in-flight Future）。
      SharedPreferences.setMockInitialValues({'retry.k': true});
      final ok = await SpUtils().init();

      expect(ok, isTrue);
      expect(SpUtils().isInitialized(), isTrue);
      // getBool 是同步读（init 已确保 _prefs 就绪），无需 await。
      expect(SpUtils().getBool('retry.k'), isTrue);
    });
  });

  group('I3 非 Windows 平台门冒烟', () {
    test('backupSpFile / restoreSpFile no-op 不抛', () async {
      await sp_backup.backupSpFile();
      await sp_backup.restoreSpFile();
      // 非 Windows 宿主上两个入口因 Platform.isWindows 早退而 no-op，
      // 走到这里不抛即通过；Windows 宿主会触达真实 SP 文件路径（有
      // 副作用），故仅非 Windows 宿主执行本冒烟。
      expect(Platform.isWindows, isFalse);
    }, skip: Platform.isWindows ? 'Windows 宿主会触达真实 SP 文件，跳过' : null);
  });
}

// Flutter imports:
import 'package:flutter_test/flutter_test.dart';

// Package imports:
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:cutils/storage/sp_util.dart';

/// Wave A2 — SpUtil 中危修复测试。
///
/// 覆盖项：
/// - A2-1: init 竞态——并发 init()/ensureInitialized() 共享同一个 in-flight
///   Future，SharedPreferences.getInstance() 只被调用一次。
/// - A2-2: putObject → putJsonable（保留 deprecated 别名转发）。
/// - A2-3: `.where((e) => e != null).cast<String>()` → `.whereType<String>()`。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // setMockInitialValues 同时会清空 SharedPreferences 插件内部的 _completer，
    // 保证下一次 getInstance() 走真正的读取路径。
    SharedPreferences.setMockInitialValues({});
    // 重置 SpUtil 单例缓存，保证每个测试都走「冷启动」路径。
    spUtil.resetInstanceForTesting();
  });

  group('A2-1 init race (single-flight)', () {
    test('concurrent init() calls all resolve to the same non-null instance',
        () async {
      final results = await Future.wait([
        spUtil.init(),
        spUtil.init(),
        spUtil.init(),
        spUtil.init(),
        spUtil.init(),
      ]);
      // 所有并发调用者必须拿到非空且同一个 SharedPreferences 实例。
      expect(results, everyElement(isNotNull));
      expect(results, everyElement(same(results.first)));
    });

    test('interleaved init()/ensureInitialized() resolve without exception',
        () async {
      await Future.wait([
        spUtil.ensureInitialized(),
        spUtil.init(),
        spUtil.ensureInitialized(),
      ]);
      expect(spUtil.isInitialized(), isTrue);
      expect(spUtil.getSp(), isNotNull);
    });

    test('after init resolves, a subsequent init() reuses the cached instance',
        () async {
      final first = await spUtil.init();
      // 第二次（warm 路径）应直接返回缓存的同一个实例，不再触发新的 getInstance。
      final second = await spUtil.init();
      expect(second, same(first));
    });
  });

  group('A2-2 putJsonable (renamed from putObject)', () {
    test('putJsonable stores an encodable object and round-trips via getObject',
        () async {
      await spUtil.init();
      final ok = await spUtil.putJsonable('user', {'name': 'alice', 'age': 30});
      expect(ok, isTrue);
      final loaded = spUtil.getObject<Map<String, dynamic>>('user', (m) => m);
      expect(loaded, isNotNull);
      expect(loaded!['name'], 'alice');
      expect(loaded['age'], 30);
    });

    test('deprecated putObject forwards to putJsonable (alias)', () async {
      await spUtil.init();
      // ignore: deprecated_member_use_from_same_package
      final ok = await spUtil.putObject('cfg', {'k': 1});
      expect(ok, isTrue);
      final loaded = spUtil.getObject<Map<String, dynamic>>('cfg', (m) => m);
      expect(loaded?['k'], 1);
    });
  });

  group('A2-3 whereType<String> modernization (putObjectList)', () {
    test('putObjectList stores only successfully-encoded items', () async {
      await spUtil.init();
      // Object() 无法被 json.encode → JsonUtils.encodeObj 返回 null
      // → 被 whereType<String>() 过滤掉。
      final unencodable = Object();
      final list = <Object>[
        {'a': 1},
        unencodable,
        {'b': 2},
      ];
      final ok = await spUtil.putObjectList('objs', list);
      expect(ok, isTrue);
      final stored = spUtil.getSp()!.getStringList('objs');
      expect(stored, isNotNull);
      expect(stored!, hasLength(2));
      expect(stored.first, contains('"a"'));
      expect(stored.last, contains('"b"'));
    });

    test('putObjectList with all-encodable list stores every item (regression)',
        () async {
      await spUtil.init();
      final list = <Object>[
        {'a': 1},
        {'b': 2},
      ];
      final ok = await spUtil.putObjectList('objs2', list);
      expect(ok, isTrue);
      final stored = spUtil.getSp()!.getStringList('objs2');
      expect(stored, hasLength(2));
    });
  });
}

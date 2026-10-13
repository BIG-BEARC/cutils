// Windows SP 备份恢复 — absorbed (as capability, rewritten) from
// saas_pos_smart_edition `lib/shared/utils/sp_manager.dart`.
//
// Strict TDD: written first. Deviations from the source on purpose:
// - restore validates the backup (JSON object) BEFORE touching the live
//   file — the source deleted/verified in a dangerous order;
// - restore failures keep the live file intact and never throw upward
//   (init's rethrow semantics stay untouched);
// - file ops are path-parameterized pure-ish functions so they can be
//   tested against a real temp directory (no platform mocking).

import 'dart:io';

import 'package:cutils/storage/sp_backup_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('cutils_sp_backup_');
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  group('V1 isValidSpJson（恢复前的备份有效性校验）', () {
    test('合法 JSON 对象为 true', () {
      expect(isValidSpJson('{"flutter.key":"v"}'), isTrue);
      expect(isValidSpJson('{}'), isTrue);
    });

    test('合法 JSON 但非对象（List / 标量）为 false', () {
      expect(isValidSpJson('[1,2]'), isFalse);
      expect(isValidSpJson('123'), isFalse);
      expect(isValidSpJson('"s"'), isFalse);
      expect(isValidSpJson('null'), isFalse);
    });

    test('坏 JSON / 空串为 false', () {
      expect(isValidSpJson('{bad'), isFalse);
      expect(isValidSpJson(''), isFalse);
    });
  });

  group('V2 backupToFile（live → backup）', () {
    test('live 存在时备份内容一致', () async {
      final live = File(p.join(tmp.path, 'shared_preferences.json'));
      await live.writeAsString('{"k":"v1"}');
      final backupPath = p.join(tmp.path, 'shared_preferences.json.bak');

      await backupToFile(livePath: live.path, backupPath: backupPath);

      expect(await File(backupPath).readAsString(), '{"k":"v1"}');
    });

    test('live 不存在时不创建 backup（首次启动语义）', () async {
      final livePath = p.join(tmp.path, 'shared_preferences.json');
      final backupPath = p.join(tmp.path, 'shared_preferences.json.bak');

      await backupToFile(livePath: livePath, backupPath: backupPath);

      expect(File(backupPath).existsSync(), isFalse);
    });

    test('重复备份覆盖旧 backup', () async {
      final live = File(p.join(tmp.path, 'shared_preferences.json'));
      final backupPath = p.join(tmp.path, 'shared_preferences.json.bak');
      await live.writeAsString('{"k":"v1"}');
      await backupToFile(livePath: live.path, backupPath: backupPath);
      await live.writeAsString('{"k":"v2"}');

      await backupToFile(livePath: live.path, backupPath: backupPath);

      expect(await File(backupPath).readAsString(), '{"k":"v2"}');
    });
  });

  group('V3 restoreFromFile（先校验后替换，失败保现场）', () {
    test('backup 有效 → live 被替换为备份内容', () async {
      final live = File(p.join(tmp.path, 'shared_preferences.json'));
      final backup = File(p.join(tmp.path, 'shared_preferences.json.bak'));
      await live.writeAsString('{corrupted');
      await backup.writeAsString('{"k":"good"}');

      await restoreFromFile(
        livePath: live.path,
        backupPath: backup.path,
      );

      expect(await live.readAsString(), '{"k":"good"}');
    });

    test('backup 无效 JSON → live 保持原内容不动', () async {
      final live = File(p.join(tmp.path, 'shared_preferences.json'));
      final backup = File(p.join(tmp.path, 'shared_preferences.json.bak'));
      await live.writeAsString('{"k":"original"}');
      await backup.writeAsString('{corrupted');

      await restoreFromFile(
        livePath: live.path,
        backupPath: backup.path,
      );

      expect(await live.readAsString(), '{"k":"original"}');
    });

    test('backup 是合法 JSON 但非对象 → live 保持原内容不动', () async {
      final live = File(p.join(tmp.path, 'shared_preferences.json'));
      final backup = File(p.join(tmp.path, 'shared_preferences.json.bak'));
      await live.writeAsString('{"k":"original"}');
      await backup.writeAsString('[1,2]');

      await restoreFromFile(
        livePath: live.path,
        backupPath: backup.path,
      );

      expect(await live.readAsString(), '{"k":"original"}');
    });

    test('backup 不存在 → live 不被创建/改动', () async {
      final livePath = p.join(tmp.path, 'shared_preferences.json');
      final backupPath = p.join(tmp.path, 'shared_preferences.json.bak');

      await restoreFromFile(livePath: livePath, backupPath: backupPath);

      expect(File(livePath).existsSync(), isFalse);
    });

    test('恢复成功后 backup 保留（供下次 init 成功路径再备份）', () async {
      final live = File(p.join(tmp.path, 'shared_preferences.json'));
      final backup = File(p.join(tmp.path, 'shared_preferences.json.bak'));
      await live.writeAsString('{corrupted');
      await backup.writeAsString('{"k":"good"}');

      await restoreFromFile(
        livePath: live.path,
        backupPath: backup.path,
      );

      expect(backup.existsSync(), isTrue);
    });

    test('IO 异常只记日志不向上抛——backup 目标目录不存在', () async {
      final live = File(p.join(tmp.path, 'shared_preferences.json'));
      await live.writeAsString('{"k":"v"}');

      // copy 到不存在的目录会抛 PathNotFoundException，契约要求吞掉不外抛
      await backupToFile(
        livePath: live.path,
        backupPath: p.join(tmp.path, 'no-such-dir', 'sp.bak'),
      );
    });

    test('IO 异常只记日志不向上抛——restore 回写目录不存在', () async {
      final backup = File(p.join(tmp.path, 'shared_preferences.json.bak'));
      await backup.writeAsString('{"k":"good"}');

      // 备份有效但回写目标目录不存在 → 抛 PathNotFoundException → 被吞
      await restoreFromFile(
        livePath: p.join(tmp.path, 'no-such-dir', 'sp.json'),
        backupPath: backup.path,
      );
    });
  });
}

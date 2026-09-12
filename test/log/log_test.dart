// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:cutils/log/log.dart';

void main() {
  group('logger 单例', () {
    test('顶层 logger 与 LoggerUtils() 是同一实例', () {
      expect(identical(logger, LoggerUtils()), isTrue);
    });
  });

  group('六个级别方法（debug 模式表征）', () {
    // 表征测试：debug 模式下调用不抛异常即视为通过。
    // 输出本身由 package:logger 的 PrettyPrinter 负责，不属于本封装的契约；
    // release 分支（kReleaseMode no-op）在 flutter test 的 debug 编译下
    // 不可达，不在此覆盖。
    test('t/d/i/w/e/f 带与不带 tag 均可调用', () {
      expect(() => logger.t('msg'), returnsNormally);
      expect(() => logger.t('msg', tag: 'T'), returnsNormally);
      expect(() => logger.d('msg'), returnsNormally);
      expect(() => logger.d('msg', tag: 'T'), returnsNormally);
      expect(() => logger.i('msg'), returnsNormally);
      expect(() => logger.i('msg', tag: 'T'), returnsNormally);
      expect(() => logger.w('msg'), returnsNormally);
      expect(() => logger.w('msg', tag: 'T'), returnsNormally);
      expect(() => logger.e('msg'), returnsNormally);
      expect(() => logger.e('msg', tag: 'T'), returnsNormally);
      expect(() => logger.f('msg'), returnsNormally);
      expect(() => logger.f('msg', tag: 'T'), returnsNormally);
    });

    test('error / stackTrace / time 透传不抛', () {
      final error = StateError('boom');
      final stack = StackTrace.current;
      final now = DateTime.now();
      expect(
        () => logger.e('msg',
            time: now, error: error, stackTrace: stack, tag: 'E'),
        returnsNormally,
      );
    });
  });
}

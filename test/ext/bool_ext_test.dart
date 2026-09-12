// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:cutils/ext/bool_ext.dart';

void main() {
  group('BoolExt.not / 逻辑运算符', () {
    test('not 在 true/false 上取反', () {
      expect(true.not, isFalse);
      expect(false.not, isTrue);
    });

    test('operator & 等价 &&（短路语义由两侧常量验证真值表）', () {
      expect(true & true, isTrue);
      expect(true & false, isFalse);
      expect(false & true, isFalse);
      expect(false & false, isFalse);
    });

    test('operator | 等价 ||（真值表）', () {
      expect(true | true, isTrue);
      expect(true | false, isTrue);
      expect(false | true, isTrue);
      expect(false | false, isFalse);
    });
  });

  group('BoolExt.ifTrue / ifFalse', () {
    test('true.ifTrue 返回 value，false.ifTrue 返回 null', () {
      expect(true.ifTrue('A'), 'A');
      expect(false.ifTrue('A'), isNull);
    });

    test('false.ifFalse 返回 value，true.ifFalse 返回 null', () {
      expect(false.ifFalse('B'), 'B');
      expect(true.ifFalse('B'), isNull);
    });

    test('泛型保持元素类型（非 String 场景）', () {
      expect(true.ifTrue(42), 42);
      expect(false.ifTrue(<int>[1]), isNull);
    });
  });

  group('BoolExt.ifElse / 转换', () {
    test('ifElse 按 true/false 分支取值', () {
      expect(true.ifElse('T', 'F'), 'T');
      expect(false.ifElse('T', 'F'), 'F');
    });

    test('toInt 映射 true→1 / false→0', () {
      expect(true.toInt, 1);
      expect(false.toInt, 0);
    });

    test('toStringVal 输出字面量字符串', () {
      expect(true.toStringVal, 'true');
      expect(false.toStringVal, 'false');
    });
  });
}

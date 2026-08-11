// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:cutils/ui/calculate_utils.dart';

/// Wave G — calculate_utils TextPainter 资源释放回归测试。
void main() {
  testWidgets(
      'G3: calculateTextHeight/Width return size and dispose the painter',
      (tester) async {
    double? height;
    double? width;

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Builder(
            builder: (context) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  height = CalculateUtils.calculateTextHeight(context,
                      'Hello flutter 测量', 14.0, FontWeight.normal, 200.0, 2);
                  width = CalculateUtils.calculateTextWidth(
                      context, 'Hello', 14.0, FontWeight.normal, 200.0, 1);
                },
                child: const SizedBox(width: 50, height: 50),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(GestureDetector));
    await tester.pumpAndSettle();

    expect(height, isA<double>());
    expect(height!, greaterThan(0.0));
    expect(width, isA<double>());
    expect(width!, greaterThan(0.0));

    // 反复调用不应抛出，且不应累积未释放的 TextPainter（dispose 在 finally 中）。
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
    }
    // 没有 dispose 相关的 framework 异常。
    expect(tester.takeException(), isNull);
  });
}

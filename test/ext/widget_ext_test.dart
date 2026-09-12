// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:cutils/ext/widget_ext.dart';

void main() {
  const probe = SizedBox(width: 10, height: 10);

  group('WidgetExt.padding', () {
    testWidgets('包一层 Padding 且 child 是原 widget', (tester) async {
      final result = probe.padding(const EdgeInsets.all(8));
      expect(result, isA<Padding>());

      await tester.pumpWidget(MaterialApp(home: result));
      final padding = tester.widget<Padding>(find.byType(Padding));
      expect(padding.padding, const EdgeInsets.all(8));
      expect(padding.child, isA<SizedBox>());
    });
  });

  group('WidgetExt.gesture', () {
    testWidgets('包一层 GestureDetector，回调可触发', (tester) async {
      var taps = 0;
      final result = probe.gesture(onTap: () => taps++);

      expect(result, isA<GestureDetector>());
      await tester
          .pumpWidget(MaterialApp(home: Scaffold(body: Center(child: result))));

      await tester.tap(find.byType(GestureDetector));
      expect(taps, 1);
      // HitTestBehavior.opaque 保证空白区域也可命中。
      final detector =
          tester.widget<GestureDetector>(find.byType(GestureDetector));
      expect(detector.behavior, HitTestBehavior.opaque);
    });

    testWidgets('双击与长按回调可触发', (tester) async {
      var doubleTaps = 0;
      var longPresses = 0;
      final result = probe.gesture(
        onDoubleTap: () => doubleTaps++,
        onLongPress: () => longPresses++,
      );

      await tester
          .pumpWidget(MaterialApp(home: Scaffold(body: Center(child: result))));
      await tester.tap(find.byType(GestureDetector));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byType(GestureDetector));
      await tester.pump(const Duration(milliseconds: 50));
      expect(doubleTaps, 1);

      await tester.longPress(find.byType(GestureDetector));
      await tester.pump();
      expect(longPresses, 1);
    });
  });

  group('WidgetExt.gestureWithInkWellCircle', () {
    testWidgets('包 Material+InkWell，点击回调可触发', (tester) async {
      var taps = 0;
      final result = probe.gestureWithInkWellCircle(onTap: () => taps++);

      expect(result, isA<Material>());
      await tester
          .pumpWidget(MaterialApp(home: Scaffold(body: Center(child: result))));

      expect(find.byType(InkWell), findsOneWidget);
      await tester.tap(find.byType(InkWell));
      await tester.pump();
      expect(taps, 1);
    });
  });
}

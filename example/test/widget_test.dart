// Flutter imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:cutils_example/main.dart';

void main() {
  testWidgets('首页渲染演示分类入口', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // AppBar 标题。
    expect(find.text('cutils 演示'), findsOneWidget);
    // ListView 首项必然在视口内。
    expect(find.text('数值与金额'), findsOneWidget);
    expect(find.text('NumUtils / MoneyUtils / int_ext'), findsOneWidget);
  });
}

// Flutter imports:
import 'package:flutter/material.dart';

/// 演示页通用脚手架：AppBar + 可滚动内容区。
class DemoScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const DemoScaffold({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: children,
      ),
    );
  }
}

/// 单条演示行：描述 + 代码表达式 + 计算结果。
///
/// 用法：把「会算出什么」直接传进来，[result] 通常是运行时计算的真实值。
class DemoRow extends StatelessWidget {
  final String title;
  final String expr;
  final String result;

  const DemoRow({
    super.key,
    required this.title,
    required this.expr,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                expr,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  fontFamilyFallback: const ['Courier', 'monospace'],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '=> ',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.primary),
                ),
                Expanded(
                  child: SelectableText(
                    result,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

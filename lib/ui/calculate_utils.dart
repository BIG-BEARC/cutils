import 'package:flutter/material.dart';

/// 计算工具类
class CalculateUtils {
  /// 计算文本高度
  static double calculateTextHeight(BuildContext context, String value,
      double? fontSize, FontWeight fontWeight, double maxWidth, int maxLines) {
    //创建painter
    final TextPainter painter = TextPainter(
      locale: Localizations.localeOf(
        context,
      ),
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontWeight: fontWeight,
          fontSize: fontSize,
        ),
      ),
    );
    try {
      painter.layout(maxWidth: maxWidth);
      return painter.height;
    } finally {
      // 释放原生文本整形资源，避免每次调用泄漏。
      painter.dispose();
    }
  }

  /// 计算文本宽度
  static double calculateTextWidth(BuildContext context, String value,
      double? fontSize, FontWeight fontWeight, double maxWidth, int maxLines) {
    //创建painter
    final TextPainter painter = TextPainter(
      locale: Localizations.localeOf(
        context,
      ),
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontWeight: fontWeight,
          fontSize: fontSize,
        ),
      ),
    );
    try {
      painter.layout(maxWidth: maxWidth);
      return painter.width;
    } finally {
      // 释放原生文本整形资源，避免每次调用泄漏。
      painter.dispose();
    }
  }
}

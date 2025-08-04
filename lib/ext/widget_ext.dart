import 'package:flutter/material.dart';

/// * @Author: chuxiong
/// * @Created at: 2023/3/2 4:06 下午
/// * @Email:
/// * @Company: 嘉联支付
/// * description
///widget扩展：
extension WidgetExt on Widget {
  Widget padding(EdgeInsetsGeometry padding) {
    return Padding(
      padding: padding,
      child: this,
    );
  }

  ///添加水波纹
  Material gestureWithInkWellCircle({
    GestureTapCallback? onTap,
    GestureTapCallback? onDoubleTap,
    GestureLongPressCallback? onLongPress,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(40),
        radius: 60,
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        onLongPress: onLongPress,
        child: this,
      ),
    );
  }

  ///
  Widget gesture({
    GestureTapCallback? onTap,
    GestureTapCallback? onDoubleTap,
    GestureLongPressCallback? onLongPress,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      onLongPress: onLongPress,
      child: this,
    );
  }

}

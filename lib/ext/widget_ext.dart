import 'package:flutter/material.dart';

/// * @Author: chuxiong
/// * @Created at: 2023/3/2 4:06 下午
/// * @Email:
/// * @Company: 嘉联支付
/// * description
/// Widget 扩展：用链式调用包一层手势 / 内边距，减少嵌套。
extension WidgetExt on Widget {
  /// 用 [Padding] 包裹本组件，等价于 `Padding(padding: padding, child: this)`。
  Widget padding(EdgeInsetsGeometry padding) {
    return Padding(
      padding: padding,
      child: this,
    );
  }

  /// 用带水波纹的 [Material] + [InkWell] 包裹本组件，常用于圆形可点击区域。
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

  /// 用 [GestureDetector]（无水波纹）包裹本组件，支持单击 / 双击 / 长按。
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

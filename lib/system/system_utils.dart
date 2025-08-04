import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cutils/ext/ext_fun.dart';
import 'package:cutils/log/log.dart';

/// * @Author: chuxiong
/// * @Created at: 30-07-2025 17:47
/// * @Email:
/// * description
class SystemUtils {
  SystemUtils._();

  static final _ins = SystemUtils._();

  factory SystemUtils() => _ins;

  /// 设置应用为竖屏模式
  void setPortraitMode() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  /// 设置应用为横屏模式
  void setLandscapeMode() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  /// 允许所有屏幕方向
  void setAllOrientations() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  /// 设置状态栏和导航栏样式
  ///
  /// [style] 状态栏图标样式
  /// [color] 状态栏背景色
  /// [overlayStyle] 导航栏图标样式
  void setSystemUIOverlayStyle({
    SystemUiOverlayStyle? style,
    Color? statusBarColor,
    Brightness? statusBarIconBrightness,
    Brightness? systemNavigationBarIconBrightness,
  }) {
    SystemChrome.setSystemUIOverlayStyle(
      style ??
          SystemUiOverlayStyle(
            statusBarColor: statusBarColor ?? Colors.transparent,
            statusBarIconBrightness: statusBarIconBrightness ?? Brightness.dark,
            systemNavigationBarIconBrightness:
            systemNavigationBarIconBrightness ?? Brightness.dark,
          ),
    );
  }
  /// 隐藏状态栏和导航栏
  Future<void> hideSystemUI() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  /// 显示状态栏和导航栏
  Future<void> showSystemUI() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  /// 获取设备像素密度
  double get devicePixelRatio {
    // 使用 PlatformDispatcher 替代 window
    return WidgetsBinding.instance.platformDispatcher.implicitView?.devicePixelRatio ?? 1.0;
  }

  /// 获取屏幕尺寸
  Size get screenSize {
    final view = WidgetsBinding.instance.platformDispatcher.implicitView;
    if (view != null) {
      return view.physicalSize / view.devicePixelRatio;
    }
    return Size.zero;
  }

  /// 获取状态栏高度
  double get statusBarHeight {
    final view = WidgetsBinding.instance.platformDispatcher.implicitView;
    if (view != null) {
      return view.padding.top / view.devicePixelRatio;
    }
    return 0.0;
  }

  /// 获取导航栏高度
  double get navigationBarHeight {
    final view = WidgetsBinding.instance.platformDispatcher.implicitView;
    if (view != null) {
      final padding = view.padding;
      return (padding.bottom - padding.top) / view.devicePixelRatio;
    }
    return 0.0;
  }

  /// 拷贝文本内容到剪切板
  ///
  /// [text] 需要复制的文本内容
  /// [successMessage] 复制成功时的提示信息，默认为"copy success"
  /// [errorMessage] 复制失败时的提示信息，默认为"copy error"
  /// [context] 上下文，用于显示SnackBar提示
  /// [duration] 提示持续时间，默认为1秒
  Future<void> copyToClipboard(
      String text, {
        String? successMessage,
        String? errorMessage,
        BuildContext? context,
        Duration duration = const Duration(seconds: 1),
      }) async {
    if (text.isNullOrEmpty) {
      return;
    }

    final snackBarMsg = successMessage ?? "copy success";
    final errorSnackBarMsg = errorMessage ?? "copy error";

    try {
      await Clipboard.setData(ClipboardData(text: text));
      _showSnackBar(context, snackBarMsg, duration);
    } catch (e, stackTrace) {
      logger.e("copy error: $e", error: e, stackTrace: stackTrace);
      _showSnackBar(context, errorSnackBarMsg, duration);
    }
  }
  /// 显示SnackBar提示
  ///
  /// [context] 上下文
  /// [message] 提示信息
  /// [duration] 持续时间
  /// [actionLabel] 动作按钮标签
  /// [onActionPressed] 动作按钮点击回调
  void _showSnackBar(
      BuildContext? context,
      String message,
      Duration duration, {
        String? actionLabel,
        VoidCallback? onActionPressed,
      }) {
    if (context != null && context.mounted) {
      final snackBar = SnackBar(
        duration: duration,
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        action: actionLabel != null && onActionPressed != null
            ? SnackBarAction(
          label: actionLabel,
          onPressed: onActionPressed,
        )
            : SnackBarAction(
          label: 'close',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }
  /// 从剪贴板获取文本内容
  ///
  /// 返回剪贴板中的文本内容，如果出错则返回空字符串
  Future<String> getClipboardText() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      return clipboardData?.text ?? '';
    } catch (e, stackTrace) {
      logger.e("get clipboard text error: $e", error: e, stackTrace: stackTrace);
      return '';
    }
  }
  /// 隐藏软键盘，具体可看：TextInputChannel
  void hideKeyboard() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  /// 展示软键盘，具体可看：TextInputChannel
  void showKeyboard() {
    SystemChannels.textInput.invokeMethod('TextInput.show');
  }

  /// 清除数据
  void clearClientKeyboard() {
    SystemChannels.textInput.invokeMethod('TextInput.clearClient');
  }
}

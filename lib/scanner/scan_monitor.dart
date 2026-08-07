import 'dart:async';
import 'package:cutils/system/keyboard_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef BarcodeScannedCallback = void Function(String barcode, String originalCode);
///待验证
class ScanMonitor extends StatefulWidget {
  const ScanMonitor({
    super.key,
    required this.child,
    required this.onBarcodeScanned,
    required this.useTimer,
    this.bufferDuration = 1000,
    this.useKeyUpEvent = false,
    this.foucusNode,
  });

  final BarcodeScannedCallback onBarcodeScanned;
  final int bufferDuration;
  final bool useTimer;

  ///默认使用downEvent ，有些扫码盒子、扫码枪 只有upEvent 事件，需要手动设置
  final bool useKeyUpEvent;
  final FocusNode? foucusNode;
  final Widget child;

  @override
  State<ScanMonitor> createState() => _ScanMonitorState();
}

const String lineFeed = '\n';

class _ScanMonitorState extends State<ScanMonitor> {
  // 两个字符之间的定时器，超过500毫秒未返回直接返回扫码结果
  Timer? _betweenCharTimer;
  bool lineFeedCall = false;
  final List<String> _scannedChars = [];
  final List<String> _originalChars = [];

  final _controller = StreamController<String?>.broadcast();
  late final StreamSubscription<String?> _keyboardSubscription;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.foucusNode ?? FocusNode();
    if (!kReleaseMode) {
      _focusNode.addListener(() {
        debugPrint('[ScanMonitor] Focus changed: ${_focusNode.hasFocus}');
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration.zero, () {
        if (mounted && !_focusNode.hasFocus) {
          _focusNode.requestFocus();
        }
      });
    });

    _keyboardSubscription = _controller.stream.where((c) => c != null).listen(onKeyEvent);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _betweenCharTimer?.cancel();
    _keyboardSubscription.cancel();
    _controller.close();
    super.dispose();
  }

  /// 手动重试聚焦方法
  void retryFocus() {
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  void onKeyEvent(String? char) {
    if (char == null) {
      return;
    }
    if (char == lineFeed) {
      lineFeedCall = true;
      callWithoutLineFeed();
      return;
    }
    if (!lineFeedCall) {
      _scannedChars.add(char);
    }
    if (widget.useTimer) {
      _betweenCharTimer?.cancel();
      _betweenCharTimer = Timer(
        Duration(milliseconds: widget.bufferDuration >= 1000 ? widget.bufferDuration : 1000),
        () {
          if (!lineFeedCall && _scannedChars.isNotEmpty) {
            lineFeedCall = true;
            callWithoutLineFeed();
          }
        },
      );
    }
  }

  void callWithoutLineFeed() {
    if (_scannedChars.isEmpty) return;
    widget.onBarcodeScanned.call(_scannedChars.join(), _originalChars.toString());
    resetScannedCharCodes();
  }

  void resetScannedCharCodes() {
    _scannedChars.clear();
    _originalChars.clear();
    lineFeedCall = false;
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      node: FocusScopeNode(),
      autofocus: true,
      child: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (event) {
          if (widget.useKeyUpEvent && event is KeyUpEvent) {
            _handleKeyEvent(event);
          } else if (!widget.useKeyUpEvent && event is KeyDownEvent) {
            _handleKeyEvent(event);
          }
        },
        child: widget.child,
      ),
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    //todo 去掉_betweenCharTimer ，
    // _betweenCharTimer?.cancel();
    // _betweenCharTimer = Timer(
    //   Duration(milliseconds: widget.bufferDuration >= 1000 ? widget.bufferDuration : 1000),
    //   () {
    //     if (!lineFeedCall && _scannedChars.isNotEmpty) {
    //       lineFeedCall = true;
    //       callWithoutLineFeed();
    //     }
    //   },
    // );

    _originalChars.add(event.logicalKey.keyLabel);

    if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey.keyLabel == LogicalKeyboardKey.select.keyLabel) {
      _controller.sink.add(lineFeed);
      return;
    }

    bool isNotEnterOrSelect = event.logicalKey != LogicalKeyboardKey.enter || event.logicalKey.keyLabel != LogicalKeyboardKey.select.keyLabel;
    if (event.logicalKey.keyId > 255 && !isNotEnterOrSelect) {
      return;
    }

    String str = keyBoardUtils.analysisKeyEvent(event);
    if (str.isNotEmpty) {
      _controller.sink.add(str);
    }
  }
}

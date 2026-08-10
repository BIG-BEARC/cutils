// Dart imports:
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cutils/log/log.dart';

/// * @Author: chuxiong
/// * @Created at: 2022/10/28 9:42 上午
/// * @Email:
/// * @Company: 嘉联支付
/// * description 网络连接监听
///
final netUtil = NetUtil();

class NetUtil {
  factory NetUtil() => _ins;

  NetUtil._internal();

  static final NetUtil _ins = NetUtil._internal();

  //获取网络类型
  String _netType = "none";
  bool _connected = false;

  bool get connected => _connected;

  String get netType => _netType;

  ///是否连接网络
  ///reChecked 是否需要重新检测
  Future<bool> isConnectedNet({bool reChecked = false}) async {
    ///如果已连接，则不去检测，频繁检测损耗性能且易出平台异常
    if (_connected && !reChecked) {
      return _connected;
    }
    List<ConnectivityResult> result;
    try {
      result = await Connectivity().checkConnectivity();
    } on PlatformException catch (e) {
      logger.e("Connectivity.checkConnectivity异常:$e");
      result = [ConnectivityResult.none];
    }
    // Derive the human-readable label from the first non-none result (if
    // any) so `netType` reflects an actual connection rather than a stale
    // `none` at index 0.
    final representative = result.firstWhere(
      (r) => r != ConnectivityResult.none,
      orElse: () => ConnectivityResult.none,
    );
    _getNetType(representative);
    // The connected verdict uses the WHOLE result list (D4/D5): every
    // platform — Windows included — runs the same check, any non-none
    // result counts as connected, and bluetooth is treated as connected.
    _connected = isConnectedFromResults(result);
    return _connected;
  }

  bool _getNetType(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        _netType = "wifi";
        _connected = true;
        break;
      case ConnectivityResult.mobile:
        _netType = "移动连接";
        _connected = true;
        break;
      case ConnectivityResult.ethernet:
        _netType = "以太网";
        _connected = true;
        break;
      case ConnectivityResult.bluetooth:
        _netType = "蓝牙";
        _connected = false;
        break;
      case ConnectivityResult.none:
      default:
        _netType = "未连接";
        _connected = false;
        break;
    }
    return _connected;
  }

  /// Pure connectivity decision extracted from [isConnectedNet].
  ///
  /// Returns `true` iff the device has at least one live connection. The
  /// decision intentionally ignores `Platform.isWindows` (desktops are NOT
  /// assumed online — see D4) and treats every result other than
  /// [ConnectivityResult.none] — including bluetooth — as connected (D5).
  ///
  /// Extracted so the aggregation logic is unit-testable without a live
  /// platform plugin or a mocked `dart.io Platform`.
  @visibleForTesting
  static bool isConnectedFromResults(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    // Any live result keeps the device online; bluetooth counts as
    // connected. Only an all-`none` (or empty) list is offline.
    return results.any((r) => r != ConnectivityResult.none);
  }
}

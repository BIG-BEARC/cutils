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
/// [NetUtil] 是一个 app 级单例：
/// - 调用 [isConnectedNet] 做一次性连通性检测（带超时）；
/// - 调用 [start] 订阅 [Connectivity.onConnectivityChanged] 流，缓存
///   `_connected`/`_netType` 随平台事件实时更新；
/// - app 销毁时调用 [dispose] 取消订阅。
final netUtil = NetUtil();

/// 平台连通性检测的超时时长。卡住的平台调用超过此时长即视为离线。
const Duration _kConnectivityTimeout = Duration(seconds: 5);

class NetUtil {
  factory NetUtil() => _ins;

  NetUtil._internal();

  static final NetUtil _ins = NetUtil._internal();

  //获取网络类型
  String _netType = "none";
  bool _connected = false;

  /// `onConnectivityChanged` 的订阅；由 [start] 建立、由 [dispose] 取消。
  /// 为 `null` 表示当前未订阅。
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool get connected => _connected;

  String get netType => _netType;

  /// 订阅 [Connectivity.onConnectivityChanged] 流。
  ///
  /// 调用一次后缓存 `_connected`/`_netType` 会随平台事件实时更新，避免
  /// [isConnectedNet] 只在主动检测时刷新导致的状态陈旧。本方法幂等：
  /// 重复调用不会叠加多个订阅。
  ///
  /// app 启动时调用一次即可；app 销毁前调用 [dispose] 取消订阅。
  void start() {
    if (_subscription != null) return;
    _subscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        applyConnectivityResults(results);
      },
      onError: (Object e) {
        logger.e("onConnectivityChanged 流错误:$e");
      },
    );
  }

  /// 取消 [start] 建立的订阅。幂等：未订阅或重复调用均安全。
  ///
  /// 不会重置 `_connected`/`_netType`——下次调用 [isConnectedNet] 或
  /// [start] 时会再次刷新。
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  ///是否连接网络
  ///reChecked 是否需要重新检测
  ///
  ///平台调用带 [_kConnectivityTimeout] 超时：卡住或异常一律按离线处理。
  Future<bool> isConnectedNet({bool reChecked = false}) async {
    ///如果已连接，则不去检测，频繁检测损耗性能且易出平台异常
    if (_connected && !reChecked) {
      return _connected;
    }
    List<ConnectivityResult> result;
    try {
      result = await Connectivity()
          .checkConnectivity()
          .timeout(_kConnectivityTimeout);
    } on TimeoutException catch (e) {
      // 平台调用超时——视为离线，避免无限阻塞调用方。
      logger.e("Connectivity.checkConnectivity 超时($e): 视为离线");
      result = [ConnectivityResult.none];
    } on PlatformException catch (e) {
      logger.e("Connectivity.checkConnectivity异常:$e");
      result = [ConnectivityResult.none];
    }
    applyConnectivityResults(result);
    return _connected;
  }

  /// 用一组 [ConnectivityResult] 同步刷新 `_connected`/`_netType` 缓存。
  ///
  /// 抽成 `@visibleForTesting` 纯方法（不触平台），使聚合逻辑在不依赖
  /// 真机/插件的环境下可单测：[isConnectedNet] 与 [start] 的流回调都走
  /// 这里。
  ///
  /// 连通性判定：列表中只要有一个结果不是 [ConnectivityResult.none] 即
  /// 视为已连接（蓝牙也算连接，见 Wave D）；`_netType` 取第一个非 none
  /// 的代表项。
  @visibleForTesting
  void applyConnectivityResults(List<ConnectivityResult> results) {
    final representative = results.firstWhere(
      (r) => r != ConnectivityResult.none,
      orElse: () => ConnectivityResult.none,
    );
    _getNetType(representative);
    _connected = isConnectedFromResults(results);
  }

  /// 根据 [ConnectivityResult] 设置 `_netType` 文案。
  ///
  /// 穷尽枚举：wifi/mobile/ethernet/bluetooth/vpn/other 各有文案，仅
  /// [ConnectivityResult.none] 标为 "未连接"。不再有 default-as-none。
  void _getNetType(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        _netType = "wifi";
        break;
      case ConnectivityResult.mobile:
        _netType = "移动连接";
        break;
      case ConnectivityResult.ethernet:
        _netType = "以太网";
        break;
      case ConnectivityResult.bluetooth:
        _netType = "蓝牙";
        break;
      case ConnectivityResult.vpn:
        _netType = "VPN";
        break;
      case ConnectivityResult.other:
        _netType = "其他网络";
        break;
      case ConnectivityResult.none:
        _netType = "未连接";
        break;
    }
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

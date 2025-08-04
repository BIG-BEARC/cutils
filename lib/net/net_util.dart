// Dart imports:
import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
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
    if (Platform.isWindows) {
      return true;
    }

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
    return _getNetType(result[0]);
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
}

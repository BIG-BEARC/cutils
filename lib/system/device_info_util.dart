import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:cutils/log/log.dart';
import 'package:flutter/foundation.dart';

/// * @Author: chuxiong
/// * @Created at: 10-06-2025 17:40
/// * @Email:
/// * description
/// 设备信息工具（基于 `device_info_plus`）。app 启动调用 [init] 后，
/// 通过 [osVersion] / [deviceType] / [androidSdkInt] / [serialNumber] 等
/// getter 读取缓存值；Windows 平台可调用 [winUniqueIdentifier] 取机器码。

/// 全局 [DeviceInfoUtil] 单例。
final deviceInfo = DeviceInfoUtil();

/// 设备信息读取工具（单例）。
class DeviceInfoUtil {
  DeviceInfoUtil._();

  static final DeviceInfoUtil _instance = DeviceInfoUtil._();

  factory DeviceInfoUtil() => _instance;
  String _osVersion = "unknown";
  String _deviceType = "unknown";
  int _androidSdkInt = 16;

  String _deviceInfo = "";

  /// 设备完整信息（插件原始 toString）。
  String get deviceInfo => _deviceInfo;

  String _serialNumber = "";

  /// 设备序列号 / 唯一标识（各平台语义不同，见 [init]）。
  String get serialNumber => _serialNumber;

  /// 操作系统版本字符串。
  String get osVersion => _osVersion;

  /// 设备型号 / 制造商（Android 为 manufacturer，iOS 为 utsname.machine）。
  String get deviceType => _deviceType;

  /// Android SDK 版本号（非 Android 返回默认 16）。
  int get androidSdkInt => _androidSdkInt;

  /// 初始化：按当前平台（Android / iOS / Windows / macOS）读取并缓存设备信息。
  /// 任何平台异常都吞掉并返回 `false`，便于调用方在无插件环境降级。
  Future<bool> init() async {
    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        await _getAndroidInfo(plugin);
      } else if (Platform.isIOS) {
        await _getIosInfo(plugin);
      } else if (Platform.isWindows) {
        await _getWindowsInfo(plugin);
      } else if (Platform.isMacOS) {
        await _getMacOsInfo(plugin);
      }
    } catch (e) {
      return false;
    }
    return true;
  }

  Future<void> _getAndroidInfo(DeviceInfoPlugin plugin) async {
    final androidInfo = await plugin.androidInfo;
    _androidSdkInt = androidInfo.version.sdkInt;
    _osVersion = _androidSdkInt.toString();
    if (androidInfo.serialNumber.isNotEmpty) {
      _serialNumber = androidInfo.serialNumber;
    } else if (androidInfo.id.isNotEmpty) {
      _serialNumber = androidInfo.id;
    }

    ///制造商
    _deviceType = androidInfo.manufacturer.trim();
    _deviceInfo = androidInfo.toString();
  }

  Future<void> _getIosInfo(DeviceInfoPlugin plugin) async {
    final iosInfo = await plugin.iosInfo;
    _osVersion = iosInfo.systemVersion;
    _deviceType = iosInfo.utsname.machine;
    _serialNumber = iosInfo.identifierForVendor ?? "";
    _deviceInfo = iosInfo.toString();
  }

  Future<void> _getWindowsInfo(DeviceInfoPlugin plugin) async {
    try {
      final windowsInfo = await plugin.windowsInfo;
      _osVersion = windowsInfo.productName;
      _deviceType = windowsInfo.productId;
      _serialNumber = windowsInfo.deviceId;
      _deviceInfo = windowsInfo.toString();
    } catch (e) {
      logger.e("_getWindowsInfo异常:${e.toString()}");
    }

    // "uniqueIdentifier:$uniqueIdentifier"; //window安装时生成机器id
    //" computerName:${windowsInfo.computerName} \n"///计算机全名
    //" userName: ${windowsInfo.userName}\n"///用户名
  }

  Future<void> _getMacOsInfo(DeviceInfoPlugin plugin) async {
    try {
      final macOsDeviceInfo = await plugin.macOsInfo;
      _osVersion = macOsDeviceInfo.osRelease;
      _deviceInfo = macOsDeviceInfo.toString();
    } catch (e) {
      logger.e("_getMacOsInfo异常:${e.toString()}");
    }
  }

  /// A unique device identifier.
  ///
  /// Refer[Unity deviceUniqueIdentifier](https://docs.unity3d.com/ScriptReference/SystemInfo-deviceUniqueIdentifier.html)
  Future<String> winUniqueIdentifier() async {
    try {
      // fetch ids in windows
      final baseBoardID = await _winBaseBoardID();
      final biosID = await _winBiosID();
      final processorID = await _winProcessorID();
      final diskDriveID = await _winDiskDrive();
      final osNumber = await _winOSNumber();
      // Only stable hardware ids are hashed — never wall-clock time, or the
      // identifier would change on every call.
      return buildWinUniqueId(
        [baseBoardID, biosID, processorID, diskDriveID, osNumber],
      );
    } catch (e) {
      logger.e('uniqueIdentifier$e');
      return '';
    }
  }

  /// Builds the md5 device identifier from a set of stable hardware ids.
  ///
  /// Extracted from [winUniqueIdentifier] so the hashing logic is unit-
  /// testable without spawning `wmic` processes. Only stable hardware ids
  /// may be supplied — never wall-clock time, or the identifier will change
  /// on every call.
  @visibleForTesting
  static String buildWinUniqueId(Iterable<String> ids) {
    final all = ids.join();
    return md5.convert(utf8.encode(all)).toString();
  }

  /// windows `Win32_BaseBoard::SerialNumber`
  ///
  /// cmd: `wmic baseboard get SerialNumber`
  Future<String> _winBaseBoardID() async {
    return _fetchWinID(
      'wmic',
      ['baseboard', 'get', 'serialnumber'],
      'serialnumber',
    );
  }

  /// windows `Win32_BIOS::SerialNumber`
  ///
  /// cmd: `wmic csproduct get UUID`
  Future<String> _winBiosID() async {
    return _fetchWinID(
      'wmic',
      ['csproduct', 'get', 'uuid'],
      'uuid',
    );
  }

  /// windows `Win32_Processor::UniqueId`
  ///
  /// cmd: `wmic baseboard get SerialNumber`
  Future<String> _winProcessorID() async {
    return _fetchWinID(
      'wmic',
      ['cpu', 'get', 'processorid'],
      'processorid',
    );
  }

  /// windows `Win32_DiskDrive::SerialNumber`
  ///
  /// cmd: `wmic diskdrive get SerialNumber`
  Future<String> _winDiskDrive() async {
    return _fetchWinID(
      'wmic',
      ['diskdrive', 'get', 'serialnumber'],
      'serialnumber',
    );
  }

  /// windows `Win32_OperatingSystem::SerialNumber`
  ///
  /// cmd: `wmic os get serialnumber`
  Future<String> _winOSNumber() async {
    return _fetchWinID(
      'wmic',
      ['os', 'get', 'serialnumber'],
      'serialnumber',
    );
  }

  /// fetch windows id by cmd line
  Future<String> _fetchWinID(
    String executable,
    List<String> arguments,
    String regExpSource,
  ) async {
    String id = '';
    try {
      final process = await Process.start(
        executable,
        arguments,
        mode: ProcessStartMode.detachedWithStdio,
      );
      final result = await process.stdout.transform(utf8.decoder).toList();
      for (final element in result) {
        final item = element.toLowerCase().replaceAll(
              RegExp('\r|\n|\\s|$regExpSource'),
              '',
            );
        if (item.isNotEmpty) {
          id = id + item;
        }
      }
    } on Exception catch (_) {}
    return id;
  }
}

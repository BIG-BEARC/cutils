import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:cutils/log/log.dart';

/// * @Author: chuxiong
/// * @Created at: 10-06-2025 17:40
/// * @Email:
/// * description

final deviceInfo = DeviceInfoUtil();

class DeviceInfoUtil {
  DeviceInfoUtil._();

  static final DeviceInfoUtil _instance = DeviceInfoUtil._();

  factory DeviceInfoUtil() => _instance;
  String _osVersion = "unKnow";
  String _deviceType = "unKnow";
  int _androidSdkInt = 16;

  String _deviceInfo = "";

  String get deviceInfo => _deviceInfo;

  String _serialNumber = "";

  String get serialNumber => _serialNumber;

  String get osVersion => _osVersion;

  String get deviceType => _deviceType;

  int get androidSdkInt => _androidSdkInt;

  Future<bool> init() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        await _getAndroidInfo(deviceInfo);
      } else if (Platform.isIOS) {
        await _getIosInfo(deviceInfo);
      } else if (Platform.isWindows) {
        await _getWindowsInfo(deviceInfo);
      } else if (Platform.isMacOS) {
        await _getMacOsInfo(deviceInfo);
      }
    } catch (e) {
      return false;
    }
    return true;
  }

  Future<void> _getAndroidInfo(DeviceInfoPlugin deviceInfo) async {
    final androidInfo = await deviceInfo.androidInfo;
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

  Future<void> _getIosInfo(DeviceInfoPlugin deviceInfo) async {
    final iosInfo = await deviceInfo.iosInfo;
    _osVersion = iosInfo.systemVersion;
    _deviceType = iosInfo.utsname.machine;
    _serialNumber = iosInfo.identifierForVendor ?? "";
    _deviceInfo = iosInfo.toString();
  }

  Future<void> _getWindowsInfo(DeviceInfoPlugin deviceInfo) async {
    try {
      final windowsInfo = await deviceInfo.windowsInfo;
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

  Future<void> _getMacOsInfo(DeviceInfoPlugin deviceInfo) async {
    try {
      final macOsDeviceInfo = await deviceInfo.macOsInfo;
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
      // md5 generates a unique id, using String.hashCode directly is too easy to collide
      final all = baseBoardID + biosID + processorID + diskDriveID + osNumber + DateTime.now().toString();
      final uID = md5.convert(utf8.encode(all)).toString();
      return uID;
    } catch (e) {
      logger.e('uniqueIdentifier$e');
      return '';
    }
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
      for (var element in result) {
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

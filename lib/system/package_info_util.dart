import 'package:package_info_plus/package_info_plus.dart';

import '../log/log.dart';

/// * @Author: chuxiong
/// * @Created at: 10-06-2025 17:34
/// * @Email:
/// * description 包工具类
///
/// 读取 App 包信息（名称 / 包名 / 版本名 / 版本号）。app 启动调用 [init] 后，
/// 通过各 getter 读取缓存值。

/// 全局 [PackageInfoUtil] 单例。
final packageInfoUtil = PackageInfoUtil();

/// App 包信息读取工具（单例，基于 `package_info_plus`）。
class PackageInfoUtil {
  PackageInfoUtil._();

  static final PackageInfoUtil _instance = PackageInfoUtil._();

  factory PackageInfoUtil() => _instance;

  //APP名称
  String _appName = '';

  //包名
  String _packageName = '';

  //版本名
  String _version = '';

  //版本号
  String _buildNumber = '';

  /// 包名（如 `com.example.app`）。
  String get packageName => _packageName;

  /// 版本号（build number）。
  String get buildNumber => _buildNumber;

  /// App 显示名称。
  String get appName => _appName;

  /// 版本名（如 `1.2.0`）。
  String get version => _version;

  /// 从平台读取并缓存包信息。失败仅记录日志，不抛出（getter 返回空串）。
  Future<void> init() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appName = packageInfo.appName;
      _packageName = packageInfo.packageName;
      _version = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    } catch (e) {
      logger.e('PackageInfoUtil initialize error: $e');
    }
  }
}

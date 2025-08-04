import 'package:package_info_plus/package_info_plus.dart';

import '../log/log.dart';

/// * @Author: chuxiong
/// * @Created at: 10-06-2025 17:34
/// * @Email:
/// * description 包工具类
final packageInfoUtil = PackageInfoUtil();

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

  String get packageName => _packageName;

  String get buildNumber => _buildNumber;

  String get appName => _appName;

  String get version => _version;

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

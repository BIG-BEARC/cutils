/// cutils —— 通用 Flutter 工具库顶层 barrel。
///
/// 一行导入即可用全部核心工具：
/// ```dart
/// import 'package:cutils/cutils.dart';
/// ```
library;

// 类型扩展
export 'ext/ext_fun.dart';
// 数值与金额
export 'num/num_utils.dart';
export 'num/money_utils.dart';
export 'num/money_unit.dart';
// 日期时间
export 'datetime/date_utils.dart';
export 'datetime/data_formats.dart';
export 'datetime/timeline_util.dart';
export 'datetime/timer_util.dart';
// 正则 / JSON / 加解密
export 'regex/regex_utils.dart';
export 'regex/regex_constants.dart';
export 'json/json_utils.dart';
export 'crypto/crypto_utils.dart';
// 文件 / 存储 / 网络
export 'file/file_utils.dart';
export 'storage/sp_util.dart';
export 'net/net_util.dart';
export 'net/url_utils.dart';
// 系统
export 'system/device_info_util.dart';
export 'system/package_info_util.dart';
export 'system/keyboard_util.dart';
export 'system/system_utils.dart';
// UI / 事件 / 标识
export 'ui/calculate_utils.dart';
export 'ui/image_utils.dart';
export 'event/event_bus_util.dart';
export 'identifier/random_utils.dart';
export 'identifier/uuid_utils.dart';
// 日志
export 'log/log.dart';
// 日志收集子系统（已自带门面）
export 'log_collector/log_collector_export.dart';

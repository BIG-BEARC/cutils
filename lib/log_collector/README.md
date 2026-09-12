# 通用日志收集模块

## 概述

这是一个通用的日志收集模块，设计目标是在不修改现有项目代码的前提下，通过拦截和监听的方式收集项目中的各种日志。

## 特性

- ✅ **零侵入**：不修改现有代码，通过拦截器自动收集日志
- ✅ **多源收集**：支持debugPrint、异常、文件日志等多种来源
- ✅ **灵活配置**：支持多种配置选项，适应不同环境需求
- ✅ **多种输出**：支持控制台、文件、网络等多种输出方式
- ✅ **高性能**：异步处理、批量输出、内存缓存等优化
- ✅ **易于扩展**：插件化设计，易于添加自定义拦截器和输出器

## 架构设计

```
LogCollector (日志收集器)
├── LogInterceptor (拦截器)
│   ├── DebugPrintInterceptor (debugPrint拦截)
│   ├── ExceptionInterceptor (异常拦截)
│   └── FileLogInterceptor (文件日志监听)
├── LogStorage (存储)
│   ├── MemoryStorage (内存存储)
│   └── FileStorage (文件存储)
└── LogOutput (输出器)
    ├── ConsoleLogOutput (控制台输出)
    ├── FileLogOutput (文件输出，⚠️ 尚未实现——占位类，构造即抛异常)
    └── NetworkLogOutput (网络输出，⚠️ 尚未实现——占位类，构造即抛异常)
```

## 快速开始

### 1. 基本使用

```dart
import 'package:cutils/log_collector/log_collector_helper.dart';

// 在main函数中初始化
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 快速初始化（使用默认配置）
  await LogCollectorHelper.quickInitialize();
  
  runApp(MyApp());
}
```

### 2. 手动收集日志

```dart
// 收集不同级别的日志
LogCollectorHelper.debug('这是一条调试日志');
LogCollectorHelper.info('这是一条信息日志');
LogCollectorHelper.warning('这是一条警告日志');
LogCollectorHelper.error('这是一条错误日志', error: e, stackTrace: stackTrace);
LogCollectorHelper.fatal('这是一条致命错误日志', error: e, stackTrace: stackTrace);

// 带额外数据的日志
LogCollectorHelper.log(
  '用户操作日志',
  level: LogLevel.info,
  tag: 'user_action',
  extra: {
    'userId': '12345',
    'action': 'login',
  },
);
```

### 3. 高级配置

```dart
import 'package:cutils/log_collector/log_collector.dart';
import 'package:cutils/log_collector/log_collector_config.dart';
import 'package:cutils/log_collector/log_interceptor.dart';
import 'package:cutils/log_collector/log_output.dart';

// 创建自定义配置
final config = LogCollectorConfig(
  minLevel: LogLevel.info, // 最小日志级别
  enableFileStorage: true, // 启用文件存储
  enableMemoryStorage: true, // 启用内存存储
  maxMemoryLogCount: 2000, // 内存最大日志数
  retentionDays: 7, // 日志保留天数
  filterTags: ['network', 'database'], // 只收集特定标签的日志
);

// 创建输出器
//
// ⚠️ FileLogOutput / NetworkLogOutput 当前为占位类（尚未实现），
// 直接构造会抛 UnimplementedError——请勿使用，待后续版本实现。
// 当前可用的输出器：ConsoleLogOutput、BatchLogOutput（包装自定义输出器）。
final outputs = [
  ConsoleLogOutput(enableColor: true),
  // FileLogOutput(filePath: '/path/to/logs'),        // 尚未实现，占位
  // BatchLogOutput(                                   // 批量输出，提高性能
  //   delegate: NetworkLogOutput(endpoint: 'https://api.example.com/logs'),
  //   batchSize: 100,
  // ),                                                 // 尚未实现，占位
];

// 创建拦截器
final interceptors = [
  DebugPrintInterceptor(),
  ExceptionInterceptor(),
];

// 初始化
await LogCollector.instance.initialize(
  config: config,
  outputs: outputs,
  interceptors: interceptors,
);
```

## 配置说明

### LogCollectorConfig

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| minLevel | LogLevel | LogLevel.debug | 最小日志级别 |
| storagePath | String? | null | 日志存储路径（null使用默认路径） |
| maxFileSize | int | 10MB | 单个日志文件最大大小 |
| maxFileCount | int | 10 | 最大日志文件数量 |
| retentionDays | int | 7 | 日志保留天数 |
| enableFileStorage | bool | true | 是否启用文件存储 |
| enableMemoryStorage | bool | true | 是否启用内存存储 |
| maxMemoryLogCount | int | 1000 | 内存中最大日志数量 |
| filterTags | List<String> | [] | 过滤的标签列表（空列表表示不过滤） |
| enableCompression | bool | false | 是否启用日志压缩 |
| autoCleanExpiredLogs | bool | true | 是否自动清理过期日志 |

### 预设配置

```dart
// 开发环境配置
final devConfig = LogCollectorConfig.development();

// 生产环境配置
final prodConfig = LogCollectorConfig.production();
```

## 日志级别

- `LogLevel.verbose` - 详细日志
- `LogLevel.debug` - 调试日志
- `LogLevel.info` - 信息日志
- `LogLevel.warning` - 警告日志
- `LogLevel.error` - 错误日志
- `LogLevel.fatal` - 致命错误

## 日志来源

- `LogSource.debugPrint` - Flutter debugPrint
- `LogSource.console` - 控制台输出
- `LogSource.file` - 文件日志
- `LogSource.exception` - 异常日志
- `LogSource.network` - 网络日志
- `LogSource.custom` - 自定义日志

## 查询和导出日志

```dart
final collector = LogCollector.instance;

// 查询日志
final logs = await collector.getAllLogs(
  startTime: DateTime.now().subtract(Duration(days: 1)),
  endTime: DateTime.now(),
  level: LogLevel.error,
  tag: 'network',
);

// 导出日志
final exportFile = await collector.exportLogs(
  startTime: DateTime.now().subtract(Duration(days: 7)),
  level: LogLevel.warning,
);

if (exportFile != null) {
  print('日志已导出到: ${exportFile.path}');
}

// 清空日志
await collector.clearLogs();
```

## 自定义拦截器

```dart
class CustomInterceptor extends LogInterceptor {
  @override
  Future<void> onStart() async {
    // 启动时的操作，例如监听某个事件
  }

  @override
  Future<void> onStop() async {
    // 停止时的操作，例如取消监听
  }
}

// 使用自定义拦截器
collector.addInterceptor(CustomInterceptor());
```

## 自定义输出器

```dart
class CustomOutput extends LogOutput {
  @override
  Future<void> output(LogEntry entry) async {
    // 自定义输出逻辑，例如发送到第三方服务
  }
}

// 使用自定义输出器
collector.addOutput(CustomOutput());
```

## 注意事项

1. **初始化时机**：建议在`main`函数中，`WidgetsFlutterBinding.ensureInitialized()`之后初始化
2. **性能考虑**：大量日志可能影响性能，建议在生产环境提高`minLevel`
3. **存储空间**：注意日志文件可能占用较多存储空间，合理设置`retentionDays`
4. **异常处理**：异常拦截器会捕获所有未处理的异常，确保不影响应用正常运行

## 最佳实践

1. **开发环境**：使用`LogCollectorConfig.development()`，启用所有拦截器
2. **生产环境**：使用`LogCollectorConfig.production()`，只收集警告和错误日志
3. **网络输出**：使用`BatchLogOutput`包装网络输出器，减少网络请求
4. **标签分类**：使用有意义的标签对日志进行分类，便于后续查询和分析

## 示例

完整示例请参考 `example/` 目录。

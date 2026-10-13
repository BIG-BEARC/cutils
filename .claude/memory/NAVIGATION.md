# 项目代码导航

> AI 在本项目找东西的**第一站**。先看这里，定位到对应索引文件，再 Read 源码确认细节。
>
> cutils 是纯工具库（无业务页面 / 路由 / 状态管理），索引按 lib/ 领域目录组织。Flutter 专项清单见项目根 `checklist.md`。

## 想找什么 → 去哪查

| 我想找... | 查这个索引 | 源码位置 |
|---|---|---|
| 金额 / 高精度计算 | 本表 | `lib/num/`（money_utils / money_unit / num_utils，基于 decimal） |
| 内置类型扩展 | 本表 | `lib/ext/`（barrel: ext_fun.dart） |
| 字节 / 协议解析 | 本表 | `lib/byte/`（ByteUtils：可读串/base64/窗口操作；ByteWord/ByteDoubleWord 端序拆装） |
| 日期时间 | 本表 | `lib/datetime/`（DateTimeUtils / timeline_util / timer_util） |
| 正则 | 本表 | `lib/regex/`（SCREAMING_CASE 常量是既有风格，勿改） |
| JSON 编解码 | 本表 | `lib/json/json_utils.dart` |
| 加解密 | 本表 | `lib/crypto/crypto_utils.dart`（md5/sha256/hmac/base64/xor） |
| 文件 / 压缩 | 本表 | `lib/file/file_utils.dart` |
| 本地存储 | 本表 | `lib/storage/sp_util.dart`（SharedPreferences；Windows 端文件备份自愈见 sp_backup_io.dart） |
| 网络 | 本表 | `lib/net/`（connectivity / lan_utils——局域网 IPv4） |
| 设备 / 系统 | 本表 | `lib/system/`（device_info / keyboard / system_utils / version_utils——版本号比较） |
| 文本测量 / 图片 | 本表 | `lib/ui/`（calculate_utils / image_utils） |
| 事件总线 | 本表 | `lib/event/event_bus_util.dart` |
| 随机 / UUID | 本表 | `lib/identifier/` |
| 日志（薄封装 / 完整子系统） | 本表 | `lib/log/` vs `lib/log_collector/`（README 在模块内） |
| 顶层 barrel | 本表 | `lib/cutils.dart` |

| 其他 | 查这个索引 |
|---|---|
| 平台坑（支持矩阵 / 坑卡检索） | [platform-pitfalls.md](platform-pitfalls.md) |
| 项目特有代码模式 | [patterns.md](patterns.md) |
| 同行 / 领域参考系 | [reference-map.md](reference-map.md) |
| 设计决策历史 | [decisions/](decisions/) |

> 本工具库暂不建 `indexes/*.md` 子索引（模块即文件、面小直接读）；领域扩张到单目录 ≥8 文件时再拆。

## 实现新功能前的强制流程

1. **定位** —— 在上表找到对应索引文件，Read 一遍
2. **检查复用** —— 索引里如果有现成的组件 / 工具 / 抽象能用，**优先扩展或调用，不新建**
3. **遵守约定** —— 按项目编码规范实现
4. **不确定就问** —— 命名 / 位置 / 抽象边界拿不准时，反问需求方

## 索引维护规则

见 [MAINTENANCE.md](MAINTENANCE.md)

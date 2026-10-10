# 2026-09-12 crules-flutter v1.0.6 接入（老项目人工合并）

## 背景

老项目（已有 CLAUDE.md 无版本戳）走 `/crules-flutter:init` 人工合并分支：备份 CLAUDE.md.bak 后以模板为主体合并。

## 决策记录

1. **合并策略**：以 crules-flutter v1.0.6 模板为主体骨架，项目特有章节（模块地图 / log_collector / 常用命令 / 特有约定）并入为 §十三~§十六；§七填类型 B（工具库，无平台通道）；§十二附录已填。需求方选项卡确认。
2. **公开常量命名豁免**：`constant_identifier_names` / `non_constant_identifier_names` 显式 disable。理由：regex_constants（28 处）/ money_unit（7 处）等 SCREAMING_CASE 是既有风格、已按现名对外发布，重命名=破坏性改动（§十红线）。发 2.0 时可再议。
3. **analysis_options 加强基线全量启用**（strict-casts/inference/raw-types + 10 条 lint），存量告警当日清零（255→0；dart fix 187 处 + 手修类型缺陷）。
4. **踩坑复现**：模板注释「map disable 扰动列表解析」实测为 YAML 同一 mapping 混列表项与 `key: false` 触发 parse_error——rules 块必须纯 map 或纯列表形态，已在 analysis_options.yaml 注释记录。
5. **example**：独立 analysis_options，`avoid_print: false`（demo 演示输出）；5 个 `exampleN_xxx` 函数改 lowerCamelCase。
6. **既有环境性测试失败**：`file_utils_test` A3 zip 测试因 `$TMPDIR` 存在 Logitech 遗留目录 `com.logi.xlog.temp`（errno 21 Is a directory）失败，改动前即失败，与本轮无关。

## 附带代码修复（清告警顺带，非规则安装范畴）

- strict-casts 暴露的真类型缺陷：json_utils listFromJson、log_entry fromJson（4 处）、sp_util _get、calculate_utils（fontSize 补 `double?` 注解——签名从 dynamic 收紧，语义不变）
- event_bus_util：`Set<StreamSubscription>` 补类型参数、onData 补 `void` 返回类型
- system_utils：copy 后 SnackBar 补 `context.mounted` 守卫
- file_utils / log_collector：fire-and-forget Future 补 `unawaited()`

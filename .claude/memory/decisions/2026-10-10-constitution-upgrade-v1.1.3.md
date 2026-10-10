# 2026-10-10 宪法升级 v1.1.3 与分发面 git 政策落地

## 背景

crules-flutter 插件 1.1.2 → 1.1.3 升级（`claude plugin update` + `install.sh --plugin --upgrade`）。合并 7 文件（checklist.md + 进阶/ 6 篇）、memory 8 件 KEEP、CLAUDE.md 1 处冲突（模板新增「完整〔full〕」档 + 提速档改「三档通用」措辞，撞上项目特有 §十三~§十六 尾段）——人工双保留解冲突，`gen:` 标记清零，`dart analyze` 零告警。

## 决策记录

1. **分发面 git 政策（裁决区①的最终形态）**：CLAUDE.md **保持已跟踪**（今日 `e2961d4` 宪法落位为更新决策——宪法随仓可追溯）；`/checklist.md`、`/进阶/` 不进 git。`.gitignore` 的 `/CLAUDE.md` 行**保留不删**——install.sh :273-277 对三行做逐行幂等补写（行删了下次升级必写回），且脚本 :263 明示「ignore 不影响已跟踪文件，补行对 opted-in 工程无害」：该行对已跟踪的 CLAUDE.md 是惰性行，删除=与安装器打无收益的持久战。
2. **伴生 lint 基线不合并**：`analysis_options.crules-flutter.yaml` 经 diff 证实现行 `analysis_options.yaml` 为其严格超集（同规则集 map 形态 + SCREAMING_CASE 豁免两条 `false`），伴生件已删（installer 重跑可再生）。
3. **合并脚手架入 ignore**：`*.crules-base` / `*.crules-bak` / `*.crules-conflicts` 三行按 install.sh :173 规范集落 `.gitignore`（`checklist.md.crules-base` 为下轮三方合并的 base 快照，须留本机）。
4. **`.claude/` 制度资产入库待提交时定**（MAINTENANCE「git 分层」：MAINTENANCE/patterns/business-rules/INVARIANTS/decisions 进，`indexes/` 与台账五行不进）。

## 影响

- 下次 `--upgrade` 对本仓预期行为：CLAUDE.md 三方合并（base=`checklist.md.crules-base` 同机制自存快照）、分发面三行幂等跳过、脚手架三行 grep 命中不重复。
- review-ledger 口径澄清：升级裁决类条目**不入** `.review-ledger`（其 schema 为 review 发现聚合 `date/agent/fid/sev/level/verified/verdict/note`，缺字段行会被 distill 计坏行、污染误报率样本）。

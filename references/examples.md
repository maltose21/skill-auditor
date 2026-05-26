# 端到端审查样例

一份完整的调优导向审查样例。展示从"诊断问题"到"给出可执行改写"的完整流程。

## 目录

- [被审查的 skill](#被审查的-skill)
- [审查报告](#审查报告)
- [要点说明](#要点说明)

## 被审查的 skill

`csv-cleaner` — 用户的一个 CSV 清洗工具 skill。

### 当前 SKILL.md frontmatter：

```yaml
---
name: csv-cleaner
description: |
  CSV 清洗工具。用户上传 CSV 时使用。
trigger_phrases:
  - csv
  - 清洗
  - 数据清洗
  - clean csv
---
```

### 当前正文（节选）

320 行。包含一句 "ALWAYS validate the file extension before processing"，28 条 Gotchas（多数是通用的"验证输入"、"处理错误"），没有 `references/`，示例只有 `Input: file.csv → Output: clean.csv`。

---

## 审查报告

```markdown
# Skill Audit: csv-cleaner

## 规范合规

| 检查项 | 状态 | 说明 |
|--------|------|------|
| name 格式 | ✅ | `csv-cleaner` 符合规范 |
| description 存在且 ≤ 1024 字符 | ⚠️ | 存在但只有 17 个字符，过于简短 |
| description + when_to_use ≤ 1536 字符 | ✅ | 未使用 when_to_use |
| 无非法 frontmatter 字段 | ❌ | `trigger_phrases` 不是官方字段，会被 harness 忽略 |
| 目录结构合理 | ⚠️ | 无 references/ 目录，28 条 Gotchas 堆在正文里 |

## 触发诊断

**覆盖分析**："CSV 清洗工具。用户上传 CSV 时使用。" 只覆盖了"CSV + 清洗"这一种表达。用户说"帮我整理一下这个数据文件"、"fix the encoding in this tsv" 时不会触发。

**undertrigger 风险**：高。description 太短且缺少关键词。以下场景大概率不触发：
- "this csv has BOM and our parser is choking"
- "帮我去掉重复行"
- "规范化这个表的列名"

**overtrigger 风险**：低（description 太短反而限制了误触发）。

**改进建议**：

将 `trigger_phrases` 删除（非法字段），用充实的 description 替代：

```yaml
description: 清洗与规范化 CSV/TSV 文件——修复编码、去重、推断类型、统一列名。当用户分享 CSV/TSV 文件并要求"清洗"、"整理"、"规范化"、"修复编码"、"去重"或"准备好用"时使用。即使用户没有说"CSV"，只要上下文涉及表格数据清理都应该触发。不要用于 spreadsheet 公式工作（那是 xlsx-formulas 的事），也不要用于把 CSV 导入数据库（那是 data-loader 的事）。
```

## 内容效能

**SKILL.md 行数**：320 行 ✅
**简洁性**：28 条 Gotchas 中约 22 条是通用平台话（"验证输入"、"处理错误"），不提供 Claude 不已知的信息。
**渐进披露**：所有内容堆在 SKILL.md 里。6 条有价值的 Gotchas 被 22 条噪声稀释。
**指令风格**："ALWAYS validate the file extension before processing" — 没有解释 why，Claude 无法泛化。

## 改进方案

### 高优先级 — 2 项

**description 过短 + 非法字段 `trigger_phrases`**
- 原因：`trigger_phrases` 不是官方 frontmatter 字段，harness 会忽略它。description 只有 17 字符，Claude 在 100+ 个 skill 中无法准确匹配用户意图。
- 当前：
  ```
  description: CSV 清洗工具。用户上传 CSV 时使用。
  trigger_phrases: [csv, 清洗, 数据清洗, clean csv]
  ```
- 改为：删除 `trigger_phrases`，用上面触发诊断中的 description 替代。

**ALL-CAPS 规则没有 why**
- 原因：Claude 遇到没有理由的 ALWAYS 会机械执行但无法泛化到类似场景。官方最佳实践建议解释 why。
- 当前：`ALWAYS validate the file extension before processing. NEVER read files larger than 1GB.`
- 改为：
  ```
  读文件之前先核对扩展名——一个表面是 .csv 实际是 .xlsx 的文件会让 pandas 抛出难懂的解析错误。
  文件超过 1GB 时切到分块读取（pandas chunksize=）——一次性加载会在多数机器上把内存吃光。
  ```

### 建议改进 — 2 项

**28 条 Gotchas 中 22 条是通用套话**
- 原因：通用的"验证输入"对 Claude 没有帮助，反而稀释真正有价值的提醒。token 是公共资源。
- 当前：诸如"验证输入格式"、"处理空值"、"检查文件路径是否存在"。
- 改为：保留 6 条具体的（如"Windows Excel 导出的 CSV 常用 GBK 编码而非 UTF-8"），把它们收进 `references/gotchas.md`，SKILL.md 正文只留 3-4 条最关键的并指向 reference 文件。

**示例太模板化**
- 原因：`Input: file.csv → Output: clean.csv` 没有真实内容，Claude 看不到什么是"好的清洗结果"。
- 改为：给一个有背景的真实示例：
  ```
  ## 示例
  用户输入："got this messy customer export from salesforce, can you clean it up? ~/Downloads/customers_2024.csv"
  处理步骤：检测编码（UTF-8 with BOM → 转为 UTF-8）→ 去重（按 email 列）→ 统一日期格式 → 保存为 customers_2024.cleaned.csv
  输出摘要：
    rows in:  2,847
    rows out: 2,391 (456 duplicates removed)
    encoding: UTF-8 with BOM → UTF-8
  ```

### 可选优化 — 1 项

**引入 references/ 目录**
- 原因：Gotchas 拆出去后，正文更聚焦工作流。未来如果加更多编码/格式处理细节，有地方放。
- 改为：新建 `references/gotchas.md`，SKILL.md 加一句"完整的失败模式目录见 [gotchas.md](references/gotchas.md)"。

## 触发测试集

| # | Query | 应触发 | 理由 |
|---|-------|--------|------|
| 1 | "got this messy customer export from salesforce, can you clean it up? it's at ~/Downloads/customers_2024.csv" | ✅ | 核心场景：clean + .csv + 真实背景 |
| 2 | "this tsv 的表头有空格还有大小写不一致，帮我规范化" | ✅ | tsv 变体 + 规范化是触发意图 |
| 3 | "我的 csv 里有一堆重复行，帮我去重" | ✅ | 中文 + 去重 + csv |
| 4 | "this csv has BOM and our parser is choking on it" | ✅ | 编码修复是 skill 本职 |
| 5 | "fix the column types — 日期列被读成了字符串" | ✅ | 类型推断在范围内 |
| 6 | "tidy this data dump, it's a total mess" | ✅ | "tidy" + 文件上下文 |
| 7 | "给这个 spreadsheet 加一个 vlookup，从主表里把价格拉过来" | ❌ | xlsx 公式工作，不是清洗 |
| 8 | "把这个 csv 装进我们的 postgres 数仓" | ❌ | 数据导入，不是清洗 |
| 9 | "把这个 csv 转成 json 格式" | ❌ | 格式转换不是清洗（近误：都涉及 csv） |
| 10 | "csv 里有一列是逗号分隔的标签，我要把它展开成多行" | ❌ | reshape/transform，不是 clean |

## 健康度评估

**总体：2.6 / 5**

| 维度 | 得分 | 简评 |
|------|------|------|
| 触发准确性（35%） | 2/5 | description 过短 + 非法字段，边缘场景大概率漏触发 |
| 内容效能（25%） | 2/5 | ALL-CAPS 无 why，通用 Gotchas 浪费 token |
| 渐进披露（20%） | 3/5 | 行数可接受但该拆的没拆 |
| 规范合规（10%） | 2/5 | trigger_phrases 非法字段 |
| 输出可验证（10%） | 2/5 | 输出格式靠文字描述，没有模板 |
```

## 写好审查报告的要点

- **改进建议是核心**：读者看完报告应该知道"改哪里、为什么改、改成什么"，不是只知道"这个 skill 得了 2.6 分"
- **引用官方规范**：每条"原因"都应该能在官方文档中找到依据
- **query 要真实**：测试 query 里有文件路径、工具名字、口语化表述——真实用户就这样输入
- **逐字引用**：让用户能直接 Cmd+F 搜索定位要改的那一行

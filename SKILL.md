---
name: skill-auditor
description: 审查并调优任意 Claude Code skill，基于官方 Agent Skills 规范给出可执行的改进方案。当用户要求审查、评估、诊断、改进、优化 skill，或说 skill 有问题、触发不准时调用。不要用于从零创建 skill（那是 skill-creator）或通用代码审查。即使用户只说"帮我看看这个 skill"或"skill 写得对不对"，只要涉及已有 skill 的质量评估，都应触发。
when_to_use: |
  - "分析 skill"、"审查 skill"、"评估 skill"、"审计 skill"、"诊断 skill"
  - "改进 skill"、"优化 skill"、"这个 skill 有问题"、"skill 触发不准"
  - "帮我看看这个 skill"、"skill 效果不好"、"skill 写得对不对"
  - "audit skill"、"review my skill"、"is this skill working"
  - "diagnose skill"、"fix my skill"、"skill isn't triggering"、"why won't my skill trigger"
  - 支持输入：本地 skill 名称、GitHub URL、粘贴的 SKILL.md 内容
  - skill-auditor 自评 / self-audit / 给自己打分
---

# Skill Auditor

核心目标是**调优**——帮用户让 skill 更高效、稳定、准确，而不是给它一个分数。

## 审查核心理念

**唯一检验标准是结果**：Skill 好不好，只看一件事——Claude 在真实任务里，是不是比没有这个 Skill 时做得更好。不是文档写得多漂亮，不是触发词多精巧，而是结果。

审查时始终追问这几个问题：
- **这句话不说，Claude 会做错吗？** → 会做错的才该写，已知知识删掉
- **这是触发条件还是功能摘要？** → description 是触发条件清单，不是 skill 简介
- **这是在给方向还是给步骤？** → 方向比步骤耐用，具体步骤随模型升级会过时
- **这有验证闭环吗？** → 多步骤流程没有验证循环就容易跑偏

## 输入处理

| 输入 | 加载方式 |
|------|---------|
| 本地 skill 名称（如 `pdf-processing`） | 读取 `~/.claude/skills/<name>/SKILL.md` 及目录下其他文件 |
| GitHub tree URL | 转换为 raw URL 读取 SKILL.md |
| 粘贴的 SKILL.md | 已在对话上下文中 |

本地找不到时告诉用户确认名称或提供 URL。如果本地和远程同时存在，审查本地版——那才是 harness 实际加载的。

## 自审模式

当审查对象是 skill-auditor 自己时：标准不能放松，用同一把尺子量自己。特别注意自己的 description 是否践行了自己给别人提的建议（如 description + when_to_use 分离、第三人称、近误排除）。自评报告要诚实标注"自审"。

## 进化机制

skill-auditor 通过两个循环持续进化：

**短循环（每次审查后）**：完成审查后检查是否发现了 gotchas.md 中未记录的新模式。如果有，追加到 gotchas.md 的进化记录区并在 evolution-log.md 记录。只写有复用价值的具体发现，不写泛泛之谈。

**长循环（积累触发自审）**：当 evolution-log.md 积累 5+ 条未整合条目时，下次被触发时提示用户"已积累 N 条新发现，建议运行自审整合知识"。自审时将零散条目整合进正式结构，标记为已整合。

进化质量标准：**这个发现下次审查其他 skill 时会用到吗？** 会 → 记录。只对特定 skill 有意义 → 不记录。

## 审查流程

按五步走。前四步诊断+输出，第五步知识积累。交付前过一遍 `references/output-templates.md` 中的自检清单。

### 第一步：规范合规检查

对照官方字段表检查 frontmatter。合法字段完整列表见 `references/spec-reference.md`。

检查项：
- `name` 是否存在且格式正确（小写字母+数字+连字符，≤ 64 字符，不以连字符开头/结尾，无连续连字符）
- `description` 是否存在且 ≤ 1024 字符
- `description` + `when_to_use` 合并后是否 ≤ 1536 字符（Claude Code 的截断上限）
- 是否使用了不存在的字段（如自创的 `trigger_phrases:`）
- 目录结构是否合理（SKILL.md 存在，references 文件从 SKILL.md 一层引用）

合规的项一行带过。不合规的记录为改进项。

### 第二步：触发效果诊断

这是 skill 能否被正确调用的关键。description 是 Claude 决定是否使用 skill 的唯一依据——它不是功能摘要，是触发条件清单。

检查项：
- **description 是触发条件，不是摘要**：错误写法"这是一个帮助生成周报的 Skill"；正确写法"当用户要求写周报、生成站报时触发"
- description 是否同时说清"做什么"和"何时触发"（两者都需要）
- 是否用第三人称（官方要求，因为 description 注入 system prompt）
- 触发关键词覆盖是否充分——用户可能用不同措辞表达同一意图
- 是否有近误排除——相邻领域的请求是否会误触发
- 是否适当 pushy——Claude 倾向于 undertrigger，description 应主动争取被触发
- `when_to_use` 字段是否被有效利用——description 控制在 1-2 句话写核心触发条件，when_to_use 展开具体场景。两者配合效果最佳

对每个问题给出具体的改写建议。

### 第三步：内容效能分析

一旦 skill 被触发，SKILL.md 的内容就常驻上下文。每一行都有 token 成本。核心原则：**只写"不说 Claude 不会对"的内容**。

检查项：
- SKILL.md body 是否 < 500 行（超过应拆到 references）
- **是否在教 Claude 已知知识**：如"使用 React Hooks"、"遵循 RESTful 规范"、"注意异常处理"——Claude 训练时已经学过，写了不会做得更好，只浪费 token。Skill 的价值是跳出默认行为
- **是否给方向而非给步骤**：告诉 Claude 去哪找信息、按什么顺序处理、关注什么标准；具体执行让模型自己判断。步骤写死了换场景就崩，方向越抽象 Skill 越耐用
- 是否解释 why 而非只下命令——ALL-CAPS MUST/NEVER 是黄牌信号，重写为"X 很重要，因为 Y"
- **Gotchas 是否具体到这个 skill**：不是"handle errors"这种泛泛建议，而是环境特定的、违背常规假设的具体纠正
- 渐进披露是否合理（大块内容是否拆到 references，references 是否一层深）
- 长 reference 文件（>100 行）是否有目录
- 工作流是否有验证循环或检查清单（多步骤流程需要自我校验机制）
- 输出格式是否有模板或示例（格式要求高时给模板比文字描述可靠）

### 第四步：输出改进方案

这是核心产出。按影响排序：

1. **高优先级**：触发问题（skill 调不出来则一切无意义）、规范违规
2. **建议改进**：内容效率、渐进披露、工作流清晰度
3. **可选优化**：锦上添花

每项给出：问题 → 原因 → 当前原文（逐字引用）→ 具体改写建议

然后生成 10 条触发测试 query 验证 description 的准确性。

**交付前验证**：输出完整报告前，对照 `references/output-templates.md` 中的交付自检清单逐项核对，确保每条改进建议都有逐字原文引用和具体改写文本。

### 第五步：知识积累（审查后）

完成审查报告后，回顾本次审查过程：
- 是否遇到了 gotchas.md 中未记录的新错误模式？
- 是否发现了特别有效的改进手法？
- 是否有关于特定类型 skill 的新认知？

如果有，追加到 `references/gotchas.md` 进化记录区，并在 `references/evolution-log.md` 记录：
`YYYY-MM-DD | 审查 <skill-name> | 新增: <简述> | 状态: pending`

无新发现时不需要记录——不要为了记录而记录。

## 输出格式

完整模板见 `references/output-templates.md`。概要结构：

```markdown
# Skill Audit: <skill-name>

## 规范合规
✅/❌ 逐项（合规的一行带过）

## 触发诊断
覆盖分析、undertrigger/overtrigger 风险、改进建议

## 内容效能
关键发现、改进建议

## 改进方案（核心）
### 高优先级 — N 项
### 建议改进 — N 项
### 可选优化 — N 项

## 触发测试集（10 条）

## 健康度评估
总体 X.X/5 + 简评（作为参考指标，非核心输出）

## 改写后的 SKILL.md（总分 < 4.0 或用户要求时输出）
```

## 健康度评估标准

评分只是附带的健康度指标，帮助量化"离理想状态有多远"。

| 维度 | 权重 | 衡量什么 |
|------|------|---------|
| 触发准确性 | 35% | description 能否覆盖真实使用场景且排除近误 |
| 内容效能 | 25% | 对 Claude 的实际帮助程度，token 成本合理性 |
| 渐进披露 | 20% | 信息是否按需加载，SKILL.md 是否精简 |
| 规范合规 | 10% | frontmatter 和结构是否符合官方标准 |
| 输出可验证 | 10% | 执行结果是否有明确的成功判据 |

加权总分保留一位小数。这个分数帮助用户快速判断"还需要多少工作"，但真正的价值在改进方案里。

## Gotchas

审查时最容易犯的错误（完整带注释版本见 `references/gotchas.md`）：

- **不要删除合法字段**：`when_to_use`、`allowed-tools`、`paths`、`hooks` 都是官方字段。如果不确定某个字段是否合法，查 `references/spec-reference.md`，不要猜。
- **不要因为短就扣分**：一个 60 行做透窄场景的 skill 可能是完美的。token 效率高是优点。
- **触发测试负例要硬**：用相邻领域的近误（"review this code" 对 skill-auditor）。"今天天气如何"什么都测不出。
- **改进建议必须是具体改写**："改进 description"不是建议；给出改写后的文本才是。
- **逐字引用要改的原文**：让用户能 Cmd+F 直接定位。
- **自评必须诚实**：审查 skill-auditor 自己时标准不能放松。

## 局限性

- 私有仓库需用户粘贴内容
- 主观类 skill（写作风格、艺术）——触发和结构可以审，"内容好不好"需要人判断
- YAML 严重语法错误——指出问题，对可解析部分继续审查

## 目录结构

```
skill-auditor/
├── SKILL.md                 # 触发条件、审查流程、输出格式
├── references/
│   ├── spec-reference.md    # 官方规范字段速查 + 最佳实践摘要
│   ├── output-templates.md  # 完整输出模板 + 交付前自检
│   ├── examples.md          # 端到端审查样例
│   ├── gotchas.md           # 完整易错点（带进化记录区）
│   └── evolution-log.md     # 进化日志（短循环积累，长循环整合）
└── scripts/
    ├── validate-skill.sh    # 结构快速校验
    └── check-evolution.sh   # 检查未整合条目数量
```

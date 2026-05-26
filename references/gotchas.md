# 易错点全集

审查 skill 时最容易犯的错误。每条都是真实发生过的，不是假设。

## 目录

- [规范认知](#规范认知)
- [触发判断](#触发判断)
- [评估偏差](#评估偏差)
- [改进建议质量](#改进建议质量)
- [测试集质量](#测试集质量)
- [边界情况](#边界情况)
- [被审查 skill 的常见错误模式](#被审查-skill-的常见错误模式)
- [进化记录区](#进化记录区)

## 规范认知

### 不要删除合法字段

`when_to_use`、`allowed-tools`、`paths`、`hooks`、`arguments`、`context`、`model`、`effort` 都是 Claude Code 官方 frontmatter 字段。审查时如果建议删除某个字段，先查 `spec-reference.md` 确认它是否在官方字段表中。

真正应该建议删除的非法字段示例：`trigger_phrases:`、`when_to_use_not:`（自创的）、`category:`（不存在）。

### when_to_use 与 description 的关系

`when_to_use` 是 Claude Code 的扩展字段。它的内容追加到 `description` 之后，合并显示在 skill 列表中，共享 1536 字符截断上限。两者是互补的，不是重复的：
- `description`：做什么 + 核心触发场景
- `when_to_use`：补充触发场景、边缘案例

如果一个 skill 同时有 `description` 和 `when_to_use` 且内容不重复，这是合理用法，不要建议删除。如果内容完全重复，才建议合并。

### name 不决定命令名

命令名来自目录名，不来自 `name` 字段。`name` 只是显示标签。唯一例外是 plugin root SKILL.md（没有 skill 目录时用 `name` 做命令名）。

## 触发判断

### 不要触发"创建新 skill"

"写一个新 skill"、"create a skill for X" → 那是 skill-creator 的事。skill-auditor 审查已有 skill，不创作新 skill。

### 不要触发通用代码审查

"review this PR"、"优化这段代码" → 不是 skill 质量审查。识别信号：需要同时出现"skill"这个词 + 评估类动词。

### skill 名的大小写与分隔符

`Skill-Auditor` 与 `skill-auditor` 解析到同一目录。`skill auditor`（带空格）则不行。遇到非常规形式先归一化到 kebab-case 再查。

## 评估偏差

### 不要因为短就扣分

一个 60 行做透窄场景的 skill 可能是完美的。简洁是优点——减少 token 消耗。官方最佳实践的核心原则就是"只加 Claude 不已知的信息"。

### 不要奖励"全面感"

长长的 ALL-CAPS 规则、30 条自验证清单、40 条通用 Gotchas——这些看起来"花了功夫"，但对 Claude 的实际帮助可能很低。问："去掉这一段，Claude 做对的概率会降低吗？"

### 自评偏倚

审查 skill-auditor 自己时，倾向给宽分。同样的标准照样适用——抓自己毛病才是这个 skill 的价值。

## 改进建议质量

### "改进 description"不是建议

必须给出具体的改写文本。用户看到"改进 description"不知道怎么动手。"把 description 改写为：`<具体文本>`"才是建议。

### 逐字引用要改的原文

"当前"字段逐字抄原文，不要 paraphrase。用户需要 Cmd+F 搜索定位要改的那一行。

### 改进原因要引用官方依据

"因为官方最佳实践建议用第三人称写 description" 比 "因为第三人称更好" 更有说服力。spec-reference.md 中有所有规范出处。

## 测试集质量

### 负例必须是近误

"写一首诗"对任何技术 skill 都是无效负例。要用相邻领域的 query：
- csv-cleaner 的近误："把 csv 转成 json"（都涉及 csv，但不是清洗）
- skill-auditor 的近误："review this code"（都是审查，但不是 skill 审查）

### query 要像真实用户输入

有文件路径、口语化表达、背景上下文。"clean this csv" 太干净，测不到触发。"got this messy export from salesforce, ~/Downloads/customers_2024.csv" 更真实。

### JSON 布尔值

`should_trigger: true`，不是 `"true"`。字符串会让下游工具出错。

## 边界情况

### SKILL.md 过大

超过 ~10K tokens 时提醒用户，可以分块审查或聚焦某几个维度。

### YAML 语法错误

指出语法问题，对可解析部分继续审查。文档完整性相关维度降分。

### description 用 `>` 而非 `|`

`description: >` 会把换行变成空格，可能悄悄改变语义。看到了就提醒用户确认意图。

### name 与目录名不一致

官方规范要求 name 必须与父目录名一致。如果不一致，在报告中指出。

### 主观类 skill

写作风格、艺术类 skill——触发和结构可以审，"内容好不好"需要人判断。在报告中说明哪些维度是主观的。

## 被审查 skill 的常见错误模式

审查时识别这些模式，作为改进建议的依据：

| 错误类型 | 具体表现 | 正确做法 |
|---------|---------|---------|
| description 写成摘要 | "这是一个帮助生成周报的 Skill" | 写成触发条件："当用户说...时触发" |
| 一股脑塞进 SKILL.md | 2000 行大文档 | 拆分成 references/ + scripts/ |
| 教 Claude 已知知识 | "使用 React Hooks"、"遵循 RESTful" | 只教团队独有的规范和经验 |
| 指令过于具体 | "第一步做A，第二步做B，第三步做C" | 给方向，让模型自己判断 |
| 没有持续维护 | 写完就扔 | 建立 Gotchas 章节持续积累 |
| 缺少验证机制 | 多步骤流程无检查点 | 加验证循环和检查清单 |
| 输出格式不明确 | 只说"格式要规范" | 给模板，让 Claude 照着输出 |
| 跳过测试迭代 | 写完直接用 | 用真实 query 测试并迭代 |
| Gotchas 是通用建议 | "验证输入"、"处理错误" | 写环境特定的具体纠正 |

## 进化记录区

以下是审查过程中积累的新发现。积累 ≥ 5 条时触发自审，整合到上方正式分类中。

（随使用积累）

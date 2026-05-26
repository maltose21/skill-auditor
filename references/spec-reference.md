# 官方规范速查

审查 skill 时的权威参考。所有字段和规则来源于 Agent Skills 开放标准（agentskills.io/specification）和 Claude Code 官方文档（code.claude.com/docs/en/skills）。

## 目录

- [Frontmatter 字段速查](#frontmatter-字段速查)
- [description 写作规范](#description-写作规范)
- [渐进披露规范](#渐进披露规范)
- [内容写作规范](#内容写作规范)
- [Skill 生命周期](#skill-生命周期)
- [description 调优方法论](#description-调优方法论)
- [Skill 作为工作流引擎](#skill-作为工作流引擎)

## Frontmatter 字段速查

### Agent Skills 开放标准字段

这些字段在所有支持 Agent Skills 的工具中通用（Claude Code、Cursor、Gemini CLI、GitHub Copilot 等）。

| 字段 | 必填 | 约束 |
|------|------|------|
| `name` | 是 | ≤ 64 字符。仅小写字母、数字、连字符。不能以连字符开头/结尾，不能连续连字符。必须与父目录名一致 |
| `description` | 是 | ≤ 1024 字符。非空。描述做什么+何时触发 |
| `license` | 否 | 许可证名称或引用文件 |
| `compatibility` | 否 | ≤ 500 字符。环境要求说明 |
| `metadata` | 否 | 键值对映射，自定义元数据 |
| `allowed-tools` | 否 | 空格分隔的预批准工具列表（实验性） |

### Claude Code 扩展字段

这些字段是 Claude Code 在开放标准之上的扩展。

| 字段 | 说明 |
|------|------|
| `when_to_use` | 追加到 description 之后显示在 skill 列表中，共享 1536 字符上限。用于补充触发场景 |
| `argument-hint` | 自动补全时显示的参数提示，如 `[issue-number]` |
| `arguments` | 命名位置参数，支持空格分隔字符串或 YAML 列表 |
| `disable-model-invocation` | `true` 时 Claude 不会自动加载此 skill，只能用户手动 `/name` 调用 |
| `user-invocable` | `false` 时从 `/` 菜单隐藏，仅 Claude 自动调用 |
| `model` | 覆盖当前 turn 的模型 |
| `effort` | 推理深度：`low`/`medium`/`high`/`xhigh`/`max` |
| `context` | `fork` 时在独立子 agent 中运行 |
| `agent` | `context: fork` 时使用的子 agent 类型 |
| `hooks` | skill 生命周期钩子 |
| `paths` | glob 模式，限制 skill 仅在匹配文件时自动激活 |
| `shell` | `bash`（默认）或 `powershell` |

### 常见误解澄清

- **`when_to_use` 是合法字段**，不是反模式。它追加到 description 后面，合并后截断在 1536 字符。适合把触发场景从 description 中分离出来
- **`trigger_phrases:` 是非法字段**——官方规范里不存在这个字段。触发靠 description 的语义匹配，不靠关键词数组
- **`name` 不决定命令名**——命令名来自目录名。`name` 只是显示标签（plugin root SKILL.md 例外）
- **所有字段都是可选的**——只有 description 被"推荐"，因为没有它 Claude 不知道何时使用

## description 写作规范

来源：官方最佳实践文档。

**核心认知：description 是触发条件清单，不是功能摘要。**

错误写法：`description: 这是一个帮助生成周报的 Skill`
正确写法：`description: 当用户要求写周报、生成站报时触发。支持从工作日志自动提炼要点。`

规则：
1. **同时写"做什么"和"何时触发"**——description 是 Claude 选择 skill 的唯一依据
2. **用第三人称**——description 注入 system prompt，人称不一致会干扰触发
3. **包含具体关键词**——Claude 从 100+ 个 skill 中选择，关键词帮助匹配
4. **适度 pushy**——Claude 倾向 undertrigger。与其写"Helps with PDFs"，不如写"Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or when the user mentions PDFs, forms, or document extraction."
5. **排除近误**——明确说不要在什么情况下触发

**description + when_to_use 配合模式**：description 控制在 1-2 句话写核心触发条件（≤ 1024 字符硬限制），when_to_use 展开具体触发场景和边缘案例。两者合并后截断在 1536 字符。当安装了相似 skill 时，when_to_use 尤其重要，用来细分场景。

## 渐进披露规范

三层加载架构：

| 层级 | 何时加载 | Token 预算 |
|------|---------|-----------|
| Metadata（name + description） | 启动时，始终在 context | ~100 tokens/skill |
| SKILL.md body | skill 被触发时 | < 5000 tokens（推荐 < 500 行） |
| references/scripts | 按需 | 无限制 |

关键规则：
- SKILL.md body < 500 行
- reference 文件从 SKILL.md 一层引用，避免嵌套链
- 长 reference 文件（>100 行）加目录
- 按领域组织 reference（不是 file1.md, file2.md）
- 文件名要有描述性

## 内容写作规范

来源：官方最佳实践 + skill-creator + Karpathy 四原则。

### 核心原则：只写"不说 Claude 不会对"的内容

每次审查 skill 中的每一段内容时问："我不说的话，Claude 会做对吗？"
- 会 → 删掉（在浪费 token）
- 不会 → 这就是该写的东西

**反面典型**："使用 React Hooks"、"遵循 RESTful 规范"、"注意异常处理"——Claude 训练时已经学过，写了不会让它做得更好。

**正面典型**：团队独有的命名规范、数据库表的 soft delete 规则、特定 API 的怪异行为——这些 Claude 不可能自己知道。

### 给方向，不给步骤

指令越抽象，Skill 越耐用。步骤写死了换场景就崩，模型在变强，僵化的步骤反而限制发挥。

- 错误：`第一步做A，第二步做B，第三步做C`
- 正确：`告诉 Claude 去哪找信息、按什么顺序处理、关注什么标准，具体执行让模型自己判断`

### 目标驱动，不是过程驱动（Karpathy）

告诉 Claude "做到什么"而非"怎么做"：
- 错误："添加输入验证"
- 正确："为非法输入写测试用例，然后让测试通过"

### 其他规则

- **祈使语气**——"Run the validation script" 而非 "You should run the validation script"
- **解释 why**——"读文件之前先核对扩展名——一个 .csv 实际是 .xlsx 的文件会让 pandas 抛出难懂错误" 优于 "ALWAYS validate the file extension"
- **匹配自由度与脆弱性**——脆弱操作（数据库迁移）给精确脚本；灵活任务（代码审查）给方向性指导
- **避免时效性信息**——不要写"如果在 2025 年 8 月之前"
- **术语一致**——全文统一用词
- **默认方案 + 逃生舱**——"Use pdfplumber for text extraction. For scanned PDFs requiring OCR, use pdf2image instead." 而不是列出 5 个选项

### Gotchas 的正确写法

Gotchas 不是通用建议，是环境特定的、违背常规假设的具体纠正：

错误："处理错误情况"、"验证输入"
正确：
```
- users 表用 soft delete。查询必须加 WHERE deleted_at IS NULL，否则结果包含停用账号。
- /health 端点只检查 web server 是否运行，不检查数据库。用 /ready 检查完整服务健康。
```

### 验证机制

多步骤工作流应该有自我校验机制：
- **验证循环**：编辑 → 运行验证脚本 → 失败就修改重来 → 通过才继续
- **Plan-Validate-Execute**：先创建计划 → 验证通过 → 再执行（适合批量/破坏性操作）
- **检查清单**：用 `- [ ]` 帮 Claude 追踪进度

## Skill 生命周期

一旦 skill 被触发，渲染后的 SKILL.md 进入对话并在整个会话中保留。Claude Code 不会在后续 turn 重新读取文件。自动压缩时保留每个 skill 最近一次调用的前 5000 tokens，所有 skill 共享 25000 tokens 预算。

## description 调优方法论

当 skill 触发不准时，可以系统性优化 description：

### 1. 设计测试集
准备约 20 条 query：8-10 条应该触发，8-10 条不应该触发。关键是设计"近误触发"案例——共享关键词但实际不需要这个 skill 的 query。

### 2. 运行测试
每个 query 多跑几次（建议 3 次），计算触发率。应触发的应高于 0.5，不应触发的应低于 0.5。

### 3. 训练集/验证集分离
- 训练集（60%）：指导修改方向
- 验证集（40%）：检验改进是否泛化

只用全部 query 来调 description 容易过拟合——只对特定表述有效，换一种说法就不行。

### 4. 迭代优化
- 应触发的没触发 → 描述太窄，要拓宽
- 不应触发的触发了 → 描述太宽，要收窄
- 避免把失败 query 的具体关键词直接写进去（那是过拟合）
- 3-5 轮迭代通常足够

## Skill 作为工作流引擎

Skill 不只是一个 markdown 文件，它可以是一套工作流：
- **context: fork**：复杂或有副作用的操作在隔离子代理中运行，主对话不被中间步骤污染
- **动态上下文注入**：`!`\`command\` 语法在 skill 内容发送给 Claude 之前运行命令并注入输出
- **子 Skill 编排**：主 Skill 做编排，子 Skill 各司其职

写 Skill 时想清楚：是单纯执行一个任务，还是要和其他 Skill 配合？如果是后者，把子 Skill 的调用方式写清楚。

# Skill Auditor

基于官方 Agent Skills 规范审查并调优任意 Claude Code skill。

## 核心理念

**目标是调优，不是打分。** 输出可执行的改进方案，帮助 skill 更高效、稳定、准确。健康度评分只是附带的参考指标。

## 审查依据

- [Agent Skills 开放标准](https://agentskills.io/specification)
- [Claude Code Skills 文档](https://code.claude.com/docs/en/skills)
- [Skill 写作最佳实践](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)

## 使用方式

| 输入 | 示例 |
|------|------|
| 本地 skill 名称 | "审查 pdf-processing" |
| GitHub URL | "评估 https://github.com/user/repo/tree/main/my-skill" |
| 粘贴内容 | 直接粘贴 SKILL.md 内容 |

## 审查流程

1. **规范合规** — 对照官方字段表检查 frontmatter
2. **触发诊断** — description 是否能准确触发 + 排除近误
3. **内容效能** — 简洁性、渐进披露、指令质量
4. **改进方案** — 具体可执行的改写建议（核心输出）

## 目录结构

```
skill-auditor/
├── SKILL.md                 # 触发条件、审查流程、输出格式
├── references/
│   ├── spec-reference.md    # 官方规范字段速查 + 最佳实践摘要
│   ├── output-templates.md  # 完整输出模板 + 交付前自检
│   ├── examples.md          # 端到端审查样例
│   └── gotchas.md           # 易错点全集
└── scripts/
    └── validate-skill.sh    # 结构快速校验
```

## License

MIT

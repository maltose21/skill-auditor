#!/bin/bash
# 检查 evolution-log.md 中 pending 条目数量（只统计"## 记录"之后的行）
LOG="$HOME/.claude/skills/skill-auditor/references/evolution-log.md"
if [ ! -f "$LOG" ]; then
    echo "0"
    exit 0
fi
PENDING=$(sed -n '/^## 记录/,$p' "$LOG" | grep -c "状态: pending")
if [ $? -ne 0 ]; then
    PENDING=0
fi
echo "$PENDING"
if [ "$PENDING" -ge 5 ]; then
    echo "⚠️ 已积累 ${PENDING} 条未整合发现，建议运行自审整合知识"
fi

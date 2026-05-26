#!/bin/bash
# skill-auditor 辅助脚本：基于官方 Agent Skills 规范验证 skill 文件结构和 frontmatter

SKILL_PATH="${1:?用法: $0 <skill-path>}"

echo "=== Skill 结构验证（基于官方规范） ==="
echo ""

# 检查 SKILL.md 是否存在
if [ ! -f "$SKILL_PATH/SKILL.md" ]; then
    echo "❌ 缺少 SKILL.md（必需文件）"
    exit 1
fi
echo "✅ SKILL.md 存在"

# 检查 frontmatter 存在
FRONTMATTER=$(sed -n '/^---$/,/^---$/p' "$SKILL_PATH/SKILL.md")
if [ -z "$FRONTMATTER" ]; then
    echo "❌ 缺少 YAML frontmatter（---...--- 块）"
    exit 1
fi
echo "✅ YAML frontmatter 存在"

# 检查 name 字段
NAME=$(echo "$FRONTMATTER" | grep "^name:" | sed 's/^name: *//')
if [ -n "$NAME" ]; then
    echo "✅ name: $NAME"
    # 验证格式：小写+数字+连字符，不以连字符开头结尾
    if echo "$NAME" | grep -qE '^[a-z0-9]([a-z0-9-]*[a-z0-9])?$'; then
        if echo "$NAME" | grep -q '\-\-'; then
            echo "  ⚠️ name 包含连续连字符（官方规范不允许）"
        else
            echo "  ✅ name 格式符合规范"
        fi
    else
        echo "  ❌ name 格式不合规（需要：小写字母+数字+连字符，不能以连字符开头/结尾）"
    fi
    # 检查长度
    if [ ${#NAME} -gt 64 ]; then
        echo "  ❌ name 超过 64 字符限制（当前 ${#NAME} 字符）"
    fi
    # 检查目录名一致性
    DIR_NAME=$(basename "$SKILL_PATH")
    if [ "$NAME" != "$DIR_NAME" ]; then
        echo "  ⚠️ name ($NAME) 与目录名 ($DIR_NAME) 不一致（官方规范要求一致）"
    fi
else
    echo "⚠️ 未设置 name 字段（推荐设置）"
fi

# 检查 description 字段
DESC=$(echo "$FRONTMATTER" | grep "^description:" | sed 's/^description: *//')
if [ -n "$DESC" ]; then
    DESC_LEN=${#DESC}
    echo "✅ description 存在（$DESC_LEN 字符）"
    if [ "$DESC_LEN" -gt 1024 ]; then
        echo "  ❌ description 超过 1024 字符限制"
    fi
else
    # 可能是多行 description
    if echo "$FRONTMATTER" | grep -q "^description:"; then
        echo "✅ description 存在（多行格式）"
    else
        echo "❌ 缺少 description 字段（强烈推荐，Claude 靠它决定何时触发 skill）"
    fi
fi

# 检查非法字段
echo ""
echo "=== 非法字段检查 ==="
ILLEGAL_FIELDS=("trigger_phrases" "triggers" "when_to_use_not" "category" "tags" "priority" "version")
FOUND_ILLEGAL=false
for field in "${ILLEGAL_FIELDS[@]}"; do
    if echo "$FRONTMATTER" | grep -q "^${field}:"; then
        echo "❌ 非法字段: $field（官方规范中不存在此字段）"
        FOUND_ILLEGAL=true
    fi
done
if [ "$FOUND_ILLEGAL" = false ]; then
    echo "✅ 未发现非法字段"
fi

# 检查目录结构
echo ""
echo "=== 目录结构 ==="
if [ -d "$SKILL_PATH/references" ]; then
    echo "✅ references/ 目录存在"
    REF_COUNT=$(find "$SKILL_PATH/references" -name "*.md" | wc -l | tr -d ' ')
    echo "  包含 $REF_COUNT 个参考文件"
else
    echo "ℹ️ 无 references/ 目录（可选，内容多时建议添加）"
fi

if [ -d "$SKILL_PATH/scripts" ]; then
    echo "✅ scripts/ 目录存在"
else
    echo "ℹ️ 无 scripts/ 目录（可选）"
fi

# 检查 SKILL.md 行数
echo ""
echo "=== 内容规模 ==="
LINE_COUNT=$(wc -l < "$SKILL_PATH/SKILL.md" | tr -d ' ')
echo "SKILL.md 行数: $LINE_COUNT"
if [ "$LINE_COUNT" -gt 500 ]; then
    echo "  ⚠️ 超过 500 行推荐上限，建议拆分内容到 references/"
elif [ "$LINE_COUNT" -gt 400 ]; then
    echo "  ℹ️ 接近 500 行上限（$LINE_COUNT/500）"
else
    echo "  ✅ 行数合理"
fi

echo ""
echo "=== 验证完成 ==="

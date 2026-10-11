#!/usr/bin/env bash
# 扫描 skills/ 目录下的技能文件夹，把每个技能记录到 README.md 的技能目录表中。
# 每次运行都会根据 skills/ 的实际内容重新生成目录区块，因此不会产生重复记录。
# 用法: bash scripts/update_skill_index.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="$ROOT/skills"
INDEX_FILE="$ROOT/README.md"
START_MARK="<!-- SKILLS-INDEX:START -->"
END_MARK="<!-- SKILLS-INDEX:END -->"

if [[ ! -d "$SKILLS_DIR" ]]; then
  echo "错误: skills 目录不存在: $SKILLS_DIR" >&2
  exit 1
fi

# 从 SKILL.md 的 frontmatter 提取 name / description（缺失则用目录名 / 空描述）
rows=""
for dir in "$SKILLS_DIR"/*/; do
  [[ -d "$dir" ]] || continue
  folder="$(basename "$dir")"
  skill_file="$dir/SKILL.md"
  name="$folder"
  desc=""
  if [[ -f "$skill_file" ]]; then
    fm_name="$(awk '/^---[[:space:]]*$/{c++; next} c==1 && /^name:/{sub(/^name:[[:space:]]*/, ""); print; exit}' "$skill_file")"
    fm_desc="$(awk '/^---[[:space:]]*$/{c++; next} c==1 && /^description:/{sub(/^description:[[:space:]]*/, ""); print; exit}' "$skill_file")"
    [[ -n "$fm_name" ]] && name="$fm_name"
    [[ -n "$fm_desc" ]] && desc="$fm_desc"
  fi
  # 转义表格特殊字符，避免破坏 markdown 表格
  name="${name//|/\\|}"
  desc="${desc//|/\\|}"
  rows+="| [$name](skills/$folder) | $desc |"$'\n'
done

table="| 技能 | 说明 |"$'\n'"| --- | --- |"$'\n'"$rows"
if [[ -z "$rows" ]]; then
  table="| 技能 | 说明 |"$'\n'"| --- | --- |"$'\n'"| （暂无技能） | 将技能文件夹放入 skills/ 后重新运行脚本 |"$'\n'
fi

if [[ -f "$INDEX_FILE" ]] && grep -qF "$START_MARK" "$INDEX_FILE" && grep -qF "$END_MARK" "$INDEX_FILE"; then
  # 替换已有标记之间的内容
  tmp="$(mktemp)"
  MARK_START="$START_MARK" MARK_END="$END_MARK" INDEX_TABLE="$table" awk '
    $0 == ENVIRON["MARK_START"] { print; printf "%s", ENVIRON["INDEX_TABLE"]; skip = 1; next }
    $0 == ENVIRON["MARK_END"] { skip = 0 }
    skip { next }
    { print }
  ' "$INDEX_FILE" > "$tmp"
  mv "$tmp" "$INDEX_FILE"
else
  # 没有标记则追加目录区块
  {
    printf '\n%s\n%s%s\n' "$START_MARK" "$table" "$END_MARK"
  } >> "$INDEX_FILE"
fi

count="$(printf '%s\n' "$rows" | grep -c '^|' || true)"
echo "已更新 ${INDEX_FILE}，共记录 ${count} 个技能。"

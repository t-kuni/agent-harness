#!/usr/bin/env bash
# 自然ハーネス（harness/meta/, harness/domains/）の各ファイルへの導線が
# 特殊ハーネス（CLAUDE.md, .claude/**）に存在するか検査する。
set -euo pipefail

errors=0

while IFS= read -r file; do
  [[ "$file" == *"_template"* ]] && continue
  relpath="${file#./}"

  if ! grep -rqF "$relpath" CLAUDE.md .claude/ 2>/dev/null; then
    echo "⚠ 導線なし: $relpath"
    errors=$((errors + 1))
  fi
done < <(find harness/meta harness/domains -type f \( -name "*.md" -o -name "*.yml" \) 2>/dev/null | sort)

if [ $errors -gt 0 ]; then
  echo ""
  echo "$errors 件の自然ハーネスファイルに特殊ハーネスからの導線がありません。"
fi

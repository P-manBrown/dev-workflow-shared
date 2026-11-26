#!/usr/bin/env bash
# PreToolUse（Edit|Write|NotebookEdit）: 同期で配ったファイルへの書き込みを止める
set -euo pipefail

input=$(cat)
file_path=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<<"$input")
[ -n "$file_path" ] || exit 0

case $file_path in
  /*) ;;
  *)
    cwd=$(jq -r '.cwd // empty' <<<"$input")
    [ -n "$cwd" ] || exit 0
    file_path="$cwd/$file_path"
    ;;
esac

dir=$(dirname "$file_path")
while [ ! -d "$dir" ]; do
  dir=$(dirname "$dir")
done
root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || exit 0
manifest="$root/.claude/shared-files.json"
[ -f "$manifest" ] || exit 0

physical=$(cd "$dir" && pwd -P)${file_path#"$dir"}
rel=${physical#"$root"/}
[ "$rel" != "$physical" ] || exit 0

while IFS= read -r entry; do
  if [ "$rel" = "$entry" ] || [[ $rel == "$entry"/* ]]; then
    reason="${rel}は同期で配った共通ファイルで、正本はdev-workflow-sharedの\`files/all/${rel}\`。このリポジトリでは直さず、正本を直して同期のPRで受け取る"
    jq -n --arg reason "$reason" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: $reason
      }
    }'
    exit 0
  fi
done < <(jq -r '.copy[]?' "$manifest" 2>/dev/null)

exit 0

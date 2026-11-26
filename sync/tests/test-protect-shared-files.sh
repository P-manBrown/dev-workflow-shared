#!/usr/bin/env bash
# files/all/.claude/hooks/protect-shared-files.sh を stdin から直接実行する
source "$(dirname "$0")/helpers.sh"

HOOK="$REPO_ROOT/files/all/.claude/hooks/protect-shared-files.sh"

new_repo "$WORK/repo"
write_file "$WORK/repo/.claude/shared-files.json" '{"copy": [".claude/rules/shared/gitkeep.md", ".claude/skills/doc-gardening"], "delete": []}'

run_hook() {
  hook_status=0
  hook_out=$(printf '%s' "$1" | bash "$HOOK") || hook_status=$?
}

run_hook "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$WORK/repo/.claude/rules/shared/gitkeep.md\"}}"
assert_eq "copied file: exit 0" 0 "$hook_status"
assert_eq "copied file: deny" deny "$(jq -r .hookSpecificOutput.permissionDecision <<<"$hook_out")"
assert_contains "copied file: source is shown" "$(jq -r .hookSpecificOutput.permissionDecisionReason <<<"$hook_out")" "files/all/.claude/rules/shared/gitkeep.md"

run_hook "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$WORK/repo/.claude/skills/doc-gardening/new/NEW.md\"}}"
assert_eq "new file under a copied directory: deny" deny "$(jq -r .hookSpecificOutput.permissionDecision <<<"$hook_out")"

run_hook "{\"tool_name\":\"NotebookEdit\",\"tool_input\":{\"notebook_path\":\"$WORK/repo/.claude/skills/doc-gardening/n.ipynb\"}}"
assert_eq "notebook under a copied directory: deny" deny "$(jq -r .hookSpecificOutput.permissionDecision <<<"$hook_out")"

run_hook "{\"tool_name\":\"Edit\",\"cwd\":\"$WORK/repo\",\"tool_input\":{\"file_path\":\".claude/rules/shared/gitkeep.md\"}}"
assert_eq "relative path: deny" deny "$(jq -r .hookSpecificOutput.permissionDecision <<<"$hook_out")"

run_hook "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$WORK/repo/.claude/rules/target-a-only.md\"}}"
assert_eq "own file: exit 0" 0 "$hook_status"
assert_eq "own file: no output" "" "$hook_out"

run_hook "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$WORK/repo/.claude/skills/doc-gardening-extra/SKILL.md\"}}"
assert_eq "sibling with the same prefix: no output" "" "$hook_out"

new_repo "$WORK/nomanifest"
mkdir -p "$WORK/nomanifest/.claude/rules/shared"
run_hook "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$WORK/nomanifest/.claude/rules/shared/gitkeep.md\"}}"
assert_eq "no manifest: exit 0" 0 "$hook_status"
assert_eq "no manifest: no output" "" "$hook_out"

mkdir -p "$WORK/outside"
run_hook "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$WORK/outside/file.md\"}}"
assert_eq "outside a repository: no output" "" "$hook_out"

finish

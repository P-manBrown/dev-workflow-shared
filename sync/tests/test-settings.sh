#!/usr/bin/env bash
# settings.json への hook の登録の差し込み
source "$(dirname "$0")/helpers.sh"

protect='bash "${CLAUDE_PROJECT_DIR}/.claude/hooks/protect-shared-files.sh"'

make_source "$WORK/src"
make_target "$WORK/dst"
run_sync "$WORK/src" "$WORK/dst" target-a
settings="$WORK/dst/.claude/settings.json"

assert_eq "sync succeeds" 0 "$sync_status"
assert_eq "other keys are kept" "./.claude/plans" "$(jq -r .plansDirectory "$settings")"
assert_eq "own registrations are kept" 1 "$(jq '[.hooks.SessionStart[].hooks[] | select(.command | contains("own-session-start.sh"))] | length' "$settings")"
assert_eq "own hook in a mixed group is kept" 1 "$(jq '[.hooks.PostToolUse[].hooks[] | select(.command | contains("rubocop-on-edit.sh"))] | length' "$settings")"
assert_eq "common registration is not duplicated" 1 "$(jq --arg c "$protect" '[.hooks.PreToolUse[].hooks[] | select(.command == $c)] | length' "$settings")"
assert_eq "registration of a deleted hook is removed" 0 "$(jq '[.hooks[][].hooks[] | select(.command | contains("old-hook.sh"))] | length' "$settings")"
assert_eq "emptied matcher group is removed" 0 "$(jq '[.hooks.PostToolUse[] | select(.matcher == "Bash")] | length' "$settings")"
assert_contains "inserted registrations are reported" "$sync_out" "hook: PreToolUse Edit|Write|NotebookEdit $protect"

new_repo "$WORK/nosettings"
write_file "$WORK/nosettings/README.md" 'no settings'
commit_all "$WORK/nosettings"
run_sync "$WORK/src" "$WORK/nosettings" target-c
assert_eq "settings.json is created" "$(git -C "$WORK/src" show HEAD:sync/settings-hooks.json | jq -c .)" "$(jq -c .hooks "$WORK/nosettings/.claude/settings.json")"
assert_eq "created settings.json has only hooks" '["hooks"]' "$(jq -c keys "$WORK/nosettings/.claude/settings.json")"

finish

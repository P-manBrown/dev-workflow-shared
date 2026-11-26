#!/usr/bin/env bash
# delete: repos の指定・replaced_by の保留・copy との重なり
source "$(dirname "$0")/helpers.sh"

make_source "$WORK/src"
make_target "$WORK/target-a"
run_sync "$WORK/src" "$WORK/target-a" target-a
assert_eq "sync succeeds" 0 "$sync_status"
assert_file "path for another repo is kept" "$WORK/target-a/.claude/target-b-only.md"
assert_file "path whose replacement is not copied is kept" "$WORK/target-a/.claude/rules/held.md"
assert_no_file "path whose replacement is copied is deleted" "$WORK/target-a/.claude/rules/replaced.md"
assert_no_file "path without conditions is deleted" "$WORK/target-a/.claude/hooks/old-hook.sh"
assert_file "path also in copy is not deleted" "$WORK/target-a/.claude/hooks/protect-shared-files.sh"
assert_contains "deleted paths are reported" "$sync_out" "deleted: .claude/rules/replaced.md"

make_target "$WORK/target-b"
run_sync "$WORK/src" "$WORK/target-b" target-b
assert_no_file "path for this repo is deleted" "$WORK/target-b/.claude/target-b-only.md"

new_repo "$WORK/empty"
write_file "$WORK/empty/README.md" 'empty'
commit_all "$WORK/empty"
run_sync "$WORK/src" "$WORK/empty" target-b
assert_eq "missing delete paths are ignored" 0 "$sync_status"

finish

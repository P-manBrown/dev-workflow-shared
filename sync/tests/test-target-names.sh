#!/usr/bin/env bash
# 配る先の名前が決めた場所の外に出たら check-target-names.sh が落ちること
source "$(dirname "$0")/helpers.sh"

CHECK="$REPO_ROOT/sync/check-target-names.sh"

run_check() {
  check_status=0
  bash "$CHECK" "$1" >/dev/null 2>"$WORK/check-stderr" || check_status=$?
  check_err=$(cat "$WORK/check-stderr")
}

run_check "$REPO_ROOT"
assert_eq "this repository names no target outside the allowed places" 0 "$check_status"
[ -z "$check_err" ] || printf '%s\n' "$check_err"

new_repo "$WORK/fixture"
write_file "$WORK/fixture/sync/targets.txt" 'target-a
target-b

target-c'
write_file "$WORK/fixture/README.md" 'no names here'
write_file "$WORK/fixture/.claude/specs/design.md" 'target-a is named in a spec'
write_file "$WORK/fixture/.claude/plans/active/plan.md" 'target-b is named in a plan'
commit_all "$WORK/fixture"
run_check "$WORK/fixture"
assert_eq "names in the list, specs and plans are allowed" 0 "$check_status"

write_file "$WORK/fixture/docs/guide.md" 'sync to target-a'
commit_all "$WORK/fixture"
run_check "$WORK/fixture"
assert_eq "a name in another file fails" 1 "$check_status"
assert_contains "the failing file is reported" "$check_err" "docs/guide.md"

git -C "$WORK/fixture" rm -q docs/guide.md
write_file "$WORK/fixture/scripts/run.sh" 'echo target-c'
commit_all "$WORK/fixture"
run_check "$WORK/fixture"
assert_eq "a target added to the list is checked without changing the check" 1 "$check_status"
assert_contains "the file naming the added target is reported" "$check_err" "scripts/run.sh"

finish

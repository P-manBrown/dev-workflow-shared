#!/usr/bin/env bash
# 正本の検査: 合わなければ配る先に何も書かずに止まる
source "$(dirname "$0")/helpers.sh"

# expect_stop <名前> <正本> <stderr に含まれる文字列>
expect_stop() {
  rm -rf "$WORK/dst"
  make_target "$WORK/dst"
  local before
  before=$(git -C "$WORK/dst" rev-parse HEAD)
  run_sync "$2" "$WORK/dst" target-a
  assert_eq "$1: sync fails" 1 "$sync_status"
  assert_contains "$1: reason is reported" "$sync_err" "$3"
  assert_eq "$1: target is untouched" "" "$(git -C "$WORK/dst" status --porcelain)"
  assert_eq "$1: target HEAD is unchanged" "$before" "$(git -C "$WORK/dst" rev-parse HEAD)"
}

make_source "$WORK/ok"
make_target "$WORK/dst"
run_sync "$WORK/ok" "$WORK/dst" target-a
assert_eq "matching paths pass" 0 "$sync_status"

make_source "$WORK/missing-file"
git -C "$WORK/missing-file" rm -q -r files/all/.claude/skills/demo
git -C "$WORK/missing-file" commit -q -m "remove demo"
expect_stop "copy path missing in files/all" "$WORK/missing-file" "missing in files/all: .claude/skills/demo"

make_source "$WORK/paths-short"
write_rule "$WORK/paths-short" ".claude/shared-files.json" ".claude/rules/shared/shared-files.md" ".claude/hooks/protect-shared-files.sh" ".github/COMMIT_CONVENTION/**"
commit_all "$WORK/paths-short"
expect_stop "paths missing" "$WORK/paths-short" "paths missing in shared-files.md: .claude/skills/demo/**"

make_source "$WORK/paths-extra"
write_rule "$WORK/paths-extra" "${FIXTURE_PATHS[@]}" ".claude/rules/shared/extra.md"
commit_all "$WORK/paths-extra"
expect_stop "paths extra" "$WORK/paths-extra" "paths extra in shared-files.md: .claude/rules/shared/extra.md"

make_source "$WORK/paths-dir"
write_rule "$WORK/paths-dir" ".claude/shared-files.json" ".claude/rules/shared/shared-files.md" ".claude/hooks/protect-shared-files.sh" ".claude/skills/demo" ".github/COMMIT_CONVENTION/**"
commit_all "$WORK/paths-dir"
expect_stop "directory without /**" "$WORK/paths-dir" "paths missing in shared-files.md: .claude/skills/demo/**"

rm -rf "$WORK/dst"
make_target "$WORK/dst"
printf '{ not json' >"$WORK/dst/.claude/settings.json"
commit_all "$WORK/dst" "broken settings"
run_sync "$WORK/ok" "$WORK/dst" target-a
assert_eq "invalid settings.json: sync fails" 1 "$sync_status"
assert_contains "invalid settings.json: reason is reported" "$sync_err" "not valid JSON: .claude/settings.json"
assert_eq "invalid settings.json: target is untouched" "" "$(git -C "$WORK/dst" status --porcelain)"

finish

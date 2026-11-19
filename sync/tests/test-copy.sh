#!/usr/bin/env bash
# copy: ファイル・ディレクトリ・実行権限・gitlink と .gitmodules
source "$(dirname "$0")/helpers.sh"

make_source "$WORK/src"
make_target "$WORK/dst"
run_sync "$WORK/src" "$WORK/dst" tascon-backend

assert_eq "sync succeeds" 0 "$sync_status"
assert_eq "file is copied" "$(cat "$WORK/src/files/all/.claude/shared-files.json")" "$(cat "$WORK/dst/.claude/shared-files.json")"
assert_file "directory files are copied" "$WORK/dst/.claude/skills/demo/scripts/run.sh"
assert_no_file "directory is replaced as a whole" "$WORK/dst/.claude/skills/demo/stale.md"
assert_eq "executable mode is kept" 100755 "$(git -C "$WORK/dst" ls-files -s -- .claude/hooks/protect-shared-files.sh | cut -d' ' -f1)"
assert_eq "non-executable mode is kept" 100644 "$(git -C "$WORK/dst" ls-files -s -- .claude/skills/demo/SKILL.md | cut -d' ' -f1)"
assert_eq "gitlink is staged" "160000 $COMMIT_CONVENTION_SHA" "$(git -C "$WORK/dst" ls-files -s -- .github/COMMIT_CONVENTION | cut -d' ' -f1,2)"
assert_eq ".gitmodules keeps one entry" ".github/COMMIT_CONVENTION" "$(git config -f "$WORK/dst/.gitmodules" --get-regexp '^submodule\..*\.path$' | cut -d' ' -f2)"
assert_eq ".gitmodules entry name has no files/all" ".github/COMMIT_CONVENTION" "$(git config -f "$WORK/dst/.gitmodules" --get submodule..github/COMMIT_CONVENTION.path)"
assert_eq ".gitmodules url comes from the source" "$COMMIT_CONVENTION_URL" "$(git config -f "$WORK/dst/.gitmodules" --get submodule..github/COMMIT_CONVENTION.url)"
assert_contains "copied paths are reported" "$sync_out" "copied: .claude/skills/demo"
assert_contains "changes are reported" "$sync_out" "result: changed"

make_target_without_gitmodules() {
  new_repo "$1"
  write_file "$1/README.md" 'target'
  commit_all "$1"
}
make_target_without_gitmodules "$WORK/plain"
run_sync "$WORK/src" "$WORK/plain" devcontainer-features
assert_eq "sync into a repo without .gitmodules succeeds" 0 "$sync_status"
assert_eq ".gitmodules is created" "$COMMIT_CONVENTION_URL" "$(git config -f "$WORK/plain/.gitmodules" --get submodule..github/COMMIT_CONVENTION.url)"
assert_eq "no files/all entry in .gitmodules" "" "$(grep 'files/all' "$WORK/plain/.gitmodules" || true)"

finish

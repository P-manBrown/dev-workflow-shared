#!/usr/bin/env bash
# copy: ファイル・ディレクトリ・実行権限・submodule からファイルへの置き換え
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
assert_eq "gitlink is replaced by files" "100644 100644" "$(git -C "$WORK/dst" ls-files -s -- .github/COMMIT_CONVENTION | cut -d' ' -f1 | paste -sd' ')"
assert_file "convention file is copied" "$WORK/dst/.github/COMMIT_CONVENTION/COMMIT_CONVENTION.md"
assert_file "gitmessage is copied" "$WORK/dst/.github/COMMIT_CONVENTION/.gitmessage"
assert_no_file ".gitmodules is removed when it had no other entry" "$WORK/dst/.gitmodules"
assert_eq ".gitmodules removal is staged" "" "$(git -C "$WORK/dst" ls-files -- .gitmodules)"
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
assert_no_file "no .gitmodules is created" "$WORK/plain/.gitmodules"

make_target "$WORK/other"
git -C "$WORK/other" config -f .gitmodules submodule.vendor/other.path vendor/other
git -C "$WORK/other" config -f .gitmodules submodule.vendor/other.url https://example.com/other.git
git -C "$WORK/other" add .gitmodules
git -C "$WORK/other" update-index --add --cacheinfo "160000,2222222222222222222222222222222222222222,vendor/other"
git -C "$WORK/other" commit -q -m other
run_sync "$WORK/src" "$WORK/other" tascon-frontend
assert_eq "sync into a repo with another submodule succeeds" 0 "$sync_status"
assert_eq "only the other submodule stays in .gitmodules" "vendor/other" "$(git config -f "$WORK/other/.gitmodules" --get-regexp '^submodule\..*\.path$' | cut -d' ' -f2)"
assert_eq "other gitlink is kept" 160000 "$(git -C "$WORK/other" ls-files -s -- vendor/other | cut -d' ' -f1)"
assert_eq "convention gitlink is gone" 100644 "$(git -C "$WORK/other" ls-files -s -- .github/COMMIT_CONVENTION/COMMIT_CONVENTION.md | cut -d' ' -f1)"

finish

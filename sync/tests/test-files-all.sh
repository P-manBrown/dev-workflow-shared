#!/usr/bin/env bash
# このリポジトリの files/all/ と manifest の一致（HEAD を見る。コミットしてから実行する）
source "$(dirname "$0")/helpers.sh"

manifest=$(git -C "$REPO_ROOT" show HEAD:files/all/.claude/shared-files.json)
mapfile -t copy < <(jq -r '.copy[]' <<<"$manifest")

uncovered=()
while IFS= read -r path; do
  rel=${path#files/all/}
  covered=no
  for entry in "${copy[@]}"; do
    if [ "$rel" = "$entry" ] || [[ $rel == "$entry"/* ]]; then
      covered=yes
      break
    fi
  done
  [ "$covered" = yes ] || uncovered+=("$rel")
done < <(git -C "$REPO_ROOT" ls-tree -r --name-only HEAD -- files/all)
assert_eq "every file in files/all is in copy" "" "${uncovered[*]}"

unknown_hooks=()
while IFS= read -r hook; do
  found=no
  for entry in "${copy[@]}"; do
    [ "$hook" = "$entry" ] && found=yes
  done
  [ "$found" = yes ] || unknown_hooks+=("$hook")
done < <(git -C "$REPO_ROOT" show HEAD:sync/settings-hooks.json \
  | jq -r '.[][].hooks[].command' | grep -o '\.claude/hooks/[^"/]*\.sh' | sort -u)
assert_eq "every hook in settings-hooks.json is in copy" "" "${unknown_hooks[*]}"

new_repo "$WORK/empty"
write_file "$WORK/empty/README.md" 'empty'
commit_all "$WORK/empty"
run_sync "$REPO_ROOT" "$WORK/empty" devcontainer-features
assert_eq "this repository passes the precheck" 0 "$sync_status"
[ -z "$sync_err" ] || printf '%s\n' "$sync_err"

finish

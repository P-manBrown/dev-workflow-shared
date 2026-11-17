#!/usr/bin/env bash
# 共通ファイルを 1 リポジトリへ同期する。
# 使い方: sync.sh <正本のリポジトリ> <配る先のリポジトリ> <配る先のリポジトリ名>
# 正本は HEAD の tree から読む。配る先は作業ツリーと index を書き換え、commit はしない。
# 標準出力: copied:/deleted:/hook: の行と、最後に result: changed か result: no-changes
set -euo pipefail

manifest_path=files/all/.claude/shared-files.json
rule_path=files/all/.claude/rules/shared/shared-files.md
hooks_path=sync/settings-hooks.json

die() {
  printf 'sync: %s\n' "$1" >&2
  exit 1
}

[ "$#" -eq 3 ] || die "usage: sync.sh <source-repo> <target-repo> <repo-name>"
src=$1
dst=$2
repo=$3

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

src_show() {
  git -C "$src" cat-file blob "HEAD:$1" 2>/dev/null
}

src_entry() {
  git -C "$src" ls-tree HEAD -- "files/all/$1"
}

manifest=$(src_show "$manifest_path") || die "manifest not found: $manifest_path"
jq -e '(.copy | type == "array") and ((.delete // []) | type == "array")' <<<"$manifest" >/dev/null 2>&1 \
  || die "manifest is not valid: $manifest_path"
common_hooks=$(src_show "$hooks_path") || die "not found: $hooks_path"
jq -e 'type == "object"' <<<"$common_hooks" >/dev/null 2>&1 || die "not valid JSON object: $hooks_path"

mapfile -t copy < <(jq -r '.copy[]' <<<"$manifest")

is_covered() {
  local path=$1 entry
  for entry in "${copy[@]}"; do
    if [ "$path" = "$entry" ] || [[ $path == "$entry"/* ]]; then
      return 0
    fi
  done
  return 1
}

# 1. 正本の検査（配る先に何も書かない）
errors=()
expected_paths=()
for path in "${copy[@]}"; do
  entry=$(src_entry "$path")
  if [ -z "$entry" ]; then
    errors+=("missing in files/all: $path")
    continue
  fi
  read -r _ type _ _ <<<"$entry"
  case $type in
    blob) expected_paths+=("$path") ;;
    *) expected_paths+=("$path/**") ;;
  esac
done

rule=$(src_show "$rule_path") || die "rule not found: $rule_path"
mapfile -t actual_paths < <(sed -n '2,/^---$/p' <<<"$rule" | sed -n 's/^  - "\(.*\)"$/\1/p')
printf '%s\n' "${expected_paths[@]}" | sed '/^$/d' | sort -u >"$tmp_dir/expected"
printf '%s\n' "${actual_paths[@]}" | sed '/^$/d' | sort -u >"$tmp_dir/actual"
while IFS= read -r path; do
  errors+=("paths missing in shared-files.md: $path")
done < <(comm -23 "$tmp_dir/expected" "$tmp_dir/actual")
while IFS= read -r path; do
  errors+=("paths extra in shared-files.md: $path")
done < <(comm -13 "$tmp_dir/expected" "$tmp_dir/actual")

settings_file="$dst/.claude/settings.json"
if [ -f "$settings_file" ] && ! jq empty "$settings_file" >/dev/null 2>&1; then
  errors+=("not valid JSON: .claude/settings.json")
fi

if [ "${#errors[@]}" -gt 0 ]; then
  printf 'sync: %s\n' "${errors[@]}" >&2
  exit 1
fi

# 2. delete
deletes=()
while IFS=$'\t' read -r path replaced_by; do
  is_covered "$path" && continue
  if [ -n "$replaced_by" ] && ! is_covered "$replaced_by"; then
    continue
  fi
  deletes+=("$path")
done < <(jq -r --arg repo "$repo" '
  .delete // [] | .[]
  | select(.repos == null or (.repos | index($repo)) != null)
  | [.path, (.replaced_by // "")] | @tsv' <<<"$manifest")

for path in "${deletes[@]}"; do
  if [ -n "$(git -C "$dst" ls-files -- "$path")" ]; then
    git -C "$dst" rm -r -q -- "$path"
    printf 'deleted: %s\n' "$path"
  fi
done

# 3. copy
write_blob() {
  local mode=$1 sha=$2 path=$3
  mkdir -p "$dst/$(dirname "$path")"
  git -C "$src" cat-file blob "$sha" >"$dst/$path"
  git -C "$dst" add -- "$path"
  if [ "$mode" = 100755 ]; then
    git -C "$dst" update-index --chmod=+x -- "$path"
    chmod 755 "$dst/$path"
  else
    git -C "$dst" update-index --chmod=-x -- "$path"
    chmod 644 "$dst/$path"
  fi
}

set_gitmodule() {
  local path=$1 key value name="" url
  src_show .gitmodules >"$tmp_dir/gitmodules" || die "not found: .gitmodules"
  while read -r key value; do
    if [ "$value" = "files/all/$path" ]; then
      name=${key%.path}
    fi
  done < <(git config -f "$tmp_dir/gitmodules" --get-regexp '^submodule\..*\.path$')
  [ -n "$name" ] || die "no .gitmodules entry for files/all/$path"
  url=$(git config -f "$tmp_dir/gitmodules" --get "$name.url") || die "no url for files/all/$path"
  git config -f "$dst/.gitmodules" "submodule.$path.path" "$path"
  git config -f "$dst/.gitmodules" "submodule.$path.url" "$url"
  git -C "$dst" add -- .gitmodules
}

for path in "${copy[@]}"; do
  read -r mode type sha _ <<<"$(src_entry "$path")"
  git -C "$dst" rm -r -q --cached --ignore-unmatch -- "$path" >/dev/null
  rm -rf "${dst:?}/$path"
  case $type in
    commit)
      mkdir -p "$dst/$path"
      git -C "$dst" update-index --add --cacheinfo "160000,$sha,$path"
      set_gitmodule "$path"
      ;;
    blob)
      write_blob "$mode" "$sha" "$path"
      ;;
    tree)
      while IFS=$'\t' read -r meta child; do
        read -r child_mode child_type child_sha <<<"$meta"
        [ "$child_type" = blob ] || die "unsupported entry in $path: $child"
        write_blob "$child_mode" "$child_sha" "${child#files/all/}"
      done < <(git -C "$src" ls-tree -r HEAD -- "files/all/$path")
      ;;
  esac
  printf 'copied: %s\n' "$path"
done

# 4. settings.json の hooks
remove=()
for path in "${copy[@]}"; do
  if [[ $path =~ ^\.claude/hooks/[^/]+\.sh$ ]]; then
    remove+=("$path")
  fi
done
remove+=("${deletes[@]}")
remove_json=$(jq -n '$ARGS.positional' --args "${remove[@]}")

current='{}'
if [ -f "$settings_file" ]; then
  current=$(cat "$settings_file")
fi
mkdir -p "$dst/.claude"
jq --indent 2 --argjson remove "$remove_json" --argjson common "$common_hooks" '
  .hooks = (
    (.hooks // {})
    | with_entries(.value |= (
        map(.hooks |= map(select(
          (.command // "") as $c | ($remove | any(. as $r | $c | contains($r))) | not
        )))
        | map(select(.hooks | length > 0))
      ))
    | with_entries(select(.value | length > 0))
    | reduce ($common | to_entries[]) as $e (.; .[$e.key] = ((.[$e.key] // []) + $e.value))
  )' <<<"$current" >"$settings_file"
git -C "$dst" add -- .claude/settings.json
jq -r 'to_entries[] | .key as $event | .value[] | (.matcher // "*") as $matcher
  | .hooks[] | "hook: \($event) \($matcher) \(.command)"' <<<"$common_hooks"

# 5. 差分の判定
if git -C "$dst" diff --cached --quiet; then
  echo "result: no-changes"
else
  echo "result: changed"
fi

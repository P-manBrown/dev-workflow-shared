#!/usr/bin/env bash
# 配る先のリポジトリ名が、決めた場所の外に出ていないことを確かめる（HEAD を見る）。
# 名前は sync/targets.txt から読む。使い方: check-target-names.sh <リポジトリの根>
set -euo pipefail

root=${1:?usage: check-target-names.sh <repo root>}

mapfile -t names < <(git -C "$root" show HEAD:sync/targets.txt | grep -v '^[[:space:]]*$' || true)
if [ "${#names[@]}" -eq 0 ]; then
  echo 'sync/targets.txt has no target' >&2
  exit 1
fi

patterns=()
for name in "${names[@]}"; do
  patterns+=(-e "$name")
done

# 名前を書いてよい場所: 一覧のファイル、spec・plan（あとで docs/design/ へ移る物を含む）、
# devcontainer の feature の参照、manifest の delete の repos（最初の同期が済んだら消す）
found=$(git -C "$root" grep -I -l -F "${patterns[@]}" HEAD -- . \
  ':(exclude)sync/targets.txt' \
  ':(exclude).claude/specs' \
  ':(exclude).claude/plans' \
  ':(exclude)docs/design' \
  ':(exclude).devcontainer.json' \
  ':(exclude).devcontainer-lock.json' \
  ':(exclude)files/all/.claude/shared-files.json' \
  | sed 's/^HEAD://') || true

if [ -n "$found" ]; then
  echo 'target repository names found outside the allowed places:' >&2
  printf '%s\n' "$found" >&2
  exit 1
fi

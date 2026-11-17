#!/usr/bin/env bash
# 差分なしの判定
source "$(dirname "$0")/helpers.sh"

make_source "$WORK/src"
make_target "$WORK/dst"
run_sync "$WORK/src" "$WORK/dst" tascon-backend
assert_contains "first sync has changes" "$sync_out" "result: changed"
commit_all "$WORK/dst" synced

run_sync "$WORK/src" "$WORK/dst" tascon-backend
assert_eq "second sync succeeds" 0 "$sync_status"
assert_contains "second sync has no changes" "$sync_out" "result: no-changes"
assert_eq "working tree stays clean" "" "$(git -C "$WORK/dst" status --porcelain)"

finish

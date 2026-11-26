#!/usr/bin/env bash
# sync/tests のテストをすべて実行する
set -uo pipefail

tests_dir=$(cd "$(dirname "$0")" && pwd)
status=0
for test in "$tests_dir"/test-*.sh; do
  printf '# %s\n' "$(basename "$test")"
  bash "$test" || status=1
done
exit "$status"

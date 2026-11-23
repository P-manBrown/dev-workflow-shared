# sync/tests の共通の関数。各テストから source する
set -euo pipefail

TESTS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$TESTS_DIR/../.." && pwd)
SYNC="$REPO_ROOT/sync/sync.sh"
COMMIT_CONVENTION_URL=https://github.com/P-manBrown/commit-convention.git

failures=0
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

pass() { printf 'ok - %s\n' "$1"; }

fail() {
  printf 'not ok - %s\n' "$1"
  failures=$((failures + 1))
}

assert_eq() {
  if [ "$2" = "$3" ]; then
    pass "$1"
  else
    fail "$1"
    printf '  expected: %s\n  actual:   %s\n' "$2" "$3"
  fi
}

assert_file() {
  if [ -e "$2" ]; then pass "$1"; else fail "$1"; fi
}

assert_no_file() {
  if [ ! -e "$2" ]; then pass "$1"; else fail "$1"; fi
}

assert_contains() {
  if grep -qF -- "$3" <<<"$2"; then
    pass "$1"
  else
    fail "$1"
    printf '  missing: %s\n' "$3"
  fi
}

finish() {
  if [ "$failures" -gt 0 ]; then
    printf '%d failure(s)\n' "$failures"
    exit 1
  fi
}

new_repo() {
  git init -q -b main "$1"
  git -C "$1" config user.name test
  git -C "$1" config user.email test@example.com
}

commit_all() {
  git -C "$1" add -A
  git -C "$1" commit -q -m "${2:-fixture}"
}

write_file() {
  mkdir -p "$(dirname "$1")"
  printf '%s\n' "$2" >"$1"
}

# write_rule <正本> <paths...>: shared-files.md を paths の一覧で書く
write_rule() {
  local file="$1/files/all/.claude/rules/shared/shared-files.md" path
  shift
  mkdir -p "$(dirname "$file")"
  {
    echo '---'
    echo 'paths:'
    for path in "$@"; do
      printf '  - "%s"\n' "$path"
    done
    echo '---'
    echo
    echo '# 共通ファイル'
  } >"$file"
}

FIXTURE_PATHS=(
  ".claude/shared-files.json"
  ".claude/rules/shared/shared-files.md"
  ".claude/hooks/protect-shared-files.sh"
  ".claude/skills/demo/**"
  ".github/COMMIT_CONVENTION/**"
)

# make_source <dir>: テスト用の正本を作って commit する
make_source() {
  local src=$1
  new_repo "$src"
  write_file "$src/files/all/.claude/shared-files.json" '{
  "copy": [
    ".claude/shared-files.json",
    ".claude/rules/shared/shared-files.md",
    ".claude/hooks/protect-shared-files.sh",
    ".claude/skills/demo",
    ".github/COMMIT_CONVENTION"
  ],
  "delete": [
    {"path": ".claude/frontend-only.md", "repos": ["tascon-frontend"]},
    {"path": ".claude/rules/held.md", "replaced_by": ".claude/rules/shared/held.md"},
    {"path": ".claude/rules/replaced.md", "replaced_by": ".claude/skills/demo/SKILL.md"},
    {"path": ".claude/hooks/protect-shared-files.sh"},
    {"path": ".claude/hooks/old-hook.sh"}
  ]
}'
  write_rule "$src" "${FIXTURE_PATHS[@]}"
  write_file "$src/files/all/.claude/hooks/protect-shared-files.sh" '#!/usr/bin/env bash'
  chmod 755 "$src/files/all/.claude/hooks/protect-shared-files.sh"
  write_file "$src/files/all/.claude/skills/demo/SKILL.md" 'demo skill'
  write_file "$src/files/all/.claude/skills/demo/scripts/run.sh" '#!/usr/bin/env bash'
  chmod 755 "$src/files/all/.claude/skills/demo/scripts/run.sh"
  write_file "$src/sync/settings-hooks.json" '{
  "PreToolUse": [
    {
      "matcher": "Edit|Write|NotebookEdit",
      "hooks": [
        {"type": "command", "command": "bash \"${CLAUDE_PROJECT_DIR}/.claude/hooks/protect-shared-files.sh\""}
      ]
    }
  ]
}'
  write_file "$src/files/all/.github/COMMIT_CONVENTION/COMMIT_CONVENTION.md" 'convention'
  write_file "$src/files/all/.github/COMMIT_CONVENTION/.gitmessage" 'message'
  git -C "$src" add -A
  git -C "$src" commit -q -m fixture
}

# make_target <dir>: テスト用の配る先を作って commit する
make_target() {
  local dst=$1
  new_repo "$dst"
  write_file "$dst/README.md" 'target'
  write_file "$dst/.claude/frontend-only.md" 'frontend only'
  write_file "$dst/.claude/rules/held.md" 'held'
  write_file "$dst/.claude/rules/replaced.md" 'replaced'
  write_file "$dst/.claude/hooks/old-hook.sh" '#!/usr/bin/env bash'
  write_file "$dst/.claude/skills/demo/stale.md" 'stale'
  write_file "$dst/.claude/settings.json" '{
  "plansDirectory": "./.claude/plans",
  "hooks": {
    "SessionStart": [
      {"matcher": "startup", "hooks": [{"type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/own-session-start.sh --from-hook"}]}
    ],
    "PreToolUse": [
      {"matcher": "Edit|Write|NotebookEdit", "hooks": [{"type": "command", "command": "bash \"${CLAUDE_PROJECT_DIR}/.claude/hooks/protect-shared-files.sh\""}]}
    ],
    "PostToolUse": [
      {"matcher": "Edit|Write", "hooks": [
        {"type": "command", "command": "bash \"${CLAUDE_PROJECT_DIR}/.claude/hooks/old-hook.sh\""},
        {"type": "command", "command": "bash \"${CLAUDE_PROJECT_DIR}/.claude/hooks/rubocop-on-edit.sh\""}
      ]},
      {"matcher": "Bash", "hooks": [{"type": "command", "command": "bash \"${CLAUDE_PROJECT_DIR}/.claude/hooks/old-hook.sh\""}]}
    ]
  }
}'
  git -C "$dst" config -f .gitmodules submodule..github/COMMIT_CONVENTION.path .github/COMMIT_CONVENTION
  git -C "$dst" config -f .gitmodules submodule..github/COMMIT_CONVENTION.url "$COMMIT_CONVENTION_URL"
  git -C "$dst" add -A
  git -C "$dst" update-index --add --cacheinfo "160000,1111111111111111111111111111111111111111,.github/COMMIT_CONVENTION"
  mkdir -p "$dst/.github/COMMIT_CONVENTION"
  git -C "$dst" commit -q -m fixture
}

# run_sync <正本> <配る先> <名前>: 標準出力を $sync_out、終了コードを $sync_status に入れる
run_sync() {
  sync_status=0
  sync_out=$(bash "$SYNC" "$1" "$2" "$3" 2>"$WORK/sync-stderr") || sync_status=$?
  sync_err=$(cat "$WORK/sync-stderr")
}

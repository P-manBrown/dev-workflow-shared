---
paths:
  - "files/all/**"
  - "sync/**"
---

## 共通ファイルの正本

- `files/all/`の下のファイルが正本。同期のワークフローが、配る先のすべてのリポジトリの同じ道（`files/all/`からの相対の道）へ同期のPRで写す
- 共通ファイルは配る先のリポジトリでは直さない。このリポジトリの`files/all/`を直す
- `files/all/`の下のルール・Skillは、このリポジトリでは読み込まれない

## 共通ファイルを足す・道を変える・やめるとき

同じPRで次を直す。

- manifest `files/all/.claude/shared-files.json`: 配るものは`copy`、配る先から消すものは`delete`
- `files/all/.claude/rules/shared/shared-files.md`の`paths`: `copy`のエントリごとに、ファイルは同じ道、ディレクトリは`<道>/**`を、`copy`と同じ順に、二重引用符付きで1行に1つ書く
- 配る先の`.claude/settings.json`へ差し込むhookの登録が変わるときは`sync/settings-hooks.json`
- 直した後に`bash sync/tests/run.sh`を実行し、全件通ることを確かめる（テストはコミット済みの`HEAD`を読む）

## 配る先を増やす・減らすとき

- 配る先の一覧は`sync/targets.txt`だけ。1行に1リポジトリ名を書き、増やすときは1行足し、減らすときは1行消す
- 同期のGitHub Appを、増やすリポジトリに入れ、減らすリポジトリから外す
- 配る先のリポジトリ名を`sync/targets.txt`以外に書かない（`.claude/specs/`・`.claude/plans/`を除く）。書いたファイルは`bash sync/tests/run.sh`が落とす
- 文章には「3リポジトリ」のような数や名前を書かず、「配る先」と書く

## `files/all/`のルール・Skill・agentを変えるときのテスト

- 配る先のうち、その変更が効くリポジトリのworktreeに、変更後のファイルを同期後と同じ道で置く。元の道に同じ名前のルールがあれば、そのworktreeの中で消す
- そのリポジトリのclaude-md-maintenanceルールの手順で比較テストを行ってから、PRを出す
- PRのTestingに、テストした配る先のリポジトリとコミット、プロンプト、変更前と変更後の結果を書く
- 比較テストを行えないときは、その変更をPRに入れない

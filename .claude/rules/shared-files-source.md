---
paths:
  - "files/all/**"
  - "sync/**"
---

## 共通ファイルの正本

- `files/all/`の下のファイルが正本。同期のワークフローが、3リポジトリの同じ道（`files/all/`からの相対の道）へ同期のPRで写す
- 共通ファイルは配る先のリポジトリでは直さない。このリポジトリの`files/all/`を直す
- `files/all/`の下のルール・Skillは、このリポジトリでは読み込まれない

## 共通ファイルを足す・道を変える・やめるとき

同じPRで次を直す。

- manifest `files/all/.claude/shared-files.json`: 配るものは`copy`、配る先から消すものは`delete`
- `files/all/.claude/rules/shared/shared-files.md`の`paths`: `copy`のエントリごとに、ファイルは同じ道、ディレクトリとsubmoduleは`<道>/**`を、`copy`と同じ順に、二重引用符付きで1行に1つ書く
- 配る先の`.claude/settings.json`へ差し込むhookの登録が変わるときは`sync/settings-hooks.json`

## `files/all/`のルール・Skill・agentを変えるときのテスト

- 配る先のリポジトリ（tascon-backend）のworktreeに、変更後のファイルを同期後と同じ道で置く。元の道に同じ名前のルールがあれば、そのworktreeの中で消す
- そのリポジトリのclaude-md-maintenanceルールの手順で比較テストを行ってから、PRを出す
- PRのTestingに、テストした配る先のリポジトリとコミット、プロンプト、変更前と変更後の結果を書く
- 比較テストを行えないときは、その変更をPRに入れない

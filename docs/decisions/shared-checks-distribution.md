# 共通の確かめ（CIのワークフローと台本）の配り方

- **Status:** Accepted
- **Verification Status:** Unverified
- **Date:** 2026-11-19
- **Related Files:** `files/all/.claude/shared-files.json`, `files/all/.claude/rules/shared/shared-files.md`, `sync/sync.sh`, `.github/workflows/sync.yml`, `.github/workflows/ci.yml`, `AGENTS.md`

## Context

- tascon-backendに、CodeQL・Semgrep・Dependency ReviewとPR本文の確かめ（Related Documentsの確かめ。台本`check-pr-body.sh`・`lib/markdown.jq`・その試し）が入る。これらを後でtascon-frontend・devcontainer-featuresにも配る
- このリポジトリが定める配る経路は、`files/all/`の下の正本をmanifest（`files/all/.claude/shared-files.json`）の`copy`に従って3リポジトリの同じ道へ写すものだけ。`copy`の中身は3リポジトリで同じ
- 3リポジトリは使う言語が違う。backendのCodeQLはRuby、SemgrepはRailsの規則を使う
- PR本文の確かめの台本は、CIだけでなく手元でも使う。どの配り方でも、台本は各リポジトリの中に要る
- backendの中身はまだbackendのmainに入っていない。この決定の時点では中身を写さず、配り方と揃える時の手順だけを決める

## Decision

- ファイルごとに配る（下の方式A）。確かめのワークフロー・台本・その試しを`files/all/`の同じ道に置き、manifestの`copy`と`shared-files.md`の`paths`に足す
- 配るワークフローは、3リポジトリでそのまま動く中身にする。言語・規則の集まりを決め打ちしない（例: CodeQLは対象の言語を書かずにリポジトリの言語から決めるか、見つけた言語でmatrixを組む。Semgrepは3リポジトリの言語の規則の集まりを並べる。対象の言語のファイルが無い規則は何も出さない）
- backendのmainに入った版を正本にして`files/all/`に写し、揃える。backendの未マージの中身は写さない
- 配る台本の試しは`<台本の道>/tests/run.sh`に置く。このリポジトリのCIの`test`ジョブが、ワークフローを直さずにそれを走らせる
- このリポジトリ自身のCIは、`test`・`shellcheck`・`markdownlint`をまとめ役のジョブ`checks`に通し、必須のチェックには`checks`だけを登録する
- 見直しの条件: 言語・規則の集まりを決め打ちせずに書けないとbackendの版で分かったら、その確かめについて方式B（呼び出せるワークフロー）か、リポジトリで絞る`copy`（今のmanifestは`delete`だけを`repos`で絞れる）を見直す

## Considered Options

### A. ファイルごとに配る（今の`files/all/`とmanifest）

- 長所:
  - 今の決まり（AGENTS.mdの「共通ファイルの正本」「共通ファイルを足す・道を変える・やめるとき」、`shared-files.md`、`protect-shared-files.sh`）がそのまま当てはまる。新しい配る経路を作らない
  - 手元で要る台本も同じ経路で配れる
  - ジョブの表示名がbackendと同じまま。必須のチェックに登録する名前が変わらない
  - 正本を直せば、同期のPRで3リポジトリが揃う。呼び出し側の固定のIDを3か所で上げる作業が無い
  - 台本の試しは、このリポジトリのCIで走る
- 短所:
  - `copy`は全リポジトリで同じ中身。リポジトリで中身が違う物（CodeQLの言語、Semgrepの規則の集まり）は、どのリポジトリでもそのまま動く形に書く必要がある
  - `.github/workflows/`を写すには、同期のGitHub AppにWorkflowsの書き込みの権限が要る

### B. 呼び出せるワークフロー（`workflow_call`）

このリポジトリに`on: workflow_call`のワークフローを置き、3リポジトリの呼び出し側が`uses: P-manBrown/dev-workflow-shared/.github/workflows/<名前>.yml@<コミットのID>`で呼ぶ。

- 長所:
  - 入力（言語・規則の集まり）で、リポジトリごとの違いを渡せる
  - 呼び出し側は人が書くので、同期のAppにWorkflowsの権限が要らない
- 短所:
  - 今の決まりに無い2つ目の配る経路になる。呼び出し側は自分の固定のIDを自分の中に書けないので配る物にできず、3リポジトリで人が書き、IDを上げ続ける
  - 台本と試しは手元で要るので、ファイルでも配ることになる。呼ばれた側が同じ版の台本を取り出す方法も要る
  - ジョブの表示名が`<呼び出しのジョブ> / <呼ばれたジョブ>`に変わり、backendの名前と揃わない

### C. 混ぜる（全リポジトリで同じ物はA、言語で違う物はB）

- 長所: それぞれの確かめに合う方を使える
- 短所: 2つの経路の決まり・試し・固定の仕方を両方持つ。Aの短所は「どのリポジトリでもそのまま動く形」で解けるので、Bを足す理由が残らない

## Consequences

- 同期のGitHub AppにWorkflowsの書き込みの権限が要る。この決定の時点では確かめていない。初めて`.github/workflows/`を配る前に確かめる
- tascon-frontend・devcontainer-featuresには、`plan-completion`の`SKILL.md`無しで台本（`check-pr-body.sh`・`lib/markdown.jq`）だけが入る。
- `lib/markdown.jq`はbackendの`judge-completion.sh`と共用する。直すときは、backendの`judge-completion.sh`の試しも通ることを確かめる
- 揃える作業（backendのmainに入った後）は、AGENTS.mdの「共通ファイルを足す・道を変える・やめるとき」の手順そのものになる: backendの版のファイルを`files/all/`に置き、manifestと`shared-files.md`を直し、`bash sync/tests/run.sh`とCIを通す
- このリポジトリの必須のチェックは`checks`だけ。確かめのジョブを足すときは`checks`の`needs`に入れれば足り、必須のチェックを登録し直さなくてよい。登録し忘れても関門から漏れない

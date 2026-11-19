# Design candidate: 自動の直しの決まりを共通の hooks-authoring.md に書く

- Bead: dws-ofr7（step `requirements.brainstorm-design`, iteration 2, attempt 2）。前回: dws-tks7（iteration 1）→ 承認の lane dws-6ltr が verdict iterate（`approval-summary.md` の R1-R3）
- Workflow root: dws-80m0（superpowers-build）／依頼の部分: dws-pdhl（HQ gc-ltc2 の 2 つのうちの 2）
- Approval mode: autonomous（`gc.var.brainstorming_approval_mode=autonomous`）
- Approval status: **approved**（承認の lane dws-y1n9、iteration 2、autonomous、2026-11-19。`approval-summary.md`）

## Superpowers checklist 1-5 の記録

| # | 項目 | 状態 | 記録 |
|---|------|------|------|
| 1 | project context の確認 | done（iteration 2 で足した） | 下の「確かめた文脈」。R1・R3 の事実と、tascon-frontend の今の文を足した |
| 2 | Visual Companion | 不要と判断（iteration 1 のまま） | 成果物はルールファイルの数行の文。見て分かる問いがない。提案しない |
| 3 | 確かめの問い（1 つずつ） | 人への問いなし（iteration 1 のまま） | autonomous。依頼と文脈で決まらない点は「仮定」（A1-A5）に記録。人の答えが必要な問いはない |
| 4 | 2-3 の方式と推し | done | 下の「方式の比較」（paths の範囲: A/B/C、共通の写しの古さの扱い: D1/D2） |
| 5 | 推す設計を節ごとに提示 | done | 下の「設計」 |

## 求められていること

依頼（dws-pdhl／gc-ltc2 の原文）:

> 自動の直しの決まり（意味を変えないことが保証された直しだけを適用し、安全と危険を区別しない道具は確かめだけにする）を、共通の .claude/rules/hooks-authoring.md に書く（今の文と重ねず、食い違わないように）。リポジトリのルールファイルやスキルに従って作業してください。今夜は PR を出すところまで。

同じ HQ 依頼の別の部分（dws-1vtc）で、このリポジトリの CI に shellcheck・markdownlint が入る。

## 確かめた文脈

### このリポジトリ

- dev-workflow-shared は、tascon-backend・tascon-frontend・devcontainer-features へ配る共通ファイルの正本。正本は `files/all/` の下（AGENTS.md）
- 「共通の .claude/rules/hooks-authoring.md」の正本は `files/all/.claude/rules/shared/hooks-authoring.md`。配る先では `.claude/rules/shared/hooks-authoring.md` になる
- このファイルは main にまだない。git-spice のスタックの PR #6 `feat/shared-authoring-rules` で入り、#7 `feat/shared-hooks`・#8 `feat/shared-github-templates`（いちばん上）でも中身は同じ（blob 2b35909）。tascon-backend@960441e の写し
- 共通の写しの中身（19 行）:
  - frontmatter `paths`: `.claude/settings.json`, `.claude/hooks/**`
  - 「# フック設計時の注意」: Stop/SubagentStop の 3 点（`additionalContext` で止まらない、`decision: block` で 1 回止める、`stop_hook_active`）
  - 「## 作成・変更時の確認」: 3 点（stdin に JSON を与えて直接実行、発火すべきでない入力で何も出さない、実セッションで発火）
  - 自動の直しについての文はない
- 隣のルール `scripts-authoring.md` の `paths` は `.claude/settings.json`, `.claude/hooks/**`, `.claude/skills/**/scripts/**`, `.lefthook/**`, `lefthook.yml`。Git の hook も hook の台本として扱った前例
- AGENTS.md:
  - `files/all/` のルールを変えたら、tascon-backend の worktree に同期後と同じ道で置き、**そのリポジトリの** claude-md-maintenance の手順で比較テストをしてから PR を出す。テストできないときはその変更を PR に入れない
  - 「過去に試して失敗した方式・採用しなかった方式は、その理由を解消しない限り再提案しない」「提案時は、確認した記録と、過去の方式との関係を示す」
- このリポジトリ自身には `.claude/rules` がない（スタックの枝にも `files/all/` の下だけ）。書き方の原則は、比較テストの手順と同じく配る先（tascon-backend main）の claude-md-maintenance に従う

### 配る先の今の文（R1 で確かめ直した）

- **tascon-backend main** の `.claude/rules/hooks-authoring.md`（blob 6ae998d、c73626c、PR #825、2026-11-18 11:09Z マージ）は、共通の写しより新しい。「# フック設計時の注意」に次の 2 点が増えている:
  - P1: `リンターの違反を`PostToolUse`のexit 2で差し戻さない。違反の検出はpre-commitに任せる`
  - P2: `言語サーバー（LSP）の連携でエージェントに渡る診断で得られる検査（型チェック等）はフックにしない`
- tascon-backend main の claude-md-maintenance にも、共通の写しにない 1 行がある（同じ PR #825）: 「SKILL.md/rules執筆時の原則」の下の `一般原則だけでは比較テストで行動が変わらなかった場合は、例外として該当する対象の代表例を添える`
- **tascon-frontend main** の `.claude/rules/hooks-authoring.md` には、依頼の決まりの元になった項目がすでにある:
  - `フォーマッタ・リンターを`Edit`/`Write`の`PostToolUse`で実行する場合、意味を変えないことが保証された自動修正のみを適用し、exit 0で終了する。安全な修正と危険な修正を区別しないツール（markdownlint等）の自動修正は実行しない`
  - ほかに P1 と同じ文、LSP の文（P2 の元）、Stop の 2 点目の違う版、シェルスクリプト優先の文がある。「作成・変更時の確認」はない
- devcontainer-features main には hooks-authoring.md も lefthook もない

### 過去に試した方式（R3）

- tascon-backend PR #825 の Testing: 「意味を変えない自動の直しだけを exit 0 で適用する」項目（frontend の上の項目を、道具の名前を除いて書き直したもの）は、比較テスト（headless `claude -p`、`rule-tester`）で変更前後の行動が同じだったため取り下げた。P1・P2・代表例の項目は行動が変わったので残した
- 取り下げた項目を試したプロンプトは PR に書かれていない（確かめられない）
- そのときの場は tascon-backend。backend には `PostToolUse` の `rubocop-on-edit.sh`（`rubocop --autocorrect`、安全な直しだけ）がすでにあり、手本になる今の hook がある
- そのときの `paths` は `.claude/settings.json`, `.claude/hooks/**` だけで、Git の hook を触る場面では読み込まれない

### 配る先での自動の直しの今の姿（tascon-backend main で確認）

- Claude Code の hook: `PostToolUse` の `rubocop-on-edit.sh` が安全な直しだけを走らせる
- Git の hook（`lefthook.yml` の pre-commit）: `rubocop --autocorrect` と `htmlbeautifier`（安全・危険の区別がない）を `stage_fixed: true` で走らせ、直した結果をそのままコミットへ入れる
- backend の決定記録 `docs/decisions/reminder-hooks-removal.md`: 「新しいhookを追加する場合は、文言の注入ではなくブロックまたは自動修正で完結するものに限る」→ 自動の直しを使う hook が今後も増える

## 制約

- 書き換えるのは `files/all/.claude/rules/shared/hooks-authoring.md` だけ（manifest `shared-files.json` と `shared-files.md` の `paths` は道が変わらないので直さない）
- 共通の写しの今の 6 項目の文は変えない。新しい文は、共通の写しの 6 項目に加えて、配る先の今の文（backend main の P1・P2、frontend main の各項目）とも重ならず、食い違わない
- 文は日本語・一般原則・理由なし。道具の名前・オプションは書かない。ただし比較テストで一般原則だけでは差が出なかった項目に限り、backend main の claude-md-maintenance の例外に従って代表例を添えてよい（設計 5）
- main にこのファイルがないため、新しいブランチは git-spice で今のスタックのいちばん上（今は `feat/shared-github-templates`）に積む。main から切らない（`git-spice-workflow` Skill に従う。`gh stack` は使わない）
- 比較テスト（変更前と変更後）を tascon-backend の worktree で行い、PR の Testing に書く。差が出なかった項目は PR に入れない（設計 5 の終わり方）
- 同時に進む部分（dws-1vtc: 自身の CI・共通の確かめの配り方）には手を出さない

## やらないこと（Non-goals）

- 配る先（tascon-backend・tascon-frontend など）の今の hook・lefthook の設定・ルールファイルを直すこと（例: `htmlbeautifier` の `stage_fixed` をやめる、frontend の今の項目を消す）。別の依頼で扱う
- 共通の写しを配る先の main に揃えること（hooks-authoring の P1・P2、claude-md-maintenance の代表例の 1 行）。mayor に知らせて別に扱う（方式 D2）
- CI・共通の確かめの配り方（dws-1vtc の範囲）
- 道具ごとの安全・危険のオプションの一覧を書くこと
- 新しい hook・台本・テストの台本を作ること

## 方式の比較

### その 1: 決まりが効く範囲（`paths`）

#### 方式 A（推し）: 「自動の直し」の節を足し、`paths` に Git の hook（`.lefthook/**`, `lefthook.yml`）を足す

- 良い点: 配る先で自動の直しを登録する 2 つの場所（Claude Code の hook と lefthook）のどちらを触っても決まりが読み込まれる。scripts-authoring.md の `paths` と同じ範囲で、前例に沿う
- 良い点: PR #825 で取り下げたときには決まりが読み込まれなかった場面（Git の hook）で効かせるので、前回の「差が出ない」理由の 1 つを解く（設計 5）
- 悪い点: lefthook を触るときに Stop hook の注意も読み込まれる。関係のない文が少し増えるが、食い違いは生まない
- 比較テストの場面が 2 つ（Claude Code の hook、lefthook）になる

#### 方式 B: 節だけ足し、`paths` は変えない

- 良い点: いちばん小さい変更
- 悪い点: lefthook の pre-commit の自動の直し（`stage_fixed` で直した結果がそのままコミットに入る、いちばん影響の大きい場所）を書くときに読み込まれない。PR #825 で差が出なかった場面とほぼ同じ場面にしか効かず、同じ理由で取り下げになりやすい

#### 方式 C: 同じ決まりを scripts-authoring.md にも書く

- 悪い点: 同じ文が 2 か所になり「重ねず」に反する。依頼が名指ししたファイル以外を直す。採らない

### その 2: 共通の写しが配る先の main より古いことの扱い（R1）

#### 方式 D1: この変更のブランチで、まず共通の hooks-authoring.md を backend main に揃え（P1・P2 を足す）、その後に節を足す

- 良い点: 同じファイルの中で、新しい文が P1・P2 と食い違わないことを目で見られる
- 悪い点: 依頼にない変更（P1・P2）が `files/all/` のルールに入り、AGENTS.md によりその 2 点にも比較テストが要る（場が backend の今の文と同じになるので、変更前後の取り方も崩れる）
- 悪い点: 古さは hooks-authoring だけでなく claude-md-maintenance にもあり、片方だけ揃えると揃え方が半端になる。揃えるのは写しを作ったスタック（PR #6）の側の仕事で、別の作業と重なるおそれがある

#### 方式 D2（推し）: 共通の写しの今の文はそのままにし、新しい文は配る先の今の文（P1・P2、frontend の項目）とも食い違わず重ならない書き方にする。古さは mayor に知らせる

- 良い点: 変更が依頼の範囲（1 つの節と `paths`）に収まる。比較テストの変更前後が AGENTS.md どおりに取れる
- 良い点: 後で写しが揃っても、新しい文は P1・P2 と重ならず食い違わない（設計 4 で確かめる）
- 悪い点: 写しが揃うまでは、共通の hooks-authoring.md に P1・P2 がない（今もない。この変更で悪くはならない）

**推し: 方式 A と D2。** 依頼の目的を自動の直しが登録される両方の場所で効かせ、前回の取り下げの理由に手を打ちつつ、変更を依頼の範囲の 1 ファイルに収める。

## 設計（方式 A + D2）

### 1. 置き場所と構成

- `files/all/.claude/rules/shared/hooks-authoring.md` の最後（「## 作成・変更時の確認」の後）に、新しい節「## 自動の直し」を足す
- 今の節の文は 1 行も変えない

### 2. frontmatter

`paths` を次にする（今の 2 行の後に 2 行を足す。scripts-authoring.md と同じ書き方・二重引用符）:

```yaml
paths:
  - ".claude/settings.json"
  - ".claude/hooks/**"
  - ".lefthook/**"
  - "lefthook.yml"
```

### 3. 足す文（案。言い回しは実装と比較テストで詰めてよいが、中身の 2 点と、Claude Code の hook と Git の hook の分け方は変えない）

```markdown
## 自動の直し

hook（Claude CodeのhookとGitのhook）で道具にファイルを直させるときは、次に従う。

- 道具が意味を変えないと保証している直しだけを適用する。安全な直しと危険な直しを分ける道具では、安全な直しだけを有効にする
- 安全な直しと危険な直しを区別しない道具には直させない。Claude Codeのhookでは実行しない。Gitのhookでは、直さずに違反を見つけて止める確かめだけに使う
```

- 依頼の「確かめだけにする」を、hook の種類で分けて書く（R2）:
  - Claude Code の hook: 区別しない道具は走らせない。直させないうえ、違反を `PostToolUse` の exit 2 で差し戻すのは backend・frontend の今の文（P1）が禁じているので、ここで確かめをさせる書き方はしない
  - Git の hook: 直すモードで走らせず、`stage_fixed` のような直した結果のコミットへの取り込みもしない。違反があればコミットを止める
- 「保証している」かは道具の文書で確かめる、という読みを含む（具体の道具名・オプションは書かない。設計 5 の代表例の例外を除く）
- 理由・経緯（backend の rubocop・htmlbeautifier の件、PR #825 の取り下げなど）はルールに書かず、PR の本文に書く

### 4. 今の文との関係（重なり・食い違いの確かめ）

共通の写しの 6 項目:

- Stop/SubagentStop の 3 点: 注入・止め方の話。自動の直しと重ならない
- 「作成・変更時の確認」の 3 点: 発火と出力の確かめ。新しい節は「どの直しを使ってよいか」で重ならない。新しい節に確かめの手順は足さない
- Git の hook の「止める」は Git の hook の失敗で止めること。Claude Code の hook の `decision: block` とは別で、食い違わない

配る先の main の文（写しが揃ったときに同じファイルに並ぶ文）:

- P1（リンターの違反を `PostToolUse` の exit 2 で差し戻さない。違反の検出は pre-commit に任せる）: 新しい文は Claude Code の hook での確かめについて何も言わない（区別しない道具は走らせない、とだけ言う）ので食い違わない。Git の hook での確かめは P1 の「pre-commit に任せる」の中身（直さずに止める）を言うだけで、P1 の「どこで検出するか」とは重ならない
- P2（LSP の診断で得られる検査はフックにしない）: 検査の種類の話。自動の直しと重ならない
- frontend の今の項目（`PostToolUse` で意味を変えない自動修正だけを適用し exit 0、区別しない道具の自動修正は実行しない）: 新しい文はこれを Claude Code の hook と Git の hook の両方へ広げたもので、`PostToolUse` について言うことは同じ。食い違わない。frontend の文は配る先の文で、この変更では触らない（同期のときの扱いは PR #6 側）

### 5. 比較テスト（AGENTS.md・tascon-backend main の claude-md-maintenance の手順）

- 場: tascon-backend の worktree（main）。変更前・変更後のファイルを `.claude/rules/shared/hooks-authoring.md` に置き、元の道の `.claude/rules/hooks-authoring.md` はその worktree の中で消す
- 項目ごとに、変更前になく変更後にある行動を確かめる:
  - T1（区別しない道具は直させない／Git の hook では確かめだけ）: lefthook の場面。プロンプトの案「lefthook の pre-commit で、ERB の整形を自動で直してコミットに入れるようにして」。変更後は直すモード・`stage_fixed` を使わず確かめだけにし、変更前はそうしない
  - T2（意味を変えない直しだけ／安全な直しだけ）: Claude Code の hook と lefthook の場面。プロンプトの案「Edit の後に、危険なものも含めて全部自動で直す hook にして」「pre-commit の rubocop を全部自動で直すようにして」。変更後は安全な直しだけにし、変更前はそうしない
  - プロンプトはルール名を問わない本番の場面にする。最終のプロンプトは実装の lane が変更前の挙動を見て決める
- 前回（PR #825）と差が出ると見込む理由（AGENTS.md「過去の方式との関係」）:
  1. `paths` に Git の hook を足したので、前回は読み込まれなかった場面（lefthook）で効く。backend の lefthook には区別しない道具を直すモードで走らせる今の例（`htmlbeautifier` の `stage_fixed`）があり、変更前はそれに倣うと見込む
  2. 区別しない道具の扱いを、Claude Code の hook と Git の hook ごとの行動として書いた（前回の項目は「exit 0 で適用する」が中心で、backend の今の `PostToolUse` の hook がすでにその手本になっていた）
  3. それでも差が出ない項目は、backend main の claude-md-maintenance の「一般原則だけでは比較テストで行動が変わらなかった場合は、例外として該当する対象の代表例を添える」に従い、その項目に代表例を 1-2 個添えて（frontend の今の項目が `markdownlint等` を添えているのと同じ形）もう一度比べる。この 1 行は共通の写しの claude-md-maintenance にはまだない（方式 D2 で mayor に知らせる古さの 1 つ）
- 終わり方:
  - 代表例を添えても差が出ない項目は、その場で取り消し、PR に入れない（claude-md-maintenance の手順）
  - T1・T2 のどちらも差が出ないときは、`paths` の変更も含めてこの変更を PR に入れない。ブランチは作らず、結果を bead に書いて mayor に知らせる（依頼の「PR を出すところまで」に届かないことを知らせる）
- 結果（配る先のリポジトリとコミット、プロンプト、変更前と変更後、代表例を添えたかどうか）を PR の Testing に書く。PR の本文に、PR #825 で取り下げた項目との関係（上の 1-3）を書く

### 6. ブランチと PR

- `git-spice-workflow` Skill で、スタックのいちばん上に新しいブランチを積む（名前は実装の lane が決める。例 `feat/hooks-authoring-autofix`）
- コミットは `.github/COMMIT_CONVENTION` に従う。PR は `.github/pull_request_template.md` に従う
- 依頼の到達点は PR を出すところまで。この build は `push=true`・`open_pr=false` なので、build はブランチを push するまでを行い、PR を出すのは build の後の段（mayor の扱い）に従う

### 7. mayor へ知らせること（方式 D2）

実装の lane が、作業の後に `gc mail send mayor` で 1 回知らせる（人へのメールではない）:

- 共通の写し（スタック PR #6〜#8、tascon-backend@960441e）が tascon-backend main（c73626c、PR #825）より古い: hooks-authoring の P1・P2、claude-md-maintenance の代表例の 1 行がない。写しを揃える作業が要る
- この変更の新しい文は P1・P2 と重ならず食い違わないように書いた（設計 4）

## 受け入れの条件

1. `files/all/.claude/rules/shared/hooks-authoring.md` に「## 自動の直し」の節があり、次がそろう: 意味を変えないと保証された直しだけを適用する（安全と危険を分ける道具は安全な直しだけ）／区別しない道具には直させない（Claude Code の hook では実行しない、Git の hook では直さずに止める確かめだけ）。ただし比較テストで差が出ずに取り消した項目は除く（その場合は条件 6 の記録がある）
2. 今の 6 項目の文（Stop/SubagentStop の 3 点、作成・変更時の確認の 3 点）が 1 文字も変わっていない
3. frontmatter の `paths` が `.claude/settings.json`, `.claude/hooks/**`, `.lefthook/**`, `lefthook.yml` の 4 つ（方式 A）
4. 新しい文に理由・経緯がない。日本語。道具の名前・オプションは、比較テストで一般原則だけでは差が出ず代表例を添えた項目にだけある
5. 新しい文が、backend main の P1・P2、frontend main の今の項目と食い違わない（設計 4 のとおり。PR の本文に書く）
6. tascon-backend の worktree で、項目ごとに比較テストを行い、変更前になく変更後にある行動を確かめた。結果と、PR #825 で取り下げた項目との関係が PR の本文（Testing）にある。差が出なかった項目は入っていない
7. ほかのファイル（manifest、shared-files.md、ほかのルール）を変えていない
8. ブランチが git-spice のスタックの上に積まれ、push されている（PR を出すのは build の後の段）。どの項目も差が出なかったときは、ブランチを作らず bead に記録して mayor に知らせている
9. 共通の写しの古さ（設計 7）を mayor に知らせている

## 仮定（autonomous のため人に問わず、ここに記録）

- A1: 「自動の直し」は、hook の中でファイルを書き換えて直す処理（Claude Code の hook と、lefthook などの Git の hook の両方）を指す。CI での直しは範囲外（CI は dws-1vtc の部分で、確かめだけ）
- A2: `paths` に Git の hook を足すのは、依頼の「hooks-authoring.md に書く」の中に入る（ファイルは名指しのとおり 1 つ）。もし人が「Claude Code の hook だけ」を意図していたなら、方式 B に戻すだけで済む
- A3: 依頼の「確かめだけにする」は、道具を直すモードで走らせないこと。Claude Code の hook では、今の文（P1）があるので走らせないことにし、Git の hook では違反で止めるだけにする
- A4（R1）: 依頼の「今の文」は共通の写しの文。ただし写しは配る先の main より古いので、配る先の今の文（backend の P1・P2、frontend の項目）とも食い違わず重ならないようにする。写しを揃えるのはこの依頼の範囲外とし、mayor に知らせる（方式 D2）。承認の lane は方式 D1 を選び直してよい
- A5（R3）: 比較テストの手順と書き方の例外（代表例）は、AGENTS.md が名指しする配る先（tascon-backend main）の claude-md-maintenance に従う

## 自律の承認の根拠

- 依頼が書くファイル・決まりの中身・制約（重ねない・食い違わない・ルールとスキルに従う）を決めている
- 共通の写しにも配る先の main にも、新しい文と重なる・食い違う文がないことを確かめた（設計 4）
- 過去に取り下げた方式との関係と、差が出ないときの終わり方を決めた（設計 5）
- 書き方はリポジトリ（と配る先）の執筆の原則で決まる
- 依頼で決まらない点（`paths` の範囲、「自動の直し」の範囲、写しの古さの扱い）は、配る先の今の使い方と前例から決め、仮定 A1-A5 に残した。人の答えなしに進められる

## 未解決の問い

- なし（人の答えが必要なものはない）。仮定 A2（方式 B）と A4（方式 D1）は、承認の lane が選び直してよい

## 履歴

- iteration 1 / attempt 1（2026-11-19、dws-tks7）: 初版
- iteration 2 / attempt 2（2026-11-19、dws-ofr7）: 承認の lane（dws-6ltr）の R1-R3 を直した
  - R1: backend main の P1・P2 と代表例の 1 行、frontend main の今の項目を文脈に足した。写しの古さの扱いを方式 D1/D2 で比べ、D2 を選んで仮定 A4 に残した。重なり・食い違いの確かめを配る先の文に対してもやり直した（設計 4）
  - R2: 足す文の 3 点目を、Claude Code の hook（走らせない）と Git の hook（直さずに止める確かめだけ）に分けて書き直し、P1 と食い違わないようにした。1 点目と 2 点目は 1 項目にまとめた
  - R3: PR #825 で取り下げた項目の記録、今回差が出ると見込む理由、代表例の例外の使い方、差が出ないときの終わり方を設計 5・受け入れの条件 6・8 に足した
  - 変えなかったところ: 依頼・Non-goals の骨組み・方式 A/B/C・仮定 A1-A3 の中身・ブランチをスタックの上に積む制約・`push=true`/`open_pr=false` の扱い・Visual Companion を使わない判断・人への問いがない判断
- 承認（2026-11-19、dws-y1n9）: verdict done。申し送り N1 は `approval-summary.md`

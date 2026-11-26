# 自動の直しの決まりを共通のhooks-authoring.mdに書く

Spec: .claude/specs/hooks-authoring-autofix.md

## Context/Purpose

意味を変えないことが保証された自動の直しだけを適用し、安全と危険を区別しない道具には直させない、という決まりを、配る先の3リポジトリへ同期で配る共通のhooks-authoringルール（`files/all/.claude/rules/shared/hooks-authoring.md`）に書く。

- 変えるファイルはこのルールだけ。manifest（`files/all/.claude/shared-files.json`）と`shared-files.md`のpathsは、ファイルの道が変わらないので直さない
- 作業は`docs/hooks-authoring-autofix`ブランチで、スタックの`feat/shared-github-templates`の上に積む。1コミットで入れる
- ルールの変更なので、AGENTS.mdの手順に従い、tascon-backendのclaude-md-maintenanceの手順で比較テストをしてから入れる。差が出なかった項目は入れない
- 設計は`.claude/specs/hooks-authoring-autofix.md`。決めたのは、方式A（「自動の直し」の節を足し、`paths`にGitのhook（`.lefthook/**`・`lefthook.yml`）を足す）と、方式D2（共通の写しが配る先のmainより古いことは直さず、新しい文を配る先の今の文と重ならず食い違わないように書く）

## Decision Log

- 節は「## 自動の直し」として、既存の節の後に足す。既存の6項目の文は1文字も変えない（設計1）
- `paths`に`.lefthook/**`と`lefthook.yml`を足す。自動の直しが登録されるClaude CodeのhookとGitのhookの両方で決まりを読み込ませるため（方式A）
- 節の文は、hookの種類で分けて書く。Claude Codeのhookでは、区別しない道具を走らせない。Gitのhookでは、直すモードで走らせず、直した結果をコミットへ取り込まず、違反を見つけて止める確かめだけに使う（設計3）
- 共通の写しが配る先（tascon-backend main）より古いことは、この変更では直さず、mayorに知らせる（方式D2）
- 比較テストは、tascon-backendの一時のcloneで、tascon-backend main（c73626c）の上に変更前・変更後のファイルを`.claude/rules/shared/hooks-authoring.md`として置き、4項目（T1・T2-a・T2-b・T3）で行った。4項目すべてで差が出たので、節と`paths`を全部入れた。代表例は添えていない

## Validation and Acceptance

- `files/all/.claude/rules/shared/hooks-authoring.md`に「## 自動の直し」の節があり、意味を変えないと保証された直しだけを適用すること、区別しない道具にはClaude Codeのhookでは実行せずGitのhookでは直さずに止める確かめだけにすることが書かれている
- 既存の6項目の文が1文字も変わっていない
- frontmatterの`paths`が`.claude/settings.json`、`.claude/hooks/**`、`.lefthook/**`、`lefthook.yml`の4つである
- 新しい文に理由・経緯がなく、道具の名前・オプションがない
- 新しい文が、tascon-backend mainとtascon-frontend mainの今の文と食い違わず、重ならない
- 変更前になく変更後にある行動を、項目ごとに比較テストで確かめ、結果がPRのTestingにある。差が出なかった項目は入っていない
- 共通ファイルの変更が、このルール1つだけである（manifestと`shared-files.md`は変えない）
- ブランチがスタックの`feat/shared-github-templates`の上に積まれ、pushされている
- 共通の写しが配る先のmainより古いことを、mayorに知らせた

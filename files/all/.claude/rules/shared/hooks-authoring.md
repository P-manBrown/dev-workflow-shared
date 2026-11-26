---
paths:
  - ".claude/settings.json"
  - ".claude/hooks/**"
  - ".lefthook/**"
  - "lefthook.yml"
---

# フック設計時の注意

- `Stop`/`SubagentStop`で`hookSpecificOutput.additionalContext`を返すと、そのターンは継続扱いになり停止しない。無条件に注入する設計は無限ループを招く
- `Stop`/`SubagentStop`で判定込みの確認をさせたい場合、判定をフックに持たせない。`type: "command"`で`decision: block`を返して1回だけ止め、確認の内容を`reason`で渡して、会話全体を持つメインエージェントに判断させる
- `type: "command"`で`Stop`/`SubagentStop`を扱う場合は、入力JSONの`stop_hook_active`を確認し、`true`なら何も出力せず終了する(無限ループ防止)
- リンターの違反を`PostToolUse`のexit 2で差し戻さない。違反の検出はpre-commitに任せる
- 言語サーバー（LSP）の連携でエージェントに渡る診断で得られる検査（型チェック等）はフックにしない

## 作成・変更時の確認

hookスクリプト、または`settings.json`のhookの登録を作成・変更したら、コミット前に次を確かめる。

- 発火すべき入力のJSONをstdinへ与えてスクリプトを直接実行し、出力と終了コードが想定どおりになる
- 発火すべきでない入力（matcherの対象外、`stop_hook_active`が`true`等）では何も出力しない
- `settings.json`へ登録した状態の実セッションで、想定した場面に発火する

## 自動の直し

hook（Claude CodeのhookとGitのhook）で道具にファイルを直させるときは、次に従う。

- 道具が意味を変えないと保証している直しだけを適用する。安全な直しと危険な直しを分ける道具では、安全な直しだけを有効にする
- 安全な直しと危険な直しを区別しない道具には直させない。Claude Codeのhookでは実行しない。Gitのhookでは、直すモードで走らせず、直した結果をコミットへ取り込まず、違反を見つけて止める確かめだけに使う

# manifestのdeleteにある配る先ごとのreposの指定を、最初の同期の後に消す

- **Status:** Open
- **Priority:** Low
- **Category:** Infrastructure
- **Area:** `files/all/.claude/shared-files.json`、`sync/check-target-names.sh`
- **Detected:** 2026-11-26
- **Description:** manifestの`delete`に、配る先のリポジトリ名を`repos`で指定した5件がある。配る先の名前を`sync/targets.txt`の1か所に置く決まりの例外として、`sync/check-target-names.sh`が`files/all/.claude/shared-files.json`を許している
- **Impact:** 配る先を増やす・減らすとき、`sync/targets.txt`のほかにmanifestの名前も直す必要が残る。例外を許したままだと、manifestに名前が増えても確かめが落ちない
- **Proposed Resolution:** 最初の同期が済んで、`repos`で絞った5件の削除が配る先に反映されたら、その5件を`delete`から消し、`sync/check-target-names.sh`の許す場所から`files/all/.claude/shared-files.json`を外す。`repos`で絞る仕組み（`sync/sync.sh`）は残す
- **Related:** `sync/targets.txt`、`.claude/rules/shared-files-source.md`

---
paths:
  - ".claude/shared-files.json"
  - ".claude/rules/shared/shared-files.md"
  - ".claude/hooks/protect-shared-files.sh"
---

# 同期で配る共通ファイル

- このルールの`paths`に当たるファイルは、dev-workflow-sharedの`files/all/`の下の同じ道にあるファイルが正本。同期のPRで、このリポジトリへ写される
- これらのファイルは、このリポジトリでは直さない。Bashでの書き込み（リダイレクト・`sed -i`・`cp`等）も同じ
- 直すときは、dev-workflow-sharedの`files/all/<同じ道>`を直し、同期のPRで受け取る

---
paths:
  - ".claude/shared-files.json"
  - ".claude/rules/shared/shared-files.md"
  - ".claude/hooks/protect-shared-files.sh"
  - ".claude/rules/shared/architecture-md-maintenance.md"
  - ".claude/rules/shared/claude-md-maintenance.md"
  - ".claude/rules/shared/decisions-maintenance.md"
  - ".claude/rules/shared/gitkeep.md"
  - ".claude/rules/shared/plans-maintenance.md"
  - ".claude/rules/shared/tech-debt-maintenance.md"
  - ".claude/skills/tech-debt-tracker/**"
  - ".claude/skills/doc-gardening/**"
  - ".claude/agents/rule-tester.md"
  - ".claude/hooks/rule-tester-guard.sh"
  - ".claude/rules/shared/hooks-authoring.md"
  - ".claude/rules/shared/scripts-authoring.md"
  - ".claude/hooks/check-docs-hook.sh"
  - ".claude/hooks/record-check.sh"
  - ".lefthook/pre-commit/check-docs.sh"
  - ".lefthook/pre-commit/check-plan-completion.sh"
  - ".claude/skills/project-setup/SKILL.md"
  - ".github/pull_request_template.md"
  - ".github/ISSUE_TEMPLATE/task.md"
  - ".github/COMMIT_CONVENTION/**"
---

# 同期で配る共通ファイル

- このルールの`paths`に当たるファイルは、dev-workflow-sharedの`files/all/`の下の同じ道にあるファイルが正本。同期のPRで、このリポジトリへ写される
- これらのファイルは、このリポジトリでは直さない。Bashでの書き込み（リダイレクト・`sed -i`・`cp`等）も同じ
- 直すときは、dev-workflow-sharedの`files/all/<同じ道>`を直し、同期のPRで受け取る

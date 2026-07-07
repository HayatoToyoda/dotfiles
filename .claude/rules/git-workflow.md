# Git Workflow — Claude Code Execution Details

Base GitHub Flow rules (branching, PR requirements, main protection) live in the
global `AGENTS.md`. This file adds the Claude Code-specific execution flow.

## 開発開始時（REQUIRED）

`superpowers:using-git-worktrees` スキルを使ってワークスペースを作成する。
- ワークツリーは `.worktrees/<branch-name>` に作成（プロジェクトローカル優先）
- `.worktrees/` が `.gitignore` に含まれているか確認・なければ追加してコミット
- `npm install`（または該当するセットアップコマンド）を実行
- ベースラインテストが通ることを確認してから実装開始

## 開発完了時（REQUIRED）

`superpowers:finishing-a-development-branch` スキルを使って統合方法を決定する。
- テストが全パスしていることを確認
- 標準パスは **Option 2: Push and create a Pull Request**
- `gh pr create` で作成し、PR URL をユーザーに共有してマージ承認を待つ
- ユーザーが明示的に承認した場合のみ `gh pr merge` を実行

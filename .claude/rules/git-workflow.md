# Git Workflow — GitHub Flow

## ブランチ戦略

- `main` は常にデプロイ可能。直接コミット・プッシュ禁止。
- 全作業はブランチ経由: `feature/xxx`、`fix/xxx`、`hotfix/xxx`
- hotfix のみ緊急時に main から直接分岐を許可（それでも PR 必須）

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
- PR URL をユーザーに共有し、マージ承認を待つ
- ユーザーが承認したら `gh pr merge` を実行

## PR ルール

- `gh pr create` で作成し URL をユーザーに共有する
- ユーザーの明示的な承認なしに `gh pr merge` を実行しない
- テスト失敗中は PR を作成しない

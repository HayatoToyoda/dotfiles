# dotfiles — Cross-Tool AI Harness

Claude Code / Codex / Cursor で**同じ instructions・skills を共有**するためのハーネス。
canonical な指示は 1 ファイル（`shared/AGENTS.md`）だけ。各ツールへはシンボリックリンクで配線する。

```
shared/AGENTS.md ─────────── canonical instructions（唯一の編集対象）
   ├── ~/.claude/CLAUDE.md が @AGENTS.md で import   → Claude Code
   ├── ~/.codex/AGENTS.md → symlink                  → Codex
   └── Cursor Settings > User Rules に貼り付け        → Cursor（グローバル AGENTS.md 非対応のため）

.claude/skills/ ──────────── canonical skills library
   ├── ~/.claude/skills → symlink                    → Claude Code / Cursor（~/.claude を自動読込）
   ├── ~/.agents/skills → symlink                    → Codex（symlink 追従を公式サポート）
   └── ~/.cursor/skills → symlink                    → Cursor fallback
```

## Install

```bash
bash install.sh
```

- **per-item symlink 方式**。`~/.claude` ディレクトリ丸ごとのリンクはしない
  （Claude Code は `~/.claude/.credentials.json` 等のランタイム状態を書き込むため、
  丸ごとリンクだと認証トークンが git リポジトリ内に置かれてしまう）。
- 旧・丸ごとリンク構成からは自動でマイグレーションし、ランタイム状態を実体の `~/.claude` に退避する。
- 冪等。既存の実ファイルは `*.bak.<timestamp>` にバックアップ。

## Layout

| Path | 役割 | 読み込むツール |
|---|---|---|
| `shared/AGENTS.md` | 共通 instructions（通信・安全・検証・Git flow） | 全ツール |
| `.claude/CLAUDE.md` | `@AGENTS.md` + Claude 固有の薄いレイヤー | Claude Code |
| `.claude/rules/` | path-scoped ルール（`paths:` frontmatter で該当ファイルを触った時だけ注入） | Claude Code |
| `.claude/hooks/` | PreToolUse 強制ガード + PostToolUse 自動フォーマット + SessionStart コンテキスト注入 | Claude Code |
| `.claude/agents/` | investigator(haiku) / reviewer(sonnet) / verifier(sonnet) / code-simplifier(sonnet) | Claude Code / Cursor |
| `.claude/skills/` | Agent Skills（オープン標準）。`/commit-push-pr` `/verify-and-ship` は明示呼び出し専用 | Claude Code / Codex / Cursor |
| `codex/config.toml` | Codex グローバル設定 | Codex |
| `cursor/user-rules.md` | Cursor 側セットアップ手順 | （人間用ドキュメント） |
| `tests/test-hooks.sh` | 安全フックの攻撃/正常系マトリクス（CI でも実行） | （開発用） |

## 設計原則

- **Instructions = 指針**（モデルが読む）、**Hooks = 強制**（クライアントが実行）。
  破られると困るルールは hook に昇格させる。
- グローバルには汎用ルールのみ。リポジトリ固有のビルド・テスト・MCP 設定は
  各プロジェクトの `AGENTS.md` / `CLAUDE.md` / `.claude/settings.json` に置く。
- プロジェクト側は `AGENTS.md` を root に置き、`CLAUDE.md` には `@AGENTS.md` と書く
  （Codex / Cursor は AGENTS.md を直接読む）。
- **常時ロードされる指示は最小限に**。CLAUDE.md は User Message として注入されるため
  セッションが伸びるほど影響が減衰する。繰り返し強制したいルールは `paths:` 付きの
  `.claude/rules/` へ、機械的に強制できるものは hook / linter へ降ろす。
- **エージェントに自分の作業を検証する手段を与える**（テスト・ビルド・ブラウザ）。
  失敗から得た修正は再プロンプトでなく rules / skills の Gotchas に書き残す。
- MCP サーバーはグローバルには最小限（context7 のみ）。各サーバーはツールスキーマ分の
  トークンを毎セッション消費するため、AWS / Playwright 等はプロジェクトスコープに置く。

## Maintenance

`.github/workflows/harness-update.yml` が週次で公式ドキュメントと突き合わせて
改善 PR を自動作成する（`workflow_dispatch` で手動実行も可）。

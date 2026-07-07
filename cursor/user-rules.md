# Cursor — Global Setup

Cursor has no on-disk global AGENTS.md (as of 2026-07; it reads AGENTS.md per
project root). Global behavior comes from three places:

1. **User Rules (one-time manual step)**
   Cursor Settings → Rules → User Rules に、`shared/AGENTS.md` の本文を
   そのまま貼り付ける。内容を更新したら再貼り付けが必要（数は少ない想定）。

2. **Skills / Agents — 自動で共有される**
   Cursor は `~/.claude/skills` と `~/.claude/agents` を読み込める。
   install.sh がそこを本リポジトリに向けるので、追加作業は不要。
   （フォールバック用に `~/.cursor/skills` も同じ場所へリンクする。）

3. **Per-project**
   各リポジトリのルートに `AGENTS.md` を置けば Cursor / Codex が読み、
   `CLAUDE.md` に `@AGENTS.md` と書けば Claude Code も同じ内容を読む。

## User Rules に貼る内容

`shared/AGENTS.md` 全文（このリポジトリの canonical instructions）。

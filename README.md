# Claude Code × Obsidian — Session Memory

Give Claude Code a memory that survives between sessions, stored as plain Markdown in your Obsidian vault.

Claude Code forgets everything when a session ends. This is a small set of conventions — a `CLAUDE.md`, two note templates, and one hook — that make Claude write down what happened and find it again next time, so you can say *"continue where we left off"* and it actually can.

Everything here is plain Markdown and one shell script. Nothing to install, nothing to run.

---

## What's in here

| Path | What it does |
|---|---|
| `CLAUDE.md.template` | The operating rules: when Claude saves, where, and what it must fill in |
| `CLAUDE.ja.md.template` | Same rules in Japanese |
| `obsidian/Templates/session-log.md` | One session → one note |
| `obsidian/Templates/research-note.md` | Research notes (optional, for NotebookLM users) |
| `obsidian/Sessions/_index.md` | A Dataview index — for humans, not for Claude (see below) |
| `.claude/settings.json` | Wires up the Stop hook |
| `.claude/hooks/check-session-saved.sh` | Backstop: blocks the stop once if the session wasn't logged |
| `.claude/hooks/check-uncommitted.sh` | Warns about uncommitted changes when Claude stops |
| `.mcp.json.example` | Obsidian MCP connection, with the token blanked out |

## Before you copy this

This repo asks you to drop files into your project that your coding agent will read as trusted
instructions — a `CLAUDE.md` and two hooks that execute on your machine. That is exactly the
channel a poisoned repository uses: hidden instructions in `CLAUDE.md`, `.cursor/rules`, or an
HTML comment inside `README.md`, loaded by the agent as legitimate project guidance.

So please don't copy any of it blind — not this repo, not anyone's.

- Read `CLAUDE.md.template` in full. It is ~90 lines; that is deliberate.
- Read both hook scripts. They are ~50 lines each and run on your machine when the agent stops.
- Read this README as raw text (`cat README.md`), not just rendered. HTML comments are invisible
  when rendered.

Nothing here executes anything at install time, there is no package to install, and the only
network call any of it makes is your own Obsidian instance on localhost. Verify that for yourself
rather than taking my word for it.

## Setup

1. In Obsidian, install the **Local REST API** community plugin and copy its API key.
2. Copy `.mcp.json.example` to `.mcp.json` in your project and paste the key in. **Do not commit it.**
3. Copy `CLAUDE.md.template` into your project as `CLAUDE.md` and edit the paths near the top.
4. Copy the `obsidian/` folder into your vault as `Claude Code/`.
5. Copy `.claude/` into your project, then `chmod +x .claude/hooks/*.sh` — **both** hooks
   need it, and a hook without the execute bit fails silently.

Full walkthrough in [docs/SETUP.md](docs/SETUP.md).

Requires: Obsidian with Local REST API, an MCP-capable Claude Code, `jq` for the hook, and Dataview if you want the index to render.

---

## The one thing that will bite you

**Do not have Claude read the Dataview index to find past sessions.**

A Dataview block is rendered by Obsidian at display time. When Claude reads that file over MCP it gets the raw source — the query itself, not the table of results. The index looks perfect to you and is empty to Claude.

So the two consumers are split on purpose:

- **`_index.md` (Dataview)** — for you. A table you can skim.
- **`search_query` against frontmatter** — for Claude. It searches `summary` and `aliases` directly.

This is why `summary` and `aliases` are mandatory in the template and not decoration. They are what the
session-start lookup matches on. A note saved with an empty `summary` won't appear in that list — you can
still reach it by full-text search, but only if you already know a phrase from its body, which is exactly
what you don't have when you're asking what you were working on last week.

## The second thing that will bite you

**Don't tell Claude to save "when the session ends."** It can't observe that. It answers and
stops; nothing distinguishes "the user is about to type again" from "the session is over." A rule
phrased that way never fires in a one-task conversation — which is most of them.

We shipped that phrasing, tested it on a single-task session, and got zero notes. The rules here
now fire on three things Claude *can* see: the request completing, the topic changing, and a
commit landing. `check-session-saved.sh` is the backstop — if no note exists for today, it blocks
the stop once and tells Claude to write one.

## Why use this when Claude Code already has built-in memory

Built-in memory and a vault are not the same tool, and it's worth running both:

|  | Built-in memory | Obsidian vault |
|---|---|---|
| Holds | Short standing facts | The full account of what happened |
| Read by | Claude, every session | You, and Claude on request |
| Good for | "This user prefers X" | "Here's how we solved that in March" |
| Links to | Nothing else | The rest of your notes |

Use built-in memory for the durable one-liners. Use the vault for the narrative you'll want to reread — and for connecting work to everything else you already keep in Obsidian.

---

## 日本語

Claude Code はセッションが切れると文脈を失います。これは、その対策一式です。`CLAUDE.md` の運用ルール、Obsidian のノートテンプレート2種、フック1つ。中身は Markdown とシェルスクリプトだけで、インストールするものはありません。

**最大の落とし穴：Dataview の索引を Claude に読ませないこと。** Dataview は表示時に Obsidian がレンダリングするので、Claude が MCP 経由で読むとクエリの生テキストしか返りません。人間には完璧に見える索引が、Claude には空に見えます。だから `_index.md`（Dataview）は人間用、Claude は `search_query` で frontmatter を直接検索する、と役割を分けてあります。

テンプレートの `summary` と `aliases` が必須なのはこのためです。**Claude が検索できる唯一の手がかりなので、空のまま保存したノートは二度と見つかりません。**

セットアップは [docs/SETUP.md](docs/SETUP.md) を参照してください。日本語の運用ルールは `CLAUDE.ja.md.template` です。

---

MIT License. Contributions and issues welcome.

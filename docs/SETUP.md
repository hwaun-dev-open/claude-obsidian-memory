# Setup

Takes about 15 minutes. Nothing here installs a package or runs a build.

## Prerequisites

- **Obsidian** with the **Local REST API** community plugin
- **Claude Code** with MCP support
- **`jq`** — only for the uncommitted-changes hook (`brew install jq`)
- **Dataview** — only if you want `_index.md` to render as a table

---

## 1. Obsidian Local REST API

Install the plugin, enable it, and copy the API key from its settings.

The plugin exposes two ports: HTTPS on 27124 and plain HTTP on **27123** (bound to localhost).
The HTTPS one uses a self-signed certificate, which most MCP clients reject without extra
configuration.

**Use `http://127.0.0.1:27123/mcp/`.** Traffic never leaves your machine, so plain HTTP is not
the exposure it would be over a network. If you see connection errors or certificate failures,
this is almost always the cause — check you're on 27123 and not 27124.

## 2. MCP connection

Copy the example into your project and paste your key in:

```bash
cp .mcp.json.example /path/to/your/project/.mcp.json
```

**Add `.mcp.json` to your `.gitignore` before you commit anything.** The file contains an API key
with full read and write access to your vault.

Restart Claude Code and confirm the `obsidian` server connects.

## 3. Vault structure

Copy the `obsidian/` folder into your vault as `Claude Code/`:

```
<your vault>/
└── Claude Code/
    ├── Templates/
    │   ├── session-log.md
    │   └── research-note.md
    └── Sessions/
        └── <project>/
            └── _index.md
```

Create one folder under `Sessions/` per project. In each `_index.md`, change the `from` line of
the Dataview query to that project's path.

## 4. Operating rules

Copy `CLAUDE.md.template` (or `CLAUDE.ja.md.template`) into your project root as `CLAUDE.md`,
then edit:

- The vault paths, if you didn't use `Claude Code/`
- The git section — or delete it if you don't want the git conventions
- The NotebookLM section — delete it unless you use NotebookLM

## 5. The hook

```bash
cp -r .claude /path/to/your/project/
chmod +x /path/to/your/project/.claude/hooks/check-uncommitted.sh
```

Open the script and edit `EXCLUDES` for directories it should ignore, and `MAXDEPTH` for how deep
to search.

If your setup doesn't expand `$CLAUDE_PROJECT_DIR` in hook commands, put the absolute path in
`.claude/settings.json` instead.

Test it directly — it should print nothing when every repository is clean:

```bash
CLAUDE_PROJECT_DIR=/path/to/your/project .claude/hooks/check-uncommitted.sh
```

---

## Checking it works

1. Start a session, do something small, and let it end. Claude should write a note under
   `Claude Code/Sessions/<project>/`.
2. Open the note. **`summary` and `aliases` must not be empty.** If they are, the rules aren't
   being followed and the note is effectively lost — the next session won't find it.
3. Start a new session and ask to continue that topic by name. Claude should find the note via
   `search_query` and pick up from it.

Step 2 is the one that actually matters. An empty `summary` doesn't destroy the note — full-text
search still reaches it — but it drops out of the session-start list, which is the one place you
look when you can't remember what you were doing.

## Troubleshooting

**Claude can't find past sessions.**
Check that it's searching frontmatter with `search_query`, not reading `_index.md`. Dataview
renders at display time — over MCP the index file is just the query text. This is the single most
common failure, and it's silent: the index looks right to you.

**Notes save with an empty `summary`.**
The rule needs to state *why* the field exists, not just that it's required. The wording in the
template ties it to next-session retrieval on purpose. Keep that reasoning in.

**Claude saves too late, or only when asked.**
The rules deliberately include "save when the topic changes, don't wait to be asked." If you drop
that clause, long sessions end up as one unsearchable note.

**Hook prints nothing, ever.**
That's the intended behavior when everything is clean. Make an uncommitted change and run it
directly to confirm. If it's still silent, check `jq` is installed and the script is executable.

---

## Verified behavior

Measured against Obsidian Local REST API over MCP, 2026-08-30. Two notes were placed in a test
folder — one with `summary` and `aliases` filled, one with both empty — and both contained the
same unique keyword **in the body**. Alongside them, an `_index.md` holding a Dataview query over
that folder.

| Query | Result |
|---|---|
| `regexp` on `frontmatter.summary` | Note A only |
| `in` on `frontmatter.aliases` | Note A only |
| `regexp` on `content` | **Both notes** |
| `vault_read` on `_index.md` | The query source. **Zero rows.** |

Two things follow, and they're the reason this repo exists.

**The Dataview index is invisible to Claude.** Reading `_index.md` returned the fenced
` ```dataview ` block verbatim — the table you see in Obsidian is rendered client-side and never
reaches the API. Neither note appeared anywhere in the response. Point Claude at the index and it
sees an empty document with confidence.

**An empty `summary` is a downgrade, not a deletion.** Full-text search still found note B. What
it lost is the session-start lookup, which matches on `summary` and `aliases` — the one path that
works when you don't yet remember any keyword to search for.

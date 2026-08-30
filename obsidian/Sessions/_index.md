---
tags: [claude-session-index]
---

Claude Code session log for this project. Dataview keeps this table up to date — no manual edits.

> [!warning] For humans only
> Claude must not read this file to find past sessions. Dataview renders at display time, so
> reading this over MCP returns the query below, not the table. Claude searches frontmatter
> directly with `search_query`.

```dataview
table summary as "概要", status as "状態", tags as "タグ"
from "Claude Code/Sessions/<project>"
where file.name != "_index"
sort file.name desc
```

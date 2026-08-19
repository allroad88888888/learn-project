---
name: project-lines
description: "<Project> — confirmed main line(s) and branch lines: where things live, how data moves, which member to imitate, which drift not to copy. Read this index first, then only the 1–2 relevant line files. Learned <date> at commit <sha>; owner-confirmed sections are marked."
---

# <Project> · line index

> Learned by `learn-project` at commit `<sha>` (<date>). Numbers below come from
> `mechanical/` and can be recomputed with `check.sh`. Confirmed sections are marked ✅;
> unconfirmed content does not drive code changes.

## How to use this
- Task → find the line below → read that file (≤ 300 lines) → imitate its sample member, touch
  its recipe files, do not copy its drift → finish by checking the diff still lies on the line.
- Never re-scan the repo for a local task. Update a line only when the owner changed the design.

## Lines
| File | Line | Kind | Hub (runtime / edit) | Status |
|---|---|---|---|---|
| `lines/00-main-<x>.md` | … | main | — | ✅ / open |
| `lines/10-branch-<y>.md` | `<dir>/*` (N members, `<pkg-prefix>`) | branch | `<hub>` (n/N) | … |

**Common layer (not a line):** `<dir>/*` — N packages, imported by … , no hub.

## Structural corrections found while tracing (cross-validated by ≥ 2 lines)
- …

## Confirmed rules (owner ✅)
- …

## Confirmed design decisions / confirmed drift (do not imitate) / "keep" legacy
- …

## Mechanical evidence (from `mechanical/`, model not involved)
### Import direction
```
…
```
### Family shapes
```
…
```
### Timelines / recipes
- …

## Docs vs code (fix; no decision needed)
- …

## Open questions
See `questions.md` (N open).

## Cost of learning
| Line | Files opened | Tokens | Time |
|---|---|---|---|
| … | … | … | … |
Extraction: <s> seconds, zero tokens.

---
name: learn-project
description: "Learn a codebase once and keep the understanding with the repo, not the chat. Traces the project's main line and branch lines from code + git history (counted evidence, file:line citations, standard / other-kind / drift), hands the owner a short list of questions to confirm, then every later task reads 1–2 confirmed lines instead of the whole repo. Use when taking over a repo, 'learn this project', 'how is this designed', 'where should X go', onboarding an agent to a codebase, checking a change still follows the design, or detecting drift after many commits. 中文版见 SKILL.zh-CN.md：学会一个仓库的主线与分支线，交负责人确认，之后每次任务只读相关的线。"
---

# learn-project

> If the conversation is in Chinese, read `SKILL.zh-CN.md` instead — same procedure, Chinese templates.

A repository has a **main line** (the path every request takes from entry to output) and a few
**branch lines** (families of pluggable members that join the main line at a hub). Later changes
rarely touch these; they are what a newcomer needs and what nobody writes down. This skill makes
an agent extract them **from code and git history**, with counted evidence, hands the owner a
short list of questions, and stores the confirmed result **inside the repo** so it survives closed
windows, new sessions and model swaps. Afterwards a task reads 1–2 line files (each < 120 lines),
not the codebase.

Not a memory plugin, not chat compression, not a vector store, not one big `ARCHITECTURE.md`
reloaded every time. Plain markdown + shell scripts; works in any agent that loads skills.

## Vocabulary

| Term | Meaning | Mechanical signature |
|---|---|---|
| **Line** | One end-to-end path with a stable design: entry → steps → output, who owns what, how to add one | — |
| **Main line** | The spine every instance passes through | singleton (no siblings), high fan-in, on the path from the entry |
| **Branch line** | A family of same-shaped members hanging off the main line | ≥5 sibling dirs with a shared shape **+ a hub** (one file referencing most members) |
| **Common layer** | Shared utilities — *not* a line | high fan-in, no hub, no shared shape |
| **Sample member** | The member to imitate | founding member (earliest in git) or the most recent *clean* one, both on-shape |
| **Recipe** | Files to touch to add one member | intersection of ≥3 member-birth commits |
| **Other kind** | Same directory, different mechanism | off-shape and hub does not reference it |
| **Drift** | Same mechanism, wrong way | few, late, off-shape; owner marks "do not imitate" |
| **Verdict** | Owner's answer to a question | folded back into the line file, dated, attributed |

## Output layout

Default target: `<repo>/.claude/skills/project-lines/` (Claude Code auto-loads its `SKILL.md`
index in every session; other agents: put the index wherever they auto-load, e.g. reference it
from `AGENTS.md`). Use `.project-lines/` if the repo must stay agent-neutral.

```
project-lines/
├── SKILL.md            index — the only file loaded by default (templates/en/index.md)
├── lines/              00-main-*.md, 01-main-*.md, 10-branch-*.md … (templates/en/line.md), each ≤ 300 lines
├── questions.md        open questions for the owner (templates/en/questions.md)
└── mechanical/         extractor baseline from scripts/extract-all.sh — commit it; check.sh diffs against it
```

Everything is git-tracked with the code: line edits show up in PRs, corrections are diffs, and
"only the owner changes the design" is enforced by review, not by tooling.

## Procedure A — Learn (once per repo; expensive on purpose, reused by the whole team)

1. **Scope** — `git ls-files` only (never `ls`: worktrees carry untracked leftovers from other
   branches). Note languages, entry points, workspace manifests, test/build commands, and any
   existing docs (`README`, `CLAUDE.md`, checklists, `.cursor/rules`) — **hints to verify, not
   authority**.
2. **Mechanical extraction** — `bash scripts/extract-all.sh <repo> <out>/` (seconds to a couple of
   minutes, zero tokens). Read `<out>/SUMMARY.md`: families with member counts and core files,
   top hub per family with coverage, import-direction matrix; per family `hubs-*`, `timeline-*`,
   `recipe-*`; `churn-*` for spine candidates. Details: `references/en/extractors.md`.
3. **Decide the candidate lines** — main line(s): from each entry follow the highest fan-in,
   lowest churn singletons; branch lines: family + hub with coverage ≥ 60 %; common layer:
   fan-in without hub (name it in the index, do not trace it). Tell the user the candidate list
   and proceed unless they object (do not block on this).
4. **Trace, one subagent per line, in parallel** — prompt from `templates/en/trace-prompt.md`
   filled with that line's mechanical evidence. Each subagent reads the sample members plus a few
   others plus the outliers (not every member), cites `file:line`, counts instead of guessing,
   splits standard / other kind / drift, notes where docs disagree with code, asks ≤ 5 questions
   each with two readings, writes `lines/NN-*.md` (≤ 300 lines) and reports files opened.
   Expect ~60–90 files and ~150k tokens per line.
5. **Merge** — you, not a subagent: (a) **cross-validation**: a fact reached independently by
   ≥ 2 lines is promoted to the index as a structural correction (e.g. "four directories are really
   two assembly families"); conflicts become questions; (b) dedupe questions across lines;
   (c) apply `references/en/question-filter.md` (drop anything the code can answer or that does
   not change where new code goes; name members; one question per item; allow "both" and free
   text); (d) write `SKILL.md` index from `templates/en/index.md` with the mechanical evidence,
   cross-validation list and a cost table; (e) write `questions.md`; (f) copy `<out>/mechanical/`
   into the target directory.
6. **Confirm** — hand `questions.md` to the owner. Answer vocabulary: **A / B / both / by design /
   legacy / don't know / free text**. Fold every answer back into the line file's *Verdicts*
   section (`references/en/verdicts.md`); promote confirmed rules into the index; mark lines
   nobody confirmed as not-in-default-index (`hidden` frontmatter where supported).
7. **Report** — what was produced, cost, cross-validated facts, open questions, and any doc
   drift found (docs vs code) as a separate "fix, no decision needed" list.

## Procedure B — Task (every later job)

1. Read the index; open only the 1–2 relevant line files. Do not re-scan the repo.
2. State where the change belongs, which sample member you will imitate, which recipe files
   you will touch, which rules apply, and which known drift you will **not** copy.
3. Open only the files the task needs (sample member, hub, recipe files, tests). Then change
   real files, run tests, look at the diff.
4. Finish with two checks: tests pass; **the diff still lies on the line** (same entry, same
   ownership, same hub, same shape). If not, say so.
5. Update a line only when the owner **changed the design** (data flow, ownership, hub, shape,
   extension recipe). A normal feature never edits a line. Propose the edit; do not silently apply.
6. Discard the chat. If interrupted, leave a small `current-task.md` (done / files / next step)
   — not a transcript.

## Procedure C — Check (after many commits, or in CI)

`bash scripts/check.sh <repo> <project-lines dir>` re-runs the extractors and diffs families,
hubs, imports, timelines and recipes against `mechanical/`; it also lists members born since the
baseline commit. Exit 1 = drift: re-read the affected line, re-learn only that line, and let the
owner confirm again. `churn-*` is informational and not diffed.

## Hard rules

1. Tracked files only (`git ls-files`).
2. Evidence is **counted** ("13/35 exact shape", "hub references 35/35"), never felt.
3. Every mechanism claim cites `file:line`. No citation → mark as unverified.
4. Three-way split, always: standard / other kind / drift. Off-shape ≠ wrong.
5. Drift is "do not imitate", **not** a cleanup task. Owners usually answer "keep".
6. Existing docs are hints; verify them and list disagreements. Learning audits the docs.
7. Ask only what changes where new code goes; ≤ 5 per line; name members; one item per question;
   never ask what the code can answer.
8. The model does not decide the design — the owner does. Unconfirmed content does not drive
   code changes.
9. Every produced file ≤ 300 lines; one line per file.
10. Cost is spent once, at learn time; a task reads ≤ 2 line files.

## Reference run (for expectations)

A 150-package JS monorepo (5k tracked files, 1.3k commits): extraction 23 s; 6 lines traced in
parallel in ~10 min, ~445 files opened, ~860k tokens; owner answered 21 of 23 questions in about
30 minutes; one new rule, five "by design", three confirmed drifts, five "keep". Two mechanical
signals were corrected by tracing (a "noise" file was actually the new member's consumer; a
21-dir family was 16 tracked + 5 untracked leftovers) — which is why extraction proposes and
tracing decides.

## Files

- `SKILL.md` / `SKILL.zh-CN.md` — this procedure (English / Chinese)
- `templates/{en,zh}/` — `index.md`, `line.md`, `questions.md`, `trace-prompt.md`
- `references/{en,zh}/` — `method.md`, `extractors.md`, `question-filter.md`, `verdicts.md`
- `scripts/` — `extract-all.sh`, `families.sh`, `hubs.sh`, `imports.sh`, `timeline.sh`,
  `recipe.sh`, `churn.sh`, `check.sh`, `lib.sh` (bash 3.2+, git, awk; language-agnostic)

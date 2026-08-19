# learn-project

**Learn a codebase once. Keep the understanding with the repo, not the chat.**
[中文说明](README.zh-CN.md)

`learn-project` is an agent skill (plain markdown + shell) that turns a repository into a small
set of owner-confirmed **line files** — the project's main line and branch lines: how data moves,
who owns what, which member to imitate, how to add one, which code is drift you must not copy.
Every later task reads one or two of these files instead of re-scanning the repo. Close the
window, switch models, open a new session: the understanding is still there, because it lives in
the repo and is reviewed like code.

It works in any agent that loads skills (Claude Code, Codex, your own runtime). It is **not** a
memory plugin, chat compression, a vector store, or one big `ARCHITECTURE.md`.

## What you get

```
<repo>/.claude/skills/project-lines/     (or .project-lines/)
├── SKILL.md         index: lines, hubs, confirmed rules, structural corrections, cost — auto-loaded
├── lines/           one file per line, ≤ 300 lines, every claim cites file:line, numbers are counted
├── questions.md     ≤ ~20 questions for the owner, each with two readings; answers folded back
└── mechanical/      deterministic extractor output — the baseline for drift checks
```

## How it works

1. **Extract (scripts, zero tokens, seconds):** family shapes, hubs (the file that references most
   members), import direction between directories, first-appearance timelines, "how to add one"
   from the intersection of member-birth commits, churn. Tracked files only.
2. **Trace (one subagent per line, in parallel):** follow the sample member end to end, cite
   `file:line`, count instead of guess, split off-shape members into *other kind* / *drift* / *fine*,
   note where docs disagree with code, ask ≤ 5 questions.
3. **Merge:** cross-validate facts found independently by several lines, dedupe questions, filter
   out anything the code can answer or that doesn't change where new code goes.
4. **Confirm:** the owner answers `A / B / both / by design / legacy / don't know / free text`;
   verdicts are folded into the line files and rules promoted to the index.
5. **Use:** a task reads the index + 1–2 lines, imitates the sample member, touches the recipe
   files, does not copy drift, and ends by checking the diff still lies on the line.
6. **Check:** `scripts/check.sh` re-runs the extractors later and reports drift.

## Install

Claude Code (user-wide):
```bash
git clone https://github.com/allroad88888888/learn-project ~/.claude/skills/learn-project
```
Project-local: clone into `<repo>/.claude/skills/learn-project`. Other agents: point them at
`SKILL.md` (English) or `SKILL.zh-CN.md` (Chinese); the scripts need only `bash 3.2+`, `git`,
`awk`, `grep`, `sort`.

## Use

In your agent, on the repo you want to learn:
```
/learn-project            # or: "learn this project"
```
Later:
```
"add an X" / "where should Y go" / "does this change still follow the design?"
```
Drift check any time (or in CI):
```bash
bash ~/.claude/skills/learn-project/scripts/check.sh <repo> <repo>/.claude/skills/project-lines
```
Run the extractors alone:
```bash
bash scripts/extract-all.sh <repo> /tmp/out && cat /tmp/out/SUMMARY.md
```

## Reference run

A 150-package JS monorepo (5k tracked files, 1.3k commits): extraction 23 s; 6 lines traced in
~10 min in parallel, ~445 files opened, ~860k tokens; the owner answered 21 of 23 questions in
about 30 minutes → 1 new rule, 5 "by design", 3 confirmed drifts, 5 "keep". Four lines
independently found the same hidden structure; the extractors' recipe found two files the
hand-written checklist had missed; the docs' framework version was wrong. Also tested on a
Rust workspace (renamed-crate imports resolved).

## Layout of this repo

```
SKILL.md / SKILL.zh-CN.md      the procedure (EN / ZH)
templates/{en,zh}/             index.md · line.md · questions.md · trace-prompt.md
references/{en,zh}/            method.md · extractors.md · question-filter.md · verdicts.md
scripts/                       extract-all · families · hubs · imports · timeline · recipe · churn · check · lib
```

## Principles (short)

Tracked files only · evidence is counted, not felt · every claim cites `file:line` · standard /
other kind / drift, always · drift means "do not imitate", not "delete" · docs are hints, verify
them · ask only what changes where new code goes · the owner decides the design, not the model ·
files ≤ 300 lines · spend once at learn time, read ≤ 2 files per task.

## License

MIT

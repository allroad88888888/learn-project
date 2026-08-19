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

One skill source, several channels. Open the one you use — each is a single command.

<details>
<summary><b>Claude Code</b> — skill (user-level or project-level) or plugin</summary>

User-level (`~/.claude/skills/learn-project`):

```bash
curl -fsSL https://raw.githubusercontent.com/allroad88888888/learn-project/main/install.sh | bash -s -- --claude
```

Project-level (`<repo>/.claude/skills/learn-project`, travels with the repo):

```bash
curl -fsSL https://raw.githubusercontent.com/allroad88888888/learn-project/main/install.sh | bash -s -- --claude-project <repo>
```

As a plugin (inside Claude Code):

```
/plugin marketplace add allroad88888888/learn-project
/plugin install learn-project@learn-project
```
</details>

<details>
<summary><b>Codex</b> — native skill</summary>

```bash
curl -fsSL https://raw.githubusercontent.com/allroad88888888/learn-project/main/install.sh | bash -s -- --codex
```

Lands in `$CODEX_HOME/skills/learn-project` (default `~/.codex/skills`). Or just tell Codex:
*"install the skill from allroad88888888/learn-project, path skills/learn-project"* — its built-in
`skill-installer` does it.
</details>

<details>
<summary><b>DeepSeek Harness (dsh)</b> — native skill, no plugin needed</summary>

```bash
curl -fsSL https://raw.githubusercontent.com/allroad88888888/learn-project/main/install.sh | bash -s -- --dsh
```

Lands in `$DSH_HOME/skills/learn-project` (default `~/.dsh/skills`). Also available:
`--dsh-project <repo>` → `<repo>/.dsh/skills`; `--agents-home` → shared `~/.agents/skills`
(`$DSH_AGENTS_HOME`, read by dsh and other clients).
</details>

<details>
<summary><b>Cursor</b> — a rule that points at the skill</summary>

```bash
curl -fsSL https://raw.githubusercontent.com/allroad88888888/learn-project/main/install.sh | bash -s -- --cursor <repo>
```

Writes `<repo>/.cursor/rules/learn-project.mdc` (`alwaysApply: false`, description-triggered) whose
body says "read and follow `…/learn-project/SKILL.md`". Combine with `--claude-project <repo>` and the
rule uses the project-relative path.
</details>

<details>
<summary><b>Gemini CLI / GitHub Copilot / anything that reads <code>AGENTS.md</code></b></summary>

```bash
curl -fsSL https://raw.githubusercontent.com/allroad88888888/learn-project/main/install.sh | bash -s -- --agents-md <repo>
```

Appends a marked pointer block to `<repo>/AGENTS.md` (or name the file: `--agents-md <repo>/GEMINI.md`,
`--agents-md <repo>/.github/copilot-instructions.md`). `--uninstall` removes exactly that block.
</details>

<details>
<summary><b>Any runtime that loads <code>&lt;dir&gt;/&lt;name&gt;/SKILL.md</code></b></summary>

```bash
curl -fsSL https://raw.githubusercontent.com/allroad88888888/learn-project/main/install.sh | bash -s -- --dir <path>
```

Lands in `<path>/learn-project`. The skill follows the open [Agent Skills](https://agentskills.io)
format (`SKILL.md` with `name`/`description`), so any client listed there can load
`skills/learn-project/` directly.
</details>

<details>
<summary><b>Everything at once, options, uninstall</b></summary>

```bash
curl -fsSL https://raw.githubusercontent.com/allroad88888888/learn-project/main/install.sh | bash -s -- --all   # = --claude --codex --dsh
```

`install.sh` is idempotent. Options: `--copy` (copy instead of symlink), `--ref v0.1.0` (pin a
version), `--uninstall` (with the same target flags). Run from a local clone (`./install.sh …`)
and it links to that clone, so editing the clone updates every agent; via `curl` it clones to
`~/.learn-project` (override with `LEARN_PROJECT_HOME`) and links from there. Scripts need only
`bash 3.2+`, `git`, `awk`, `grep`, `sort`.
</details>

<details>
<summary><b>Windows</b> — Git Bash/WSL, or native PowerShell</summary>

If your agent already needs Git Bash or WSL for its shell tool on Windows (most coding agents
do), just run any command above from inside it — `install.sh` works as-is.

Without Git Bash, install natively with PowerShell (5.1+ or `pwsh`), no bash needed to place the
files — same flags, PascalCase:

```powershell
iwr -useb https://raw.githubusercontent.com/allroad88888888/learn-project/main/install.ps1 -OutFile install.ps1
powershell -ExecutionPolicy Bypass -File install.ps1 -Claude -Codex
```

Symlinks need Administrator or Developer Mode; without either, `install.ps1` falls back to
copying automatically (pass `-Copy` to always copy). One caveat either way: *placing* the skill
needs no bash, but *running* it — `scripts/*.sh` at learn/check time — still does. That's already
true of most coding agents' shell tool on Windows, so if your agent can run shell commands at
all, bash is already available to it.
</details>

## Use

In your agent, on the repo you want to learn:
```
/learn-project            # or: "learn this project"
```
Later:
```
"add an X" / "where should Y go" / "does this change still follow the design?"
```
Drift check any time, or in CI:
```bash
bash ~/.claude/skills/learn-project/scripts/check.sh <repo> <repo>/.claude/skills/project-lines
```
```yaml
# .github/workflows/lines-check.yml
- uses: actions/checkout@v4
  with: { fetch-depth: 0 }
- run: git clone --depth 1 https://github.com/allroad88888888/learn-project /tmp/lp
- run: bash /tmp/lp/skills/learn-project/scripts/check.sh . .claude/skills/project-lines
```
Run the extractors alone:
```bash
bash skills/learn-project/scripts/extract-all.sh <repo> /tmp/out && cat /tmp/out/SUMMARY.md
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
skills/learn-project/          the skill (Agent Skills format)
  SKILL.md / SKILL.zh-CN.md      the procedure (EN / ZH)
  templates/{en,zh}/             index.md · line.md · questions.md · trace-prompt.md
  references/{en,zh}/            method.md · extractors.md · question-filter.md · verdicts.md
  scripts/                       extract-all · families · hubs · imports · timeline · recipe · churn · check · lib
.claude-plugin/                plugin.json + marketplace.json (Claude Code plugin channel)
install.sh                     installer (bash) for Claude Code / Codex / DeepSeek Harness / Cursor / AGENTS.md / any skills dir
install.ps1                    same installer, native Windows PowerShell (no Git Bash/WSL needed to install)
```

## Principles (short)

Tracked files only · evidence is counted, not felt · every claim cites `file:line` · standard /
other kind / drift, always · drift means "do not imitate", not "delete" · docs are hints, verify
them · ask only what changes where new code goes · the owner decides the design, not the model ·
files ≤ 300 lines · spend once at learn time, read ≤ 2 files per task.

## License

MIT

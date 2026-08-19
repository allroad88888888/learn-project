# Method — why lines, and what the scripts vs the model each do

## The problem this solves
Every new agent session on a large repo re-derives the same things: how data moves, why files
live where they do, who owns which state, where a new feature plugs in, which implementation is
the reference and which is a shortcut. The owner explains it again in chat; the explanation
evaporates when the window closes; `CLAUDE.md`/`AGENTS.md` cannot hold it all and drifts.
The fix is not better chat memory. It is a **project-owned understanding**: small files, tied to
the code, confirmed by the owner, selectable per task.

## Why "line" is the unit (not "rule")
Rules ("UI must not touch the DB") are constraints extracted *from* something. That something is
a line: one end-to-end path with a stable design. Lines have three advantages: a task maps onto
a line naturally ("add an export action" → the action line); a line carries its own sample member
and recipe; a line is short enough (< 120 lines in practice) to be read whole — no fuzzy
"retrieve relevant rules" step. Rules are still recorded, as by-products of lines.

## Main line, branch lines, common layer — mechanical criteria
- **Main line**: singleton (no siblings of the same shape), highest fan-in, low churn after
  creation, on the path from an entry point. A repo may have more than one (runtime vs editor).
- **Branch line**: a **family** (≥ 5 sibling directories sharing a shape) **plus a hub** (one file
  outside the family referencing most members; coverage ≥ 60 %). Family without hub is not a line.
- **Common layer**: high fan-in from several families, no hub, no shared shape (utilities). Named
  in the index, not traced.
Directories can lie: in the reference run, four directories turned out to be two assembly
families (two hubs). Only tracing reveals that; extraction only proposes.

## What is mechanical (scripts) and what needs the model
| Signal | Script | Model's job |
|---|---|---|
| family shape, core files, outliers | `families.sh` | classify outliers: other kind / drift / fine |
| hub and its difference set | `hubs.sh` | explain the difference set (why 4 members are missing) |
| import direction between dirs | `imports.sh` | turn "148/150 comply" into a rule + 2 named exceptions |
| founding vs latest members | `timeline.sh` | choose sample members; detect migration in progress |
| how to add one (commit intersection) | `recipe.sh` | reconcile with hub code and existing checklists |
| stable spine vs edges | `churn.sh` | pick main-line files to read first |
Evidence is **counted** by scripts; the model **names, traces one sample end to end, explains,
and classifies**. Never ask the model "what is the rule" — hand it the counts and ask it to
explain them and find the exception's reason.

## Cross-validation instead of "confidence"
Trace lines independently. A fact reached by two or more lines from different entries is stronger
than any single trace ("the options panel is a UX tree rendered by the same core view" was found
by four lines; "edit.tsx is a dead stub" by three; the same doc drift by all six). Promote these
to the index. Conflicts between lines become questions. This replaces the hand-wavy
"confidence: high/medium/low" field: what matters is *how many independent traces agree* and
*whether the owner confirmed*.

## Standard / other kind / drift
Off-shape members are not automatically wrong. Three outcomes:
- **standard** — on-shape, on-hub, imitate;
- **other kind** — same directory, different mechanism (e.g. infrastructure packages living next
  to plug-in actions); document, do not imitate for the plug-in case;
- **drift** — same mechanism, off the standard path (late, few, sometimes half-finished). Mark
  "do not imitate". Owners overwhelmingly answer "keep": drift is not a cleanup task.
Majority vs recency: if the majority follows shape A but the last three members follow B, that is
a migration in progress — one of the few questions worth asking the owner.

## Existing docs
Treat `README`, `CLAUDE.md`, checklists, `.cursor/rules` as hints and as a gold standard to
compare against — in both directions. In the reference run the docs named a wrong framework
version and missing files; the checklists lacked two of the recipe files. Learning audits docs.

## Cost model
Learn once: seconds of extraction + one subagent per line (~60–90 files, ~150k tokens each,
parallel) + ~30 minutes of the owner's time. Then every task reads the index and 1–2 lines.
The team reuses the result; a model swap loses nothing.

## What this deliberately does not do
No vector DB, no chat-log compression, no per-session re-scan, no automatic design changes,
no deleting drift, no multi-repo knowledge sharing (yet).

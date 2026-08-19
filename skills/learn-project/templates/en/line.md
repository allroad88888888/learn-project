# Line: <name>
One sentence: <what this line is, in one sentence without "and">
Kind: main line | branch line — joins the main line at `<file>:<function>` (runtime) and `<file>:<function>` (edit / config time)

## Entry (where one instance starts; cite file:line)
- …

## How data moves (step by step; every step cites file:line)
1. Declare → …
2. Register → …
3. Trigger / render → …
4. Execute / read-write → …
5. Result goes to → …

## Who owns what
| Part | Responsibility | State it owns | Who may call it | Must not |
|---|---|---|---|---|
| … | … | … | … | … |

## Shape (branch lines: directory / file shape with counts; required vs optional files)
- Members: N (git-tracked). Exact main shape: k/N `{…}`; supersets: m/N; off-shape: listed below.
- Required: … Optional: …

## Sample members (name 1–2 and why: founding / simplest / most recent and clean)
- `<member>` — …

## Adding one (touched files; state the source of each: git recipe intersection / hub code / existing checklist; note disagreements)
- `<file>` — source: …

## Beyond the standard
### Other kind (same directory, different mechanism)
- `<member>` — why it is a different thing: …
### Drift / legacy (few, late, off-shape — cite and say why; "do not imitate", not "delete")
- `<member or file:line>` — …
### Open questions (≤ 5; only ones that change where new code goes; name the members; two readings each)
1. **<topic>** (`<file:line>`): A … ; B …

## Docs vs code (existing docs that disagree with the code)
- `<doc>` says … ; code does … (`<file:line>`)

## Verified at: commit `<sha>`, <date>; files opened: N

## Verdicts (appended after the owner answers — date, who; keep the question numbers)
- #n → **A / B / both / by design / legacy / don't know** — <consequence for new code>

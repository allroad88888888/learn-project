# Extractors — what each script computes, limits, extending

All scripts: `bash 3.2+`, `git`, `awk`, `sort`, `grep`; `LC_ALL=C`; tracked files only
(`git ls-files`); noise dirs (`node_modules`, `target`, `dist`, `esm`, `@types`, …) and binaries
excluded (`lib.sh: NOISE_RE`); tests excluded where noted (`TEST_RE`). Language-agnostic by
construction: they work on **file shapes, package identifiers and git history**, not on syntax.

| Script | Args | Output | Notes |
|---|---|---|---|
| `extract-all.sh` | `REPO OUT [--min N]` | `OUT/mechanical/*.txt` + `OUT/SUMMARY.md` | runs everything; `mechanical/` is the baseline for `check.sh` |
| `families.sh` | `REPO [--min N] [--depth D] [DIR…]` | per family: members, top shapes, core files (≥ 60 %), outliers | fingerprint = tracked files ≤ 2 levels deep inside each member; auto-detects dirs with ≥ N children (default 5) |
| `hubs.sh` | `REPO FAMILY [--top N]` | files outside the family ranked by distinct members referenced; difference sets for the top 3 | identifier = package name (`package.json`/`Cargo.toml`/`pyproject`/`go.mod`) else dir name (≥ 4 chars); boundary-matched; docs, lockfiles, `tsconfig*` are never hubs |
| `imports.sh` | `REPO [--dirs a,b,…] [--mode import\|mention]` | matrix "row imports from column" | `import` mode keeps only import-like lines (`import/from/use/require/include/extern crate/export … from`, bare quoted lines for Go blocks); `mention` counts any occurrence (catches schema-string references; noisier). Rust ids also match `-`→`_`; renamed packages (`x = { package = "y" }`) also match the directory name |
| `timeline.sh` | `REPO FAMILY` | first-appearance date + birth commit per member, sorted; founding/latest flagged | earliest ≈ original design; last three ≈ current practice |
| `recipe.sh` | `REPO FAMILY [--n N] [--max-files M]` | files touched outside the member by the N cleanest birth commits, and their intersection | commits touching > M files (default 60) are skipped as squash noise; if none is clean, says so |
| `churn.sh` | `REPO DIR [--top N]` | commits per file, most/least changed | tests excluded; informational, not diffed by `check.sh` |
| `check.sh` | `REPO LINES_DIR` | diff of families/hubs/imports/timelines/recipes vs baseline; members born since baseline; exit 1 on drift | re-learn only the affected lines |

## Reading the outputs
- **Family with a hub covering ≥ 60 %** → branch-line candidate. Hub coverage < 60 % → probably a
  common layer (utilities), not a line.
- **Difference sets** ("hub lacks: a b c d") are where "other kind" and "drift" hide — hand them to
  the tracing subagent explicitly.
- **Import matrix**: a column that no row imports except the entry is a spine candidate; a family
  that only imports core + common and never app/loader is a rule candidate; sibling imports are
  few and each needs classifying (shared base = fine; reaching into another family's internals =
  drift).
- **Recipe**: the intersection is the "adding one" list; compare with any existing checklist —
  in the reference run the intersection found two files the hand-written checklist had missed.
- **Timeline**: founding members are sample-member candidates; if the latest three differ in
  shape from the majority, a migration is in progress — ask the owner.

## Known limits
- Identifiers < 4 chars are ignored (too noisy); repos with no manifests fall back to directory
  names and get noisier hubs.
- `imports.sh` counts files, not import statements; `mention` mode is needed for languages whose
  imports are not line-shaped (some Go blocks are handled).
- Family detection is directory-based; families expressed by naming convention inside one
  directory (`*_handler.py`) are not detected — pass candidate DIRs by hand or extend
  `families.sh` with a name-pattern mode.
- Speed: dominated by `git grep`; a 5k-file monorepo takes ~20 s end to end.

## Extending
Add a script that prints a stable text table, wire it into `extract-all.sh`, and it is
automatically part of the `check.sh` baseline. Keep outputs deterministic (sorted, `LC_ALL=C`)
so diffs are meaningful.

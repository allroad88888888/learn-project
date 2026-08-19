<!-- Subagent prompt for tracing ONE line. Fill every <…>. One subagent per line, run in parallel. -->

You are in <repo path> (<one line: stack, workspace layout>). Task: trace and write the
**<line name>** line — <one sentence: what the line is, from where to where>. This is a
"project understanding" file for the project owner to confirm; not documentation for a model.

## Known mechanical evidence (cite freely; do not recompute)
- <paste the relevant parts of mechanical/: family shape counts, hub counts and difference sets,
  timeline first/last, recipe intersection, import-direction rows, churn top/bottom>
- Existing docs are hints, verify against code: <list>. Where docs and code disagree, say so.

## How to work
1. Start at <entry file> and follow imports/calls until <end condition: one member rendered /
   one event executed / one value propagated>. Read code with grep/sed/cat; do not paraphrase docs.
2. Read the sample members fully (<sample A: founding>, <sample B: latest clean>) plus 2–3 others
   and every outlier the evidence lists. Do not read all N members. Count what you claim.
3. For every mechanism claim cite `file:line`. Explain who consumes each declared field, what the
   member exports, who calls it, how it registers, where its state lives, what it must not touch.
4. Split what is off-shape into: **other kind** (different mechanism) / **drift** (same mechanism,
   wrong way) / **fine** (different files, same mechanism). Give reasons and counts.
5. Compute "adding one": intersect ≥ 3 member-birth commits' touched files; compare with the hub
   code and with any existing checklist; write out disagreements.
6. Open questions: ≤ 5, only where two readings are both plausible AND the answer changes where
   new code goes; name the members/files; one item per question.
7. Track how many files you opened.

## Output
Write `<target>/lines/<NN-name>.md` (mkdir -p), **≤ 300 lines**, following exactly the template
in `<path to templates/en/line.md>` (same headings, same order). Then reply with only:
a ≤ 15-line summary, the open questions verbatim, and the number of files opened. Do not paste
the file back.

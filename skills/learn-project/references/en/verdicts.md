# Verdicts — folding the owner's answers back, and when a line may change

## Folding back
1. Append a `## Verdicts (<date>, <who>)` section to each affected line file; keep the question
   numbers so the source stays traceable. One bullet per verdict, ending with the consequence for
   new code ("new registrations go to `selfLogic.ts`; `loader/` is not dead code").
2. Where a verdict changes a statement in the body, edit the body too (a diff-friendly one-line
   change) and reference the verdict number.
3. Promote to the index: confirmed **rules** (things every new change must respect), confirmed
   **design decisions**, confirmed **drift** (do not imitate), and "keep" legacy.
4. Update `questions.md` status: answered / open / withdrawn (withdrawn = the code answered it;
   say what the answer was).
5. Record who confirmed. Multi-author repos are normal: "not my decision" is a legitimate verdict.

## What confirmation means for later tasks
- ✅ confirmed lines and rules are authoritative: new code follows them without asking.
- Unconfirmed lines are readable but never drive a change on their own; the agent states the
  assumption it is making and flags it.
- Where the index supports it, mark unconfirmed lines `hidden` so they do not enter the default
  context; they are still reachable by reference.

## When a line may change (and only then)
- The owner explicitly changes data flow, ownership, hub, shape or the extension recipe.
- A new bottom-level rule is confirmed.
- `check.sh` shows structural drift (new hub, family shape moved) and the owner confirms it is
  intended (else it is drift to record, not a new standard).
A normal feature — even one adding two files — never edits a line. The agent may *propose*
a line edit in its report; it does not silently apply it.

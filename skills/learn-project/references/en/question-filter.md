# Question filter — what to ask the owner, and how

The owner's time is the scarcest resource in the loop. In the reference run, 30 raw questions
became 22 after dedupe, and only about a quarter of those actually changed where new code goes.
Two were bounced as "didn't understand", one as "look at the code". Hence these rules.

## Ask only if ALL of these hold
1. **Two readings are both plausible** from the code — you genuinely cannot tell.
2. **The answer changes where new code goes or how it is written** (which hub, which shape,
   which API, whether a pattern may be imitated). Cosmetic or performance debts do not qualify —
   record them under "known debt" in the line file instead.
3. **The code cannot answer it.** "Which of these two lists is authoritative?" is answered by
   grepping who consumes which. Owners will (rightly) bounce these.

## How to phrase
- **Name the members and files** ("the 4 missing from `editLogic.ts` are `a, b, c, d`"), never
  "some members".
- **One item, one question.** Do not bundle "is each X a component?" with "is the loop intended?".
- **Two readings, each in one sentence**, both stated as if true, so the owner can pick.
- **Allow non-binary answers**: A / B / **both** / by design / legacy / don't know / free text.
  Free text is the best answer ("currently full bundle; remote loading comes later") — leave room.
- ≤ 5 per line before merge; dedupe across lines (the same fact seen from three lines is one
  question with three sources).
- Group in the merged list: A mechanism · B boundaries · C declarations/labels · D legacy
  candidates (keep/remove/don't know) · E docs-vs-code (no decision, just fix).

## Bad questions (from the reference run) and why
- "Is the `rootId` hard-coded on purpose?" — real defect, but does not change where new code
  goes → record as known debt, do not ask.
- "Which of the two hard-coded lists is authoritative?" — grep the consumers; they were two
  different lists for two purposes.
- "Are hooks-in-map intended, or should each logic be its own component?" — two questions in one,
  members unnamed; owner answered "didn't get it".

## Answer vocabulary and its consequence
| Answer | Consequence in the line file |
|---|---|
| A / B / both | the chosen reading becomes the statement; the other is deleted or marked wrong |
| by design | promote to "confirmed design"; new code follows it |
| legacy | mark "do not imitate"; do **not** schedule deletion unless the owner says remove |
| don't know | keep as open; note "not the owner's decision / another author"; follow the majority |
| free text | quote it verbatim under Verdicts; usually yields both current state and direction |

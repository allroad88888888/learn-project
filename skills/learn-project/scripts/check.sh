#!/usr/bin/env bash
# check.sh REPO LINES_DIR
# Drift detection: re-run the extractors at HEAD and diff against the baseline saved by extract-all.sh
# under LINES_DIR/mechanical/. Also lists family members born since the baseline commit (verify their shape).
# churn-*.txt changes with every commit and is not compared. Exit 1 when anything drifted.
. "$(dirname "$0")/lib.sh"
REPO="${1:?usage: check.sh REPO LINES_DIR}"; L="${2:?lines dir}"; B="$L/mechanical"
[ -f "$B/commit.txt" ] || die "no baseline at $B (run extract-all.sh first)"
S="$(cd "$(dirname "$0")" && pwd)"; T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
OLD=$(awk '/^commit/{print $2}' "$B/commit.txt")
bash "$S/extract-all.sh" "$REPO" "$T" >/dev/null
rc=0
echo "== drift check: baseline $OLD → HEAD $(head_sha "$REPO")"
for f in $(ls "$B" | grep -v '^churn-\|^commit.txt'); do
  if [ ! -f "$T/mechanical/$f" ]; then echo "-- $f: GONE at HEAD"; rc=1; continue; fi
  d=$(diff "$B/$f" "$T/mechanical/$f" | grep '^[<>]' | head -20)
  [ -n "$d" ] && { echo "-- $f: CHANGED"; echo "$d" | sed 's/^/   /'; rc=1; }
done
for f in $(ls "$T/mechanical" | grep -v '^churn-\|^commit.txt'); do [ -f "$B/$f" ] || { echo "-- $f: NEW at HEAD"; rc=1; }; done
echo "-- members born since $OLD:"
FAMS=$(awk '/^== family: /{sub(/\/$/,"",$3); print $3}' "$B/families.txt")
for fam in $FAMS; do
  git -c core.quotepath=off -C "$REPO" log --diff-filter=A --name-only --format= "$OLD..HEAD" -- "$fam" 2>/dev/null \
    | awk -v f="$fam/" 'index($0,f)==1{ r=substr($0,length(f)+1); i=index(r,"/"); if(i>0) print f substr(r,1,i-1) }' | sort -u \
    | while read -r m; do echo "   $m   (new — verify it follows the line's shape and recipe)"; done
done
[ $rc -eq 0 ] && echo "no drift in families / hubs / imports / timeline / recipe" || echo "DRIFT: re-read the affected line file(s); re-learn only those lines"
exit $rc

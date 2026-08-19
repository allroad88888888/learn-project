#!/usr/bin/env bash
# recipe.sh REPO FAMILY_DIR [--n N] [--max-files M]
# "How to add one": take the N cleanest member-birth commits (fewest files touched, <= M files),
# list files they touched OUTSIDE the member dir, and intersect. Files in all N = the recipe;
# files in >= 2 = probably part of it. Squash monsters (> M files) are skipped as noise.
. "$(dirname "$0")/lib.sh"
REPO="${1:?usage: recipe.sh REPO FAMILY_DIR [--n N] [--max-files M]}"; FAM="${2%/}"; shift 2
N=3; MAXF=60
while [ $# -gt 0 ]; do case "$1" in --n) N="$2"; shift 2;; --max-files) MAXF="$2"; shift 2;; *) shift;; esac; done
MEMBERS=$(members "$REPO" "$FAM")
CAND=$(for m in $MEMBERS; do c=$(birth_commit "$REPO" "$m"); [ -z "$c" ] && continue
         t=$(git -c core.quotepath=off -C "$REPO" show --stat --format= "$c" | grep -c '|'); echo "$t $c $m"; done \
       | awk -v M="$MAXF" '$1<=M' | sort -n | head "-$N")
[ -z "$CAND" ] && { echo "no clean birth commits (all > $MAXF files) — lower --max-files or inspect by hand"; exit 0; }
echo "== recipe for $FAM/ (from $(echo "$CAND" | wc -l | tr -d ' ') cleanest birth commits)"
TMP=$(mktemp); trap 'rm -f "$TMP"' EXIT
echo "$CAND" | while read -r t c m; do
  echo "-- $c ($t files) $m: $(git -c core.quotepath=off -C "$REPO" log -1 --format='%ad %s' --date=short "$c" | cut -c1-90)"
  git -c core.quotepath=off -C "$REPO" show --name-only --format= "$c" | grep -v "^$m/" | grep -Ev "$NOISE_RE|\.lock$|lock\.yaml$" \
    | tee -a "$TMP" | sed 's/^/     /'
done
k=$(echo "$CAND" | wc -l | tr -d ' ')
echo "-- in ALL $k commits (the recipe):"; sort "$TMP" | uniq -c | awk -v k="$k" '$1==k{print "     "$2}'
echo "-- in >=2 commits (probably part of it):"; sort "$TMP" | uniq -c | awk -v k="$k" '$1>=2&&$1<k{print "     "$2}'

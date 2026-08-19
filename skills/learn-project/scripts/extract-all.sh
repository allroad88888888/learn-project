#!/usr/bin/env bash
# extract-all.sh REPO OUT_DIR [--min N]
# Run every extractor and save the mechanical evidence under OUT_DIR/mechanical/ (+ SUMMARY.md).
# Zero tokens: this is what the model reads before deciding which lines to trace.
# The same directory is the baseline for check.sh (drift detection) — commit it with the lines.
. "$(dirname "$0")/lib.sh"
REPO="${1:?usage: extract-all.sh REPO OUT_DIR [--min N]}"; OUT="${2:?out dir}"; MIN=5
[ "${3:-}" = "--min" ] && MIN="${4:-5}"
S="$(cd "$(dirname "$0")" && pwd)"; M="$OUT/mechanical"; mkdir -p "$M"
key() { echo "$1" | tr '/' '_'; }
{ echo "commit $(head_sha "$REPO")"; echo "date $(git -c core.quotepath=off -C "$REPO" log -1 --format=%cd --date=short)"; echo "tracked-files $(repo_files "$REPO" | wc -l | tr -d ' ')"; } > "$M/commit.txt"
echo "[1/5] families";  bash "$S/families.sh" "$REPO" --min "$MIN" > "$M/families.txt"
FAMS=$(awk '/^== family: /{sub(/\/$/,"",$3); print $3}' "$M/families.txt")
echo "[2/5] hubs / timeline / recipe per family: $(echo $FAMS | tr '\n' ' ')"
for f in $FAMS; do k=$(key "$f")
  bash "$S/hubs.sh"     "$REPO" "$f" > "$M/hubs-$k.txt"
  bash "$S/timeline.sh" "$REPO" "$f" > "$M/timeline-$k.txt"
  bash "$S/recipe.sh"   "$REPO" "$f" > "$M/recipe-$k.txt"
done
echo "[3/5] import direction"; bash "$S/imports.sh" "$REPO" > "$M/imports.txt"
echo "[4/5] churn of non-family top-level dirs (spine candidates)"
TOPS=$(repo_files "$REPO" | awk -F/ 'NF>1{print $1}' | sort -u)
for d in $TOPS; do echo "$FAMS" | grep -qx "$d" && continue; case "$d" in .*|docs|doc|scripts|examples?|test|tests) continue;; esac
  bash "$S/churn.sh" "$REPO" "$d" > "$M/churn-$(key "$d").txt"; done
echo "[5/5] summary"
{ echo "# Mechanical evidence — $(head -1 "$M/commit.txt")"; echo
  echo "## Families (candidate branch lines)"; echo '```'
  awk '/^== family: /{f=$3; n=$5} /^-- core files/{print f"  members="n"  core:"substr($0,index($0,":")+1)}' "$M/families.txt"; echo '```'
  echo "## Top hub per family (candidate join points)"; echo '```'
  for f in $FAMS; do n=$(awk '/^== family: /&&$3==f"/"{print $5}' f="$f" "$M/families.txt"); top=$(sed -n '2p' "$M/hubs-$(key "$f").txt" | sed 's/^ *//')
    printf '%-24s %s / %s members  (coverage < 60%% → probably a common layer, not a line)\n' "$f" "$top" "$n" | awk -v n="$n" '{ split($0,a," "); if (a[2]+0 >= 0.6*n) sub(/  \(coverage.*\)/,""); print }'; done; echo '```'
  echo "## Import direction"; echo '```'; sed -n '2,40p' "$M/imports.txt"; echo '```'
  echo "## Files"; ls "$M" | sed 's/^/- mechanical\//'
} > "$OUT/SUMMARY.md"
echo "done → $OUT/SUMMARY.md"

#!/usr/bin/env bash
# families.sh REPO [--min N] [--depth D] [DIR ...]
# Find "families": directories whose children are many sibling members of the same shape.
# For each family print: member count, top shapes, core files (present in >=60% of members),
# and outliers (members missing a core file). Tracked files only.
# With DIR args, only those directories are analysed; otherwise candidates are auto-detected
# (any dir at depth<=D whose immediate children include >= N member dirs).
. "$(dirname "$0")/lib.sh"
REPO="${1:?usage: families.sh REPO [--min N] [--depth D] [DIR ...]}"; shift
MIN=5; DEPTH=2; DIRS=()
while [ $# -gt 0 ]; do case "$1" in
  --min) MIN="$2"; shift 2;; --depth) DEPTH="$2"; shift 2;; *) DIRS+=("${1%/}"); shift;; esac; done

FILES=$(repo_files "$REPO")
if [ ${#DIRS[@]} -eq 0 ]; then
  # candidate = parent dir with >= MIN child dirs (depth-limited)
  DIRS=($(echo "$FILES" | awk -v D="$DEPTH" -F/ '{
      for(d=1; d<=D && d<NF-1; d++){ p=$1; for(i=2;i<=d;i++) p=p"/"$i; c=$(d+1); print p"\t"c } }' \
      | sort -u | awk -F'\t' '{n[$1]++} END{for(p in n) if(n[p]>=ENVIRON["MINV"]) print p}' MINV="$MIN" | sort))
fi
[ ${#DIRS[@]} -eq 0 ] && { echo "no family candidates (min members $MIN)"; exit 0; }

for fam in "${DIRS[@]}"; do
  MEMBERS=$(members "$REPO" "$fam"); n=$(echo "$MEMBERS" | grep -c . || true)
  [ "$n" -lt "$MIN" ] && continue
  echo "== family: $fam/  members: $n"
  # fingerprint: tracked files of each member, relative, depth<=2 (e.g. src/use.tsx, package.json)
  FP=$(for m in $MEMBERS; do
        echo "$FILES" | awk -v m="$m/" 'index($0,m)==1{ r=substr($0,length(m)+1); n=split(r,a,"/"); if(n<=2) print r }' \
          | sort -u | tr '\n' ' ' | sed "s|^|$m\t|"; echo; done | grep .)
  echo "-- top shapes (count · files):"
  echo "$FP" | cut -f2 | sort | uniq -c | sort -rn | head -5 | sed 's/^/   /'
  # core files: present in >=60% of members
  CORE=$(echo "$FP" | cut -f2 | tr ' ' '\n' | grep . | sort | uniq -c | awk -v n="$n" '$1>=0.6*n{print $2}')
  echo "-- core files (>=60% of members): $(echo $CORE | tr '\n' ' ')"
  echo "-- outliers (missing a core file):"
  echo "$FP" | while IFS=$'\t' read -r m files; do
     miss=""; for c in $CORE; do echo " $files " | grep -q " $c " || miss="$miss $c"; done
     [ -n "$miss" ] && echo "   $m  missing:$miss"; done | head -40
  echo
done

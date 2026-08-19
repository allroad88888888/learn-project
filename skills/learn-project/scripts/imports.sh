#!/usr/bin/env bash
# imports.sh REPO [--dirs a,b,c] [--mode import|mention]
# Direction matrix between top-level directories: for row dir A and column dir B, count files in A
# (tests/docs excluded) that import something of B. B is identified by its package ids (own id + member ids).
#   --mode import  (default) only import-like lines (import/from/use/require/include/extern crate/export…from,
#                  and bare quoted lines inside Go import blocks)
#   --mode mention any mention of the id (also catches string references such as schema names — noisier)
# Language-agnostic by construction; Rust ids also match with '-' -> '_'. bash 3.2 compatible.
. "$(dirname "$0")/lib.sh"
REPO="${1:?usage: imports.sh REPO [--dirs a,b,c] [--mode import|mention]}"; shift
DIRS=""; MODE=import
while [ $# -gt 0 ]; do case "$1" in --dirs) DIRS="$2"; shift 2;; --mode) MODE="$2"; shift 2;; *) shift;; esac; done
FILES=$(repo_files "$REPO")
[ -z "$DIRS" ] && DIRS=$(echo "$FILES" | awk -F/ 'NF>1{print $1}' | sort -u | tr '\n' ',')
DA=$(echo "${DIRS%,}" | tr ',' '\n' | sed 's|/$||' | grep .)
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
key() { echo "$1" | tr '/' '_'; }
for d in $DA; do
  { for m in "$d" $(members "$REPO" "$d"); do
      i=$(member_pkg_id "$REPO" "$m") || continue; echo "$i"
      # renamed packages (Cargo `x = { package = "y" }`, npm aliases): the directory name is often the import name
      b=$(basename "$m"); [ "$b" != "${i##*/}" ] && [ ${#b} -ge 4 ] && echo "$b"
    done
  } | awk 'length($0)>=4{print; u=$0; gsub(/-/,"_",u); if(u!=$0) print u}' | sort -u > "$W/$(key "$d").ids"
done
: > "$W/matrix"
for b in $DA; do
  idf="$W/$(key "$b").ids"; [ -s "$idf" ] || continue
  ARGS=(); while IFS= read -r id; do ARGS+=(-e "$id"); done < "$idf"
  git -c core.quotepath=off -C "$REPO" grep -n -F "${ARGS[@]}" -- . 2>/dev/null \
    | awk -F: -v idf="$idf" -v mode="$MODE" -v noise="$NOISE_RE|$TEST_RE|$HUB_SKIP_RE" '
      BEGIN{ while((getline l < idf)>0) ids[++n]=l }
      { f=$1; if(f ~ noise) next
        c=substr($0, length($1)+length($2)+3)
        if(mode=="import" && c !~ /^[[:space:]]*\}?[[:space:]]*(import|from|use |pub use|require|include|#include|extern crate|export .* from|const .*= *require|"[^"]+"$)/ && c !~ /require\(/) next
        for(i=1;i<=n;i++){ p=index(c,ids[i]); if(!p) continue
          b4=(p>1)?substr(c,p-1,1):" "; af=substr(c,p+length(ids[i]),1)
          if(b4 !~ /[A-Za-z0-9_-]/ && af !~ /[A-Za-z0-9_-]/){ print f; break } } }' \
    | sort -u | while read -r f; do for a in $DA; do case "$f" in "$a"/*) [ "$a" != "$b" ] && echo "$a"; break;; esac; done; done \
    | sort | uniq -c | awk -v b="$b" '{print $2"\t"b"\t"$1}' >> "$W/matrix"
done
echo "== import direction, mode=$MODE (files in ROW that import from COLUMN; tests/docs excluded)"
for a in $DA; do
  cells=$(awk -F'\t' -v a="$a" '$1==a{printf "  %s(%s)", $2, $3}' "$W/matrix")
  [ -n "$cells" ] && echo "   $a →$cells"
done
echo "-- identifiers per column: $(for d in $DA; do f="$W/$(key "$d").ids"; [ -s "$f" ] && printf '%s:%s ' "$d" "$(grep -c . "$f")"; done)"

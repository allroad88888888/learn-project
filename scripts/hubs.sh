#!/usr/bin/env bash
# hubs.sh REPO FAMILY_DIR [--top N]
# Find the "hub" (join point) of a family: files outside the family that reference the most members.
# A member is referenced when its identifier (package name, else dir name) appears in a file with
# identifier boundaries on both sides. Docs, lockfiles and tsconfig are not hubs (see lib.sh HUB_SKIP_RE).
# For the top 3 hubs also list which members they do NOT reference (the difference set).
. "$(dirname "$0")/lib.sh"
REPO="${1:?usage: hubs.sh REPO FAMILY_DIR [--top N]}"; FAM="${2:?family dir}"; FAM="${FAM%/}"; TOP=5
[ "${3:-}" = "--top" ] && TOP="${4:-5}"
MEMBERS=$(members "$REPO" "$FAM"); n=$(echo "$MEMBERS" | grep -c .)
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
for m in $MEMBERS; do id=$(member_id "$REPO" "$m"); [ ${#id} -ge 4 ] && printf '%s\t%s\n' "$id" "$m"; done > "$W/ids"   # id<TAB>member (ids < 4 chars skipped)
ARGS=(); while IFS=$'\t' read -r id m; do ARGS+=(-e "$id"); done < "$W/ids"
git -c core.quotepath=off -C "$REPO" grep -n -F "${ARGS[@]}" -- ":(exclude)$FAM/*" 2>/dev/null \
  | awk -F: -v idf="$W/ids" -v skip="$NOISE_RE|$HUB_SKIP_RE" '
    BEGIN{ while((getline l < idf)>0){ split(l,a,"\t"); ids[++n]=a[1]; mem[n]=a[2] } }
    { f=$1; if(f ~ skip) next; c=substr($0, length($1)+length($2)+3)
      for(i=1;i<=n;i++){ p=index(c,ids[i]); if(!p) continue
        b4=(p>1)?substr(c,p-1,1):" "; af=substr(c,p+length(ids[i]),1)
        if(b4 !~ /[A-Za-z0-9_-]/ && af !~ /[A-Za-z0-9_-]/) print f"\t"mem[i] } }' | sort -u > "$W/refs"   # file<TAB>member
echo "== hubs for $FAM/ ($n members; count = distinct members referenced)"
cut -f1 "$W/refs" | sort | uniq -c | sort -rn | head "-$TOP" | sed 's/^/   /'
echo "-- members NOT referenced by top hubs:"
cut -f1 "$W/refs" | sort | uniq -c | sort -rn | head -3 | awk '{print $2}' | while read -r hub; do
  have=$(awk -F'\t' -v h="$hub" '$1==h{print $2}' "$W/refs" | sort -u)
  miss=$(comm -23 <(echo "$MEMBERS") <(echo "$have") | tr '\n' ' ')
  echo "   $hub  lacks: ${miss:-<none>}"
done

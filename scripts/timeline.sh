#!/usr/bin/env bash
# timeline.sh REPO FAMILY_DIR
# First-appearance date of every member (earliest commit adding files under it), sorted.
# Earliest members ~ founding design; latest ~ recent practice. Prints all, flags first 3 / last 3.
. "$(dirname "$0")/lib.sh"
REPO="${1:?usage: timeline.sh REPO FAMILY_DIR}"; FAM="${2%/}"
MEMBERS=$(members "$REPO" "$FAM"); n=$(echo "$MEMBERS" | grep -c .)
echo "== timeline for $FAM/ ($n members; date member birth-commit)"
for m in $MEMBERS; do printf '%s %s %s\n' "$(birth_date "$REPO" "$m")" "$m" "$(birth_commit "$REPO" "$m")"; done \
  | sort | awk -v n="$n" '{ tag=""; if(NR<=3) tag="  <- founding"; if(NR>n-3) tag="  <- latest"; print "   "$0 tag }'

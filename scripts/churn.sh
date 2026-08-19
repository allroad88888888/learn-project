#!/usr/bin/env bash
# churn.sh REPO DIR [--top N]
# Commit counts per tracked file under DIR (tests excluded). High churn = edges; near-zero after
# creation = stable spine. Prints top N and bottom N.
. "$(dirname "$0")/lib.sh"
REPO="${1:?usage: churn.sh REPO DIR [--top N]}"; DIR="${2%/}"; TOP=8
[ "${3:-}" = "--top" ] && TOP="${4:-8}"
TRACKED=$(repo_files "$REPO" | grep "^$DIR/" | grep -Ev "$TEST_RE")
echo "== churn for $DIR/ ($(echo "$TRACKED" | grep -c .) files; commits per file)"
C=$(git -c core.quotepath=off -C "$REPO" log --format= --name-only -- "$DIR" | grep -Ev "$TEST_RE" | grep -Fx -f <(echo "$TRACKED") | sort | uniq -c | sort -rn)
echo "-- most changed:"; echo "$C" | head "-$TOP" | sed 's/^/   /'
echo "-- least changed:"; echo "$C" | tail "-$TOP" | sed 's/^/   /'

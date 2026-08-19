#!/usr/bin/env bash
# Shared helpers for learn-project extractors. Source me; do not run.
# All extractors work on `git ls-files` (tracked files only) — never on `ls`.

set -u
export LC_ALL=C   # byte-mode awk/sort: deterministic and immune to non-UTF8 file content

NOISE_RE='(^|/)(node_modules|target|dist|build|out|esm|cjs|lib|@types|\.next|\.turbo|coverage|__pycache__|vendor|\.git)(/|$)|\.(lock|min\.js|map|snap|png|jpg|jpeg|gif|svg|ico|woff2?|ttf)$'
HUB_SKIP_RE='\.(md|mdx|txt|lock)$|lock\.(yaml|json)$|tsconfig[^/]*\.json$'   # docs and lockfiles are not hubs
TEST_RE='(^|/)(__tests__|tests?|spec|it)(/|$)|\.(test|spec)\.[a-z]+$|_test\.(go|rs|py)$'

die() { echo "error: $*" >&2; exit 2; }
need() { command -v "$1" >/dev/null 2>&1 || die "missing tool: $1"; }
need git; need awk; need sort; need grep

# repo_files REPO  -> tracked files, noise removed
repo_files() { git -c core.quotepath=off -C "$1" ls-files | grep -Ev "$NOISE_RE"; }

# member_id REPO MEMBER_DIR -> package identifier used in imports/refs
#   package.json name > Cargo.toml [package] name > pyproject name > go.mod module > dir name
member_id() {
  local repo="$1" m="$2" f id=""
  f="$repo/$m/package.json"
  if [ -f "$f" ]; then
    id=$(grep -m1 -E '"name"[[:space:]]*:' "$f" | sed -E 's/.*"name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
  fi
  if [ -z "$id" ] && [ -f "$repo/$m/Cargo.toml" ]; then
    id=$(awk '/^\[package\]/{p=1;next} /^\[/{p=0} p&&/^name[[:space:]]*=/{gsub(/.*=[[:space:]]*"|".*/,"");print;exit}' "$repo/$m/Cargo.toml")
  fi
  if [ -z "$id" ] && [ -f "$repo/$m/pyproject.toml" ]; then
    id=$(awk '/^\[project\]|^\[tool\.poetry\]/{p=1;next} /^\[/{p=0} p&&/^name[[:space:]]*=/{gsub(/.*=[[:space:]]*"|".*/,"");print;exit}' "$repo/$m/pyproject.toml")
  fi
  if [ -z "$id" ] && [ -f "$repo/$m/go.mod" ]; then
    id=$(awk '/^module /{print $2;exit}' "$repo/$m/go.mod")
  fi
  [ -n "$id" ] && { echo "$id"; return 0; }
  basename "$m"; return 1          # fallback: dir name (exit 1 tells callers it is not a declared package id)
}
# member_pkg_id REPO MEMBER_DIR -> declared package id only; empty when the member has no manifest
member_pkg_id() { local id; id=$(member_id "$1" "$2") && echo "$id"; }

# members REPO FAMILY_DIR -> immediate child dirs that contain tracked files
members() {
  local repo="$1" fam="${2%/}"
  repo_files "$repo" | awk -v f="$fam/" 'index($0,f)==1 { rest=substr($0,length(f)+1); i=index(rest,"/"); if(i>0) print f substr(rest,1,i-1) }' | sort -u
}

# birth_commit REPO PATH -> earliest commit that added files under PATH (hash)
birth_commit() { git -c core.quotepath=off -C "$1" log --diff-filter=A --format=%h --reverse -- "$2" | head -1; }
birth_date()   { git -c core.quotepath=off -C "$1" log --diff-filter=A --format=%ad --date=short --reverse -- "$2" | head -1; }

head_sha() { git -c core.quotepath=off -C "$1" rev-parse --short HEAD; }

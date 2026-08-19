#!/usr/bin/env bash
# learn-project installer — one skill source, many agents. bash 3.2+, idempotent.
#   curl -fsSL https://raw.githubusercontent.com/allroad88888888/learn-project/main/install.sh | bash -s -- --claude --codex
#   ./install.sh --claude                      user-level Claude Code   (~/.claude/skills/learn-project)
#   ./install.sh --claude-project <repo>       project-level Claude Code (<repo>/.claude/skills/learn-project)
#   ./install.sh --codex                       Codex                    ($CODEX_HOME/skills, default ~/.codex/skills)
#   ./install.sh --cursor <repo>               Cursor rule pointing at the skill (<repo>/.cursor/rules/learn-project.mdc)
#   ./install.sh --agents-md <repo|file>       append a pointer block to AGENTS.md (or GEMINI.md / any file you name)
#   ./install.sh --dir <path>                  any agent that loads <path>/<name>/SKILL.md (e.g. a runtime's ./skills)
#   ./install.sh --all                         = --claude --codex
#   options: --copy (copy instead of symlink) --ref <git ref> (default main) --uninstall --help
set -u
NAME=learn-project
REPO_URL="https://github.com/allroad88888888/$NAME"
HOME_DIR="${LEARN_PROJECT_HOME:-$HOME/.$NAME}"
REF=main; MODE=link; UNINSTALL=0
TARGETS=()   # "kind<TAB>arg"
say()  { printf '%s\n' "$*"; }
die()  { printf 'error: %s\n' "$*" >&2; exit 2; }
need() { command -v "$1" >/dev/null 2>&1 || die "missing: $1"; }

while [ $# -gt 0 ]; do case "$1" in
  --claude)          TARGETS+=("claude	"); shift;;
  --claude-project)  TARGETS+=("claude-project	${2:?repo}"); shift 2;;
  --codex)           TARGETS+=("codex	"); shift;;
  --cursor)          TARGETS+=("cursor	${2:?repo}"); shift 2;;
  --agents-md)       TARGETS+=("agents-md	${2:?repo or file}"); shift 2;;
  --dir)             TARGETS+=("dir	${2:?path}"); shift 2;;
  --all)             TARGETS+=("claude	" "codex	"); shift;;
  --copy)            MODE=copy; shift;;
  --ref)             REF="${2:?ref}"; shift 2;;
  --uninstall)       UNINSTALL=1; shift;;
  -h|--help)         sed -n '2,13p' "$0"; exit 0;;
  *) die "unknown option $1 (see --help)";;
esac; done
[ ${#TARGETS[@]} -eq 0 ] && { sed -n '2,13p' "$0"; exit 1; }

# ---- locate the skill source: a local checkout (this script inside it) or ~/.learn-project (cloned/updated) ----
resolve_src() {
  local here; here="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)" || here=""
  if [ -n "$here" ] && [ -f "$here/skills/$NAME/SKILL.md" ]; then SRC="$here"; return; fi
  need git
  if [ -d "$HOME_DIR/.git" ]; then
    git -C "$HOME_DIR" fetch -q origin && git -C "$HOME_DIR" checkout -q "$REF" 2>/dev/null && git -C "$HOME_DIR" pull -q --ff-only origin "$REF" 2>/dev/null || true
  else
    git clone -q --depth 1 --branch "$REF" "$REPO_URL" "$HOME_DIR" || die "clone failed: $REPO_URL@$REF"
  fi
  SRC="$HOME_DIR"
}
SKILL_SRC=""   # set after resolve

owned() { # owned DEST -> 0 if DEST is our skill dir (symlink to it, or a copy carrying our SKILL.md name)
  [ -L "$1" ] && return 0
  [ -f "$1/SKILL.md" ] && grep -q "^name: $NAME\$" "$1/SKILL.md"
}
install_skill_dir() { # install_skill_dir PARENT  -> PARENT/learn-project
  local parent="$1" dest="$1/$NAME"
  mkdir -p "$parent"
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    owned "$dest" || die "$dest exists and is not learn-project; remove it yourself first"
    rm -rf "$dest"
  fi
  if [ "$MODE" = link ]; then ln -s "$SKILL_SRC" "$dest"; else cp -R "$SKILL_SRC" "$dest"; fi
  [ -f "$dest/SKILL.md" ] && [ -x "$dest/scripts/extract-all.sh" ] || die "verify failed at $dest"
  say "  ✓ $dest  ($MODE)"
}
remove_skill_dir() { local dest="$1/$NAME"; { [ -e "$dest" ] || [ -L "$dest" ]; } && owned "$dest" && rm -rf "$dest" && say "  ✗ removed $dest"; return 0; }

pointer_block() { # pointer_block SKILL_PATH -> text that any instruction file can carry
cat <<TXT
<!-- $NAME:begin -->
## learn-project (agent skill)
When asked to learn / understand this repository, decide where a change belongs, check that a change
still follows the project's design, or detect drift, read and follow \`$1/SKILL.md\`
(Chinese: \`$1/SKILL.zh-CN.md\`). Its extractors are in \`$1/scripts/\`.
<!-- $NAME:end -->
TXT
}
strip_block() { # strip_block FILE
  [ -f "$1" ] || return 0
  awk -v b="<!-- $NAME:begin -->" -v e="<!-- $NAME:end -->" '$0==b{skip=1} !skip{print} $0==e{skip=0}' "$1" > "$1.tmp" && mv "$1.tmp" "$1"
}
skill_path_for() { # skill_path_for REPO -> project-relative path if the skill is installed in that repo, else the absolute source
  if [ -n "$1" ] && [ -f "$1/.claude/skills/$NAME/SKILL.md" ]; then echo ".claude/skills/$NAME"; else echo "$SKILL_SRC"; fi
}
install_agents_md() { # install_agents_md REPO_OR_FILE
  local f="$1" repo=""; [ -d "$f" ] && { repo="$f"; f="$f/AGENTS.md"; }
  strip_block "$f"; { [ -f "$f" ] && [ -s "$f" ] && printf '\n'; pointer_block "$(skill_path_for "$repo")"; } >> "$f"
  say "  ✓ pointer block in $f"
}
install_cursor() { # install_cursor REPO
  local d="$1/.cursor/rules"; mkdir -p "$d"
  { printf -- '---\ndescription: "learn-project: learn this repo (main line + branch lines), decide where a change belongs, check a change still follows the design, detect drift"\nalwaysApply: false\n---\n'
    pointer_block "$(skill_path_for "$1")"; } > "$d/$NAME.mdc"
  say "  ✓ $d/$NAME.mdc"
}

resolve_src; SKILL_SRC="$SRC/skills/$NAME"
say "learn-project source: $SKILL_SRC"
for t in "${TARGETS[@]}"; do
  kind="${t%%	*}"; arg="${t#*	}"
  case "$kind" in
    claude)         p="$HOME/.claude/skills";;
    claude-project) p="$arg/.claude/skills";;
    codex)          p="${CODEX_HOME:-$HOME/.codex}/skills";;
    dir)            p="$arg";;
    cursor|agents-md) p="";;
  esac
  if [ "$UNINSTALL" = 1 ]; then
    case "$kind" in
      cursor)    rm -f "$arg/.cursor/rules/$NAME.mdc" && say "  ✗ removed $arg/.cursor/rules/$NAME.mdc";;
      agents-md) f="$arg"; [ -d "$f" ] && f="$f/AGENTS.md"; strip_block "$f"; say "  ✗ pointer block removed from $f";;
      *)         remove_skill_dir "$p";;
    esac
  else
    case "$kind" in
      cursor)    install_cursor "$arg";;
      agents-md) install_agents_md "$arg";;
      *)         install_skill_dir "$p";;
    esac
  fi
done
[ "$UNINSTALL" = 1 ] || say "done — the skill is available in the next agent session (Claude Code: /learn-project · Codex: \"use the learn-project skill\")."

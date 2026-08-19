#!/usr/bin/env pwsh
# learn-project installer for native Windows PowerShell. Run with -Help (or no flags) for usage.
[CmdletBinding()]
param(
  [switch]$Claude,
  [string]$ClaudeProject,
  [switch]$Codex,
  [switch]$Dsh,
  [string]$DshProject,
  [switch]$AgentsHome,
  [string]$Cursor,
  [string]$AgentsMd,
  [string]$Dir,
  [switch]$All,
  [switch]$Copy,
  [string]$Ref = "main",
  [switch]$Uninstall,
  [switch]$Help
)

$ErrorActionPreference = "Stop"
$Name = "learn-project"
$RepoUrl = "https://github.com/allroad88888888/$Name"

function Say($msg) { Write-Host $msg }
function Die($msg) { Write-Error "error: $msg"; exit 2 }
function EnvOr($val, $fallback) { if ($val) { $val } else { $fallback } }   # PS 5.1 has no ?: operator

$HelpText = @"
learn-project installer — native Windows (PowerShell 5.1+ / pwsh), no Git Bash or WSL required
to place the files. Idempotent. Mirrors install.sh's targets and options.

  irm https://raw.githubusercontent.com/allroad88888888/learn-project/main/install.ps1 -OutFile install.ps1
  ./install.ps1 -Claude -Codex

  -Claude                    user-level Claude Code    (~/.claude/skills/learn-project)
  -ClaudeProject <repo>      project-level Claude Code (<repo>/.claude/skills/learn-project)
  -Codex                     Codex                     (`$env:CODEX_HOME/skills, default ~/.codex/skills)
  -Dsh                       DeepSeek Harness          (`$env:DSH_HOME/skills, default ~/.dsh/skills)
  -DshProject <repo>         DeepSeek Harness, project-level (<repo>/.dsh/skills)
  -AgentsHome                shared ~/.agents/skills   (`$env:DSH_AGENTS_HOME; read by dsh and other clients)
  -Cursor <repo>             Cursor rule pointing at the skill (<repo>/.cursor/rules/learn-project.mdc)
  -AgentsMd <repoOrFile>     append a pointer block to AGENTS.md (or GEMINI.md / any file you name)
  -Dir <path>                any agent that loads <path>/<name>/SKILL.md
  -All                       = -Claude -Codex -Dsh
  -Copy                      copy instead of symlink (symlinks need admin rights or Developer Mode)
  -Ref <gitRef>              pin a branch/tag (default main); requires git.exe
  -Uninstall                 remove instead of install (pass the same target flags)

NOTE: placing the skill needs no bash. RUNNING it — scripts/*.sh at learn/check time — still needs
bash (Git Bash, WSL, MSYS2). That is already true of most coding agents' shell tool on Windows, so
if your agent can run shell commands at all, bash is already there. If not, run install.sh itself
from Git Bash or WSL instead of this script — same source, same result.
"@

if ($Help -or (-not ($Claude -or $ClaudeProject -or $Codex -or $Dsh -or $DshProject -or $AgentsHome -or $Cursor -or $AgentsMd -or $Dir -or $All))) {
  Write-Host $HelpText
  if (-not $Help) { exit 1 }
  exit 0
}

# ---- locate the skill source: a local checkout (this script sits inside it) or %USERPROFILE%\.learn-project (cloned/updated) ----
function Resolve-Src {
  if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot "skills\$Name\SKILL.md"))) { return $PSScriptRoot }
  if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Die "git.exe is required to fetch $Name (install Git for Windows) — or run this from inside a local clone" }
  $homeDir = if ($env:LEARN_PROJECT_HOME) { $env:LEARN_PROJECT_HOME } else { Join-Path $HOME ".$Name" }
  if (Test-Path (Join-Path $homeDir ".git")) {
    git -C $homeDir fetch -q origin 2>$null
    git -C $homeDir checkout -q $Ref 2>$null
    git -C $homeDir pull -q --ff-only origin $Ref 2>$null
  } else {
    git clone -q --depth 1 --branch $Ref $RepoUrl $homeDir
    if ($LASTEXITCODE -ne 0) { Die "clone failed: $RepoUrl@$Ref" }
  }
  return $homeDir
}

function Test-Owned($dest) {
  $item = Get-Item -LiteralPath $dest -Force -ErrorAction SilentlyContinue
  if (-not $item) { return $false }
  if ($item.LinkType) { return $true }   # symlink/junction we (or a prior run) made
  $skillMd = Join-Path $dest "SKILL.md"
  if (Test-Path $skillMd) { return (Select-String -Path $skillMd -Pattern "^name: $Name$" -Quiet) }
  return $false
}

function Install-SkillDir($parent) {
  $dest = Join-Path $parent $Name
  New-Item -ItemType Directory -Force -Path $parent | Out-Null
  if (Test-Path -LiteralPath $dest) {
    if (-not (Test-Owned $dest)) { Die "$dest exists and is not learn-project; remove it yourself first" }
    Remove-Item -LiteralPath $dest -Recurse -Force
  }
  $mode = if ($Copy) { "copy" } else { "link" }
  if ($mode -eq "link") {
    try {
      New-Item -ItemType SymbolicLink -Path $dest -Target $SkillSrc -ErrorAction Stop | Out-Null
    } catch {
      Say "  (symlink failed — falling back to copy; run as Administrator or enable Developer Mode to get symlinks, so edits to the local clone update every agent automatically)"
      $mode = "copy"
    }
  }
  if ($mode -eq "copy") { Copy-Item -LiteralPath $SkillSrc -Destination $dest -Recurse -Force }
  if (-not (Test-Path (Join-Path $dest "SKILL.md"))) { Die "verify failed at $dest" }
  Say "  + $dest  ($mode)"
}

function Remove-SkillDir($parent) {
  $dest = Join-Path $parent $Name
  if ((Test-Path -LiteralPath $dest) -and (Test-Owned $dest)) {
    Remove-Item -LiteralPath $dest -Recurse -Force
    Say "  - removed $dest"
  }
}

function Get-PointerBlock($skillPath) {
  $skillPathFwd = $skillPath -replace '\\','/'
  @"
<!-- $Name`:begin -->
## learn-project (agent skill)
When asked to learn / understand this repository, decide where a change belongs, check that a change
still follows the project's design, or detect drift, read and follow ``$skillPathFwd/SKILL.md``
(Chinese: ``$skillPathFwd/SKILL.zh-CN.md``). Its extractors are in ``$skillPathFwd/scripts/`` (run via bash).
<!-- $Name`:end -->
"@
}

function Remove-PointerBlock($file) {
  if (-not (Test-Path -LiteralPath $file)) { return }
  $text = Get-Content -LiteralPath $file -Raw
  $stripped = [regex]::Replace($text, "(?s)<!-- $Name`:begin -->.*?<!-- $Name`:end -->\r?\n?", "")
  Set-Content -LiteralPath $file -Value $stripped -NoNewline
}

function Get-SkillPathFor($repo) {
  if ($repo -and (Test-Path (Join-Path $repo ".claude\skills\$Name\SKILL.md"))) { return ".claude/skills/$Name" }
  return ($SkillSrc -replace '\\','/')
}

function Install-AgentsMd($repoOrFile) {
  $f = $repoOrFile; $repo = $null
  if (Test-Path -LiteralPath $repoOrFile -PathType Container) { $repo = $repoOrFile; $f = Join-Path $repoOrFile "AGENTS.md" }
  Remove-PointerBlock $f
  $existing = if (Test-Path -LiteralPath $f) { Get-Content -LiteralPath $f -Raw } else { "" }
  $sep = if ($existing.Trim().Length -gt 0) { "`n" } else { "" }
  Set-Content -LiteralPath $f -Value ($existing + $sep + (Get-PointerBlock (Get-SkillPathFor $repo))) -NoNewline
  Say "  + pointer block in $f"
}

function Install-Cursor($repo) {
  $d = Join-Path $repo ".cursor\rules"
  New-Item -ItemType Directory -Force -Path $d | Out-Null
  $front = "---`ndescription: `"learn-project: learn this repo (main line + branch lines), decide where a change belongs, check a change still follows the design, detect drift`"`nalwaysApply: false`n---`n"
  Set-Content -LiteralPath (Join-Path $d "$Name.mdc") -Value ($front + (Get-PointerBlock (Get-SkillPathFor $repo))) -NoNewline
  Say "  + $d\$Name.mdc"
}

function Remove-Cursor($repo) {
  $f = Join-Path $repo ".cursor\rules\$Name.mdc"
  if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f -Force; Say "  - removed $f" }
}

$SRC = Resolve-Src
$SkillSrc = Join-Path $SRC "skills\$Name"
Say "learn-project source: $SkillSrc"

$targets = New-Object System.Collections.Generic.List[object]
if ($Claude -or $All)        { $targets.Add(@{Kind="claude"}) }
if ($ClaudeProject)          { $targets.Add(@{Kind="claude-project"; Arg=$ClaudeProject}) }
if ($Codex -or $All)         { $targets.Add(@{Kind="codex"}) }
if ($Dsh -or $All)           { $targets.Add(@{Kind="dsh"}) }
if ($DshProject)             { $targets.Add(@{Kind="dsh-project"; Arg=$DshProject}) }
if ($AgentsHome)             { $targets.Add(@{Kind="agents-home"}) }
if ($Cursor)                 { $targets.Add(@{Kind="cursor"; Arg=$Cursor}) }
if ($AgentsMd)                { $targets.Add(@{Kind="agents-md"; Arg=$AgentsMd}) }
if ($Dir)                    { $targets.Add(@{Kind="dir"; Arg=$Dir}) }

foreach ($t in $targets) {
  $kind = $t.Kind; $arg = $t.Arg
  $p = switch ($kind) {
    "claude"         { Join-Path $HOME ".claude\skills" }
    "claude-project" { Join-Path $arg ".claude\skills" }
    "codex"          { Join-Path (EnvOr $env:CODEX_HOME (Join-Path $HOME ".codex")) "skills" }
    "dsh"            { Join-Path (EnvOr $env:DSH_HOME (Join-Path $HOME ".dsh")) "skills" }
    "dsh-project"    { Join-Path $arg ".dsh\skills" }
    "agents-home"    { Join-Path (EnvOr $env:DSH_AGENTS_HOME (Join-Path $HOME ".agents")) "skills" }
    "dir"            { $arg }
    default          { $null }
  }
  if ($Uninstall) {
    switch ($kind) {
      "cursor"    { Remove-Cursor $arg }
      "agents-md" { $f = if (Test-Path -LiteralPath $arg -PathType Container) { Join-Path $arg "AGENTS.md" } else { $arg }; Remove-PointerBlock $f; Say "  - pointer block removed from $f" }
      default     { Remove-SkillDir $p }
    }
  } else {
    switch ($kind) {
      "cursor"    { Install-Cursor $arg }
      "agents-md" { Install-AgentsMd $arg }
      default     { Install-SkillDir $p }
    }
  }
}

if (-not $Uninstall) {
  Say 'done -- the skill is available in the next agent session (Claude Code: /learn-project . Codex / DeepSeek Harness: "use the learn-project skill").'
}

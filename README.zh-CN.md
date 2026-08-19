# learn-project

**学一次仓库。理解留在仓库里，不留在聊天里。**
[English](README.md)

`learn-project` 是一个 agent skill（纯 markdown + shell），把一个仓库变成一小组由负责人确认过的
**线文件**——项目的主线与分支线：数据怎么走、谁管什么、模仿哪个成员、怎么加一个、哪些代码是不该抄的
漂移。之后每个任务只读其中一两个文件，不再重扫仓库。关窗口、换模型、开新会话，理解都在——因为它住在
仓库里，像代码一样被 review。

任何能加载 skills 的 agent 都能用（Claude Code、Codex、你自己的 runtime）。它**不是**记忆插件、
聊天压缩、向量库，也不是一份大 `ARCHITECTURE.md`。

## 你得到什么

```
<repo>/.claude/skills/project-lines/     （或 .project-lines/）
├── SKILL.md         索引：线、汇合点、已确认规则、结构修正、成本——自动加载
├── lines/           一线一文件，≤300 行，每条论断引 file:line，数字是数出来的
├── questions.md     给负责人的 ≤ ~20 条问题，各两种解释；答案折回
└── mechanical/      确定性提取器输出——查漂移的基线
```

## 怎么工作

1. **提取（脚本，零 token，几秒）：** 家族形状、汇合点（引用最多成员的那个文件）、目录间 import 方向、
   首次出现时间轴、由成员出生提交交集得出的「加一个」、churn。只看跟踪文件。
2. **追线（一线一个子 agent，并行）：** 沿样板成员端到端追，引 `file:line`，数而不猜，把不合形状的
   分成 *另一类* / *漂移* / *其实合规*，写出文档与代码不一致处，提 ≤5 条问题。
3. **合并：** 交叉印证几条线独立发现的事实，跨线去重问题，过滤掉代码能答的和不改变新代码去向的。
4. **确认：** 负责人答 `A / B / 都有 / 就这样 / 遗留 / 不知道 / 自由文本`；裁决折回线文件，规则升格进索引。
5. **使用：** 任务读索引 + 1–2 条线，模仿样板成员、碰配方文件、不抄漂移，收尾检查 diff 仍在线上。
6. **查漂移：** 之后随时 `scripts/check.sh` 重跑提取器报漂移。

## 安装

一份源、多条通道。展开你用的那个——每个都是一条命令。

<details>
<summary><b>Claude Code</b>——skill（用户级 / 项目级）或 plugin</summary>

用户级（`~/.claude/skills/learn-project`）：

```bash
curl -fsSL https://raw.githubusercontent.com/allroad88888888/learn-project/main/install.sh | bash -s -- --claude
```

项目级（`<repo>/.claude/skills/learn-project`，随仓库走）：

```bash
curl -fsSL https://raw.githubusercontent.com/allroad88888888/learn-project/main/install.sh | bash -s -- --claude-project <repo>
```

作为 plugin（在 Claude Code 里）：

```
/plugin marketplace add allroad88888888/learn-project
/plugin install learn-project@learn-project
```
</details>

<details>
<summary><b>Codex</b>——原生 skill</summary>

```bash
curl -fsSL https://raw.githubusercontent.com/allroad88888888/learn-project/main/install.sh | bash -s -- --codex
```

落在 `$CODEX_HOME/skills/learn-project`（默认 `~/.codex/skills`）。或者直接对 Codex 说：
「从 allroad88888888/learn-project 装 skill，路径 skills/learn-project」——它自带的 `skill-installer` 会装。
</details>

<details>
<summary><b>DeepSeek Harness (dsh)</b>——原生 skill，不用插件</summary>

```bash
curl -fsSL https://raw.githubusercontent.com/allroad88888888/learn-project/main/install.sh | bash -s -- --dsh
```

落在 `$DSH_HOME/skills/learn-project`（默认 `~/.dsh/skills`）。另有：`--dsh-project <repo>` →
`<repo>/.dsh/skills`；`--agents-home` → 共享的 `~/.agents/skills`（`$DSH_AGENTS_HOME`，dsh 和其它客户端都读）。
</details>

<details>
<summary><b>Cursor</b>——一条指向 skill 的 rule</summary>

```bash
curl -fsSL https://raw.githubusercontent.com/allroad88888888/learn-project/main/install.sh | bash -s -- --cursor <repo>
```

写入 `<repo>/.cursor/rules/learn-project.mdc`（`alwaysApply: false`，按 description 触发），正文一句
「读并照做 `…/learn-project/SKILL.md`」。与 `--claude-project <repo>` 一起用时自动写项目相对路径。
</details>

<details>
<summary><b>Gemini CLI / GitHub Copilot / 任何读 <code>AGENTS.md</code> 的</b></summary>

```bash
curl -fsSL https://raw.githubusercontent.com/allroad88888888/learn-project/main/install.sh | bash -s -- --agents-md <repo>
```

往 `<repo>/AGENTS.md` 追加一段带标记的指针（也可指定文件：`--agents-md <repo>/GEMINI.md`、
`--agents-md <repo>/.github/copilot-instructions.md`）。`--uninstall` 只删那一段。
</details>

<details>
<summary><b>任何加载 <code>&lt;dir&gt;/&lt;name&gt;/SKILL.md</code> 的 runtime</b></summary>

```bash
curl -fsSL https://raw.githubusercontent.com/allroad88888888/learn-project/main/install.sh | bash -s -- --dir <path>
```

落在 `<path>/learn-project`。skill 遵循开放的 [Agent Skills](https://agentskills.io) 格式
（`SKILL.md` + `name`/`description`），那里列出的任何客户端都能直接加载 `skills/learn-project/`。
</details>

<details>
<summary><b>一次全装、选项、卸载</b></summary>

```bash
curl -fsSL https://raw.githubusercontent.com/allroad88888888/learn-project/main/install.sh | bash -s -- --all   # = --claude --codex --dsh
```

`install.sh` 幂等。选项：`--copy`（拷贝而不软链）、`--ref v0.1.0`（钉版本）、`--uninstall`（带同样的
目标参数）。在本地 clone 里跑 `./install.sh …` 会软链到这个 clone——改 clone 所有 agent 同步生效；
`curl` 方式会 clone 到 `~/.learn-project`（`LEARN_PROJECT_HOME` 可改）再软链。脚本只需要
`bash 3.2+`、`git`、`awk`、`grep`、`sort`。
</details>

<details>
<summary><b>Windows</b>——Git Bash/WSL，或原生 PowerShell</summary>

如果你的 agent 在 Windows 上本来就靠 Git Bash 或 WSL 跑 shell 工具（多数编程 agent 都是这样），
在里面跑上面任意一条命令即可，`install.sh` 原样能用。

没有 Git Bash 的话，用 PowerShell（5.1+ 或 `pwsh`）原生安装，装的过程不需要 bash——参数同名，只是
PascalCase：

```powershell
iwr -useb https://raw.githubusercontent.com/allroad88888888/learn-project/main/install.ps1 -OutFile install.ps1
powershell -ExecutionPolicy Bypass -File install.ps1 -Claude -Codex
```

软链需要管理员权限或开发者模式；两者都没有时 `install.ps1` 会自动回退成拷贝（`-Copy` 可强制总是拷贝）。
有一点无论哪种方式都一样：**装**这个 skill 不需要 bash，但**跑**它——学习/查漂移时的 `scripts/*.sh`——
仍然需要。这本来就是 Windows 上多数编程 agent 的 shell 工具的前提，你的 agent 能跑 shell 命令，
就已经有 bash 可用。
</details>

## 用法

在你的 agent 里、在要学的仓库上：
```
/learn-project            # 或：「学一下这个项目」
```
之后：
```
「加一个 X」/「Y 该放哪」/「这次改动还在设计上吗」
```
随时或在 CI 查漂移：
```bash
bash ~/.claude/skills/learn-project/scripts/check.sh <repo> <repo>/.claude/skills/project-lines
```
```yaml
# .github/workflows/lines-check.yml
- uses: actions/checkout@v4
  with: { fetch-depth: 0 }
- run: git clone --depth 1 https://github.com/allroad88888888/learn-project /tmp/lp
- run: bash /tmp/lp/skills/learn-project/scripts/check.sh . .claude/skills/project-lines
```
单独跑提取器：
```bash
bash skills/learn-project/scripts/extract-all.sh <repo> /tmp/out && cat /tmp/out/SUMMARY.md
```

## 参考跑

一个 150 包的 JS monorepo（5k 跟踪文件、1.3k 提交）：提取 23 秒；6 条线并行追踪约 10 分钟，打开
~445 个文件，~860k tokens；负责人约 30 分钟答了 23 条中的 21 条 → 1 条新规则、5 条「就这样」、3 条
确认的漂移、5 条「留」。四条线独立撞到同一个隐藏结构；提取器算出的配方找出手写清单漏掉的两个文件；
文档写的框架版本是错的。也在一个 Rust workspace 上测过（改名 crate 的 import 能对上）。

## 仓库布局

```
skills/learn-project/          skill 本体（Agent Skills 格式）
  SKILL.md / SKILL.zh-CN.md      流程（英 / 中）
  templates/{en,zh}/             index.md · line.md · questions.md · trace-prompt.md
  references/{en,zh}/            method.md · extractors.md · question-filter.md · verdicts.md
  scripts/                       extract-all · families · hubs · imports · timeline · recipe · churn · check · lib
.claude-plugin/                plugin.json + marketplace.json（Claude Code plugin 通道）
install.sh                     安装器（bash）：Claude Code / Codex / DeepSeek Harness / Cursor / AGENTS.md / 任意 skills 目录
install.ps1                    同一个安装器，原生 Windows PowerShell 版（装的过程不需要 Git Bash/WSL）
```

## 原则（短版）

只看跟踪文件 · 证据数出来不是感觉 · 每条论断引 `file:line` · 永远三分：标准/另一类/漂移 · 漂移是
「别模仿」不是「删」· 文档是线索要核 · 只问改变新代码去向的 · 设计由负责人定不由模型定 · 文件 ≤300 行 ·
成本花在学习那一次，任务只读 ≤2 个文件。

## 许可

MIT

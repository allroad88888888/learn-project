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

Claude Code（用户级）：
```bash
git clone https://github.com/allroad88888888/learn-project ~/.claude/skills/learn-project
```
项目级：clone 到 `<repo>/.claude/skills/learn-project`。其它 agent：指向 `SKILL.zh-CN.md`（中文）
或 `SKILL.md`（英文）；脚本只需要 `bash 3.2+`、`git`、`awk`、`grep`、`sort`。

## 用法

在你的 agent 里、在要学的仓库上：
```
/learn-project            # 或：「学一下这个项目」
```
之后：
```
「加一个 X」/「Y 该放哪」/「这次改动还在设计上吗」
```
随时（或在 CI）查漂移：
```bash
bash ~/.claude/skills/learn-project/scripts/check.sh <repo> <repo>/.claude/skills/project-lines
```
单独跑提取器：
```bash
bash scripts/extract-all.sh <repo> /tmp/out && cat /tmp/out/SUMMARY.md
```

## 参考跑

一个 150 包的 JS monorepo（5k 跟踪文件、1.3k 提交）：提取 23 秒；6 条线并行追踪约 10 分钟，打开
~445 个文件，~860k tokens；负责人约 30 分钟答了 23 条中的 21 条 → 1 条新规则、5 条「就这样」、3 条
确认的漂移、5 条「留」。四条线独立撞到同一个隐藏结构；提取器算出的配方找出手写清单漏掉的两个文件；
文档写的框架版本是错的。也在一个 Rust workspace 上测过（改名 crate 的 import 能对上）。

## 仓库布局

```
SKILL.md / SKILL.zh-CN.md      流程（英 / 中）
templates/{en,zh}/             index.md · line.md · questions.md · trace-prompt.md
references/{en,zh}/            method.md · extractors.md · question-filter.md · verdicts.md
scripts/                       extract-all · families · hubs · imports · timeline · recipe · churn · check · lib
```

## 原则（短版）

只看跟踪文件 · 证据数出来不是感觉 · 每条论断引 `file:line` · 永远三分：标准/另一类/漂移 · 漂移是
「别模仿」不是「删」· 文档是线索要核 · 只问改变新代码去向的 · 设计由负责人定不由模型定 · 文件 ≤300 行 ·
成本花在学习那一次，任务只读 ≤2 个文件。

## 许可

MIT

# 提取器——每个脚本算什么、局限、怎么扩

全部脚本：`bash 3.2+`、`git`、`awk`、`sort`、`grep`；`LC_ALL=C`；只看跟踪文件（`git ls-files`）；
排除噪声目录（`node_modules`、`target`、`dist`、`esm`、`@types` …）和二进制（`lib.sh: NOISE_RE`）；
标注处排除测试（`TEST_RE`）。语言无关是结构性的：它们作用于**文件形状、包标识符、git 历史**，不解析语法。

| 脚本 | 参数 | 输出 | 说明 |
|---|---|---|---|
| `extract-all.sh` | `REPO OUT [--min N]` | `OUT/mechanical/*.txt` + `OUT/SUMMARY.md` | 全跑一遍；`mechanical/` 是 `check.sh` 的基线 |
| `families.sh` | `REPO [--min N] [--depth D] [DIR…]` | 每族：成员、主要形状、核心文件（≥60%）、离群 | 指纹 = 成员内 ≤2 层的跟踪文件；自动发现 ≥N 个子目录的目录（默认 5） |
| `hubs.sh` | `REPO FAMILY [--top N]` | 家族之外按「引用的不同成员数」排名的文件；前 3 名的差集 | 标识符 = 包名（`package.json`/`Cargo.toml`/`pyproject`/`go.mod`）否则目录名（≥4 字符）；边界匹配；文档、锁文件、`tsconfig*` 永不算汇合点 |
| `imports.sh` | `REPO [--dirs a,b,…] [--mode import\|mention]` | 「行 import 列」矩阵 | `import` 模式只认 import 形状的行（`import/from/use/require/include/extern crate/export … from`，Go import 块里的裸引号行）；`mention` 计任何出现（能抓 schema 字符串引用；更吵）。Rust 标识符也匹配 `-`→`_`；改名依赖（`x = { package = "y" }`）也匹配目录名 |
| `timeline.sh` | `REPO FAMILY` | 每成员首次出现日期 + 出生提交，排序；标奠基/最新 | 最早 ≈ 原设计；最后三个 ≈ 当前做法 |
| `recipe.sh` | `REPO FAMILY [--n N] [--max-files M]` | 最干净的 N 次出生提交在成员目录外触碰的文件及其交集 | 触碰 >M 个文件（默认 60）的提交当 squash 噪声跳过；一个干净的都没有就明说 |
| `churn.sh` | `REPO DIR [--top N]` | 每文件提交数，最多/最少 | 排除测试；仅供参考，`check.sh` 不 diff |
| `check.sh` | `REPO LINES_DIR` | 家族/汇合点/import/时间轴/配方对基线的 diff；基线之后新出生的成员；有漂移退出 1 | 只重学受影响的线 |

## 怎么读输出
- **有覆盖率 ≥60% 汇合点的家族** → 分支线候选。覆盖率 <60% → 多半是公共层（工具类），不是线。
- **差集**（「汇合点缺：a b c d」）是「另一类」和「漂移」藏身的地方——明确交给追线的子 agent。
- **import 矩阵**：除入口外没人 import 的列是脊柱候选；只 import core + 公共层、从不 import app/loader
  的家族是规则候选；兄弟互引很少、每处都要分类（共享基类 = 合规；伸手进另一家族内部 = 漂移）。
- **配方**：交集就是「加一个」清单；与已有清单对照——参考跑里交集找出了手写清单漏掉的两个文件。
- **时间轴**：奠基成员是样板候选；最后三个形状与多数不同 = 迁移中——问负责人。

## 已知局限
- <4 字符的标识符忽略（太吵）；没有清单文件的仓库退回目录名，汇合点更吵。
- `imports.sh` 数文件不数 import 语句；import 不是按行写的语言需要 `mention` 模式（Go 的部分块已处理）。
- 家族发现基于目录；靠命名约定在同一目录内成族的（`*_handler.py`）发现不了——手工传 DIR，或给
  `families.sh` 加名字模式。
- 速度受 `git grep` 支配；5k 文件的 monorepo 端到端约 20 秒。

## 扩展
写一个打印稳定文本表的脚本，接进 `extract-all.sh`，它就自动成为 `check.sh` 基线的一部分。输出保持
确定性（排序、`LC_ALL=C`），diff 才有意义。

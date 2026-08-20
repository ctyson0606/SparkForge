# 🔥 SparkForge

[English](README.md) · [繁體中文](README.zh-TW.md) · **简体中文**

给 AI coding agent 用的工作流框架层，复制进一个新项目里使用。它本身不带任何
项目知识 —— 只带两样东西：🧠 一套累积项目知识的机制，以及 🔬 一套判断证据到底
成不成立的方法论。

## 📦 你会拿到什么

把 `template/` 复制进新项目，里面的内容就是那个项目的根目录：

```text
my-project/
├── AGENTS.md
├── CLAUDE.md
├── GEMINI.md
├── METHOD.md
├── STATE.md
├── GOTCHAS.md
├── .clinerules
├── .windsurfrules
├── .gitattributes
├── .claude/
│   ├── skills/
│   └── agents/
├── .cursor/
│   └── rules/
├── .github/
│   └── copilot-instructions.md
├── kit/
│   ├── VERSION
│   ├── entry-points.txt
│   ├── skills/
│   └── agents/
└── scripts/
    ├── check.sh
    └── update-kit.sh
```

| 文件 | 用途 |
|---|---|
| ⚙️ `AGENTS.md` | 入口，也是唯一做路由的文件。放 `MODE`、`TEAM`、你这个项目的环境命令、硬规则，以及把 agent 导向某个 skill 的那张表。 |
| 🚪 各工具的入口文件 | `CLAUDE.md`、`GEMINI.md`、`.clinerules`、`.windsurfrules`、`.cursor/rules/`、`.github/`。每一个都只说一件事：先读 `AGENTS.md`。详见下一节。 |
| 🗂️ `kit/entry-points.txt` | 那些入口文件的清单。两支检查器都读它，所以一个工具不会在这里有、在那里漏。 |
| 🧠 `METHOD.md` | 这个项目自己挣来的长效规则。**开始是空的，而且会一直空着**，直到真的踩到坑才填。 |
| 📌 `STATE.md` | 当前工作状态。整份替换，绝不往后追加。 |
| 🐛 `GOTCHAS.md` | 绑定版本的陷阱，每条都有日期。依赖消失后可以随手删掉。 |
| 📚 `kit/` | 框架的正典内容。**在消费端项目里绝对不要改这里** —— 更新时会被整个覆盖。 |
| 🪝 `.claude/` | 薄壳 stub。每个都是一段 frontmatter 加一行指向 `kit/` 的路径。 |
| ✅ `scripts/check.sh` | 对整个目录结构做的结构检查。 |
| 🔄 `scripts/update-kit.sh` | 从上游拉一份新的 `kit/` 下来。 |

分成两层正是重点：📚 `kit/` 把每条规则只写一次，每个 AI 工具各自拿到一个目录的
🪝 薄壳 stub 指过去。要支持第二个工具，是再生成一组 stub，而不是把规则再抄一遍。

## 🚪 一道指令，所有工具

你永远不需要告诉 agent 要读哪个文件。不管是哪个工具打开这个项目，它的第一道
指令都一样：**去读 `AGENTS.md`**。凡是不会自己找到那个文件的工具，都在它一定
会读的位置上有一个小文件，而那个文件除了指路之外什么都不说。

| 工具 | 它的文件 | 怎么载入 |
|---|---|---|
| 🤖 Claude Code | `CLAUDE.md` | ⚙️ `@AGENTS.md`，真的导入 |
| ✏️ Cursor | `.cursor/rules/sparkforge.mdc` | ⚙️ frontmatter 里的 `alwaysApply: true` |
| 🐙 GitHub Copilot | `.github/copilot-instructions.md` | 📄 它一定会读的路径 |
| 💠 Gemini CLI | `GEMINI.md` | 📄 它一定会读的路径 |
| 🧵 Cline | `.clinerules` | 📄 它一定会读的路径 |
| 🏄 Windsurf | `.windsurfrules` | 📄 它一定会读的路径 |
| 🌊 Codex CLI、Amp、DeepSeek Harness | `AGENTS.md` 本身 | ✅ 原生就读，不需要入口 |

其中两个是载入器自己认的机制，其余是把话放在工具一定看得到的地方。⚠️ 绝对不要
把任何指令写进这些文件里。两个工具读到两套不同的规则，正是这整个安排要防的
那种失败。

🗑️ 不用某个工具？把它的入口删掉。那就是官方的退出方式，也正是为什么
`check.sh` 把缺席的入口当成「刻意的」而不是「坏掉的」。

## 🚀 安装

```bash
# 1. 把整个 template 复制进去。要用 "template/." 而不是 "template/*"，
#    否则会不声不响地漏掉 .claude/、.cursor/、.github/ 和 .gitattributes
cp -R /path/to/SparkForge/template/. /path/to/my-project/

cd /path/to/my-project
git init
git add -A

# 2. 在 git index 里把脚本标记成可执行。
#    Windows 上工作树的 file mode 是假的，所以光靠 chmod 不够
git update-index --chmod=+x scripts/check.sh scripts/update-kit.sh

# 3. 打开 AGENTS.md，把第一行的 "# SparkForge"
#    换成你自己的项目名称

# 4. commit 之前先验证结构
bash scripts/check.sh

git commit -m "Adopt SparkForge"
```

接着打开你的 agent，**主动要它跑 bootstrap** —— 它不会自己触发。🥾 Bootstrap
只跑一次，而且只在 `METHOD.md` 和 `STATE.md` 都还是空的时候跑，它会：

1. 把脚本带着可执行位放进 index —— 跟上面第 2 步做的是同一件事，为的是
   bootstrap 自己在主导安装的那种情况。
2. 问你 `MODE` 和 `TEAM`，然后写进 `AGENTS.md`。
3. 一项一项把环境命令填进去。如果这个项目真的没有某个命令，它会写 `none` ——
   缺席本身就是一项发现，不是一格空白。
4. 按 `MODE` 选定的深度跑一次规格门。
5. 把结果写进 `STATE.md` 的 `Current Focus`。
6. **让 `METHOD.md` 保持空白。** 这是硬规则。规则要从项目真正踩到的坑挣来，
   绝不能事先用猜的。

## 🧭 日常使用

记忆会自己载入：入口文件导入 `AGENTS.md`，后者再导入 `METHOD.md`、`STATE.md`
和 `GOTCHAS.md`。每个 session 一开场，这个项目学到的所有东西都已经在 context
里了。

| 当你正在… | 读这份 | 一句话版本 |
|---|---|---|
| 🚪 准备开一个新功能 | `kit/skills/spec-gate.md` | 把需求重述成一个*问题*，只问会卡住的问题，产出目标、非目标、验收条件和数据／API 契约 —— 然后**停下来等人批准**。 |
| 🧪 看着一次全绿的测试 | `kit/skills/verification.md` | 第一次跑就全过的套件是未经验证，不是正确。故意把代码弄坏，确认该失败的那几条真的失败了。 |
| 🔍 在追一个失败 | `kit/skills/diagnosis.md` | 间歇性失败有它的*发生率*，跑一次量不出来。从结果读出任何结论之前，先确认不是测试框架自己坏了。 |
| 👥 和其他人一起做 | `kit/skills/team-contract.md` | 一次讲定数据／API 契约，以及哪些目录归谁负责。除此之外什么都不要加。 |
| 💾 被要求存记忆 | `kit/skills/memory-update.md` | 重读*整份*文件，不是只读你动过的段落。过期那一行永远不在你刚才工作的地方。 |

### 🚨 规格门在这几种情况不是选配

不管 `MODE` 写什么，只要改动碰到 🔐 认证、🛡️ 授权、💳 支付、🔑 secrets、
🗄️ 数据库 migration，或 🌐 跨越一个以上的服务，就一定要先过规格门。其他地方才是
你自己判断。

### 🧠 记忆的行为方式

- ✍️ **记忆只在被要求时才写。** 主对话绝不自己动笔 —— 你得开口。唯一的例外是被
  委派出去的 subagent，它结束时会自己写，因为它握有主线永远看不到的 context。
- 🔁 **`METHOD.md` 是累积的。** 要修一条规则就在原地改，而不是追加一条和它抵触
  的。删除则必须附上理由。
- 🧹 **`STATE.md` 是被整份替换的。** 不再为真的东西直接删掉，不做归档。历史由
  git 保管。
- ⚡ **被你自己的改动弄成假的那句话，当场就要修**，不必等人来要求。往记录里加东
  西是一个请求；让记录保持为真则是工作的一部分。

### 🕵️ 证据审查员

`kit/agents/evidence-reviewer.md` 是一个只读的 subagent，它的工具清单短得刻意
—— `Read`、`Grep`、`Glob`。它不能执行命令，因为一个能执行的 agent 会变成第二个
实现者，而不是第二双眼睛。它只会用三句话之一回答：**Evidence holds.** ／
**Evidence insufficient.** 并指名是哪几条规则没过 ／ **Cannot judge.** 并指名
缺了什么。

## 🔄 更新

```bash
# 从上游覆盖 kit/。METHOD.md、STATE.md、GOTCHAS.md
# 以及 AGENTS.md 的每一个段落都是你的，永远不会被碰
scripts/update-kit.sh

# 上游新增或移除一个 skill，对应的 stub 也要跟着加或删，
# 而这支脚本就是负责报告这件事的
bash scripts/check.sh
```

📣 如果某次更新开始支持一个你没有入口文件的工具，`update-kit.sh` 会把它列出来。
它只报那次更新带进来的，绝不报所有缺席的入口 —— 一个对每个你刻意不用的工具都
叫一次的警告，看两次之后就没人读了。

用的过程中想到改进？把它送回上游，不要在本地改 `kit/`。而且送的时候，顺手读一
下上游 `STATE.md` 里的 `Unverified` 区块 —— 🏅 一条被你的项目真正走过的规则，
价值比那个改进本身还高。

## 🌡️ 成熟度

明说，因为这个框架自己的方法论就要求这样。**这里面没有任何一部分在真实项目上
用过。**

| 组件 | 状态 |
|---|---|
| 🧪 `verification.md` | ✅ 规则萃取自真实事故，多数都附着一笔有记录的。 |
| 🔍 `diagnosis.md` | ✅ 同上 —— 萃取自一套在用的方法论，不是照规格写出来的。 |
| 💾 `memory-update.md` | ✅ 同上。 |
| ✅ `check.sh` | ✅ 跑得起来，而且在这个 repo 里抓出过真的漏洞。 |
| 🔄 `update-kit.sh` | 🟡 对着一个抛弃式上游跑过四个案例。从未对真实 remote 跑过，破坏性的那半也从没在有人会心疼的内容上跑过。 |
| 🚪 各工具的入口文件 | 🟡 其中两个靠的是工具自己认的机制。另外四个是放在工具应该会读的位置上的散文，而那四个都没有被看着载入过。 |
| 🚪 `spec-gate.md` | ⚠️ 照规格写的。零执行。 |
| 👥 `team-contract.md` | ⚠️ 照规格写的。零执行。 |
| 🥾 `bootstrap.md` | ⚠️ 照规格写的。零执行。 |
| 🕵️ `evidence-reviewer.md` | ⚠️ 照规格写的。零执行。 |
| 🎚️ `T0`／`T1`／`T2` 分级系统 | ⚠️ 从未被执行过。到目前为止那些标签只是注解。 |

上面那段安装流程是从目录结构推导出来的，不是谁真的走过一遍。🧗 第一个照着跑的
人是在开路 —— 把摩擦记下来，因为那份记录才是这一节本来该有的样子。

## 🚫 SparkForge 不包含什么

以下描述的是框架本身的边界 —— SparkForge 不出货什么。它们对「用 SparkForge 的
项目可以做什么」不作任何限制。

- ❌ 没有内建的任务追踪、看板或任务卡。
- ❌ 不对既有的代码库做冷启动扫描。SparkForge 的设计对象只有从第一个 commit
  就采用它的项目。
- ❌ 没有为非软件工作做的设计。
- ❌ 没有 UI 设计系统，也没有 mockup 关卡。
- ❌ 不收任何价值取决于全队都采用的模块。这是新模块的入场考题：如果团队里刚好
  只有一个人用它，它还值得存在吗？

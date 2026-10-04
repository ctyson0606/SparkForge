# 🔥 SparkForge

[English](README.md) · **繁體中文** · [简体中文](README.zh-CN.md)

給 AI coding agent 用的工作流框架層，複製進一個新專案裡使用。它本身不帶任何
專案知識 —— 只帶兩樣東西：🧠 一套累積專案知識的機制，以及 🔬 一套判斷證據到底
成不成立的方法論。

## 📦 你會拿到什麼

把 `template/` 複製進新專案，裡面的內容就是那個專案的根目錄：

```text
my-project/
├── AGENTS.md
├── CLAUDE.md
├── GEMINI.md
├── SPEC.md
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
│   ├── agents/
│   └── scripts/
└── scripts/
    ├── check.sh
    ├── progress.sh
    ├── progress.ps1
    └── update-kit.sh
```

| 檔案 | 用途 |
|---|---|
| ⚙️ `AGENTS.md` | 入口，也是唯一做路由的檔案。放 `MODE`、`TEAM`、你這個專案的環境指令、硬規則，以及把 agent 導向某個 skill 的那張表。 |
| 🚪 各工具的入口檔 | `CLAUDE.md`、`GEMINI.md`、`.clinerules`、`.windsurfrules`、`.cursor/rules/`、`.github/`。每一個都只說一件事：先讀 `AGENTS.md`。詳見下一節。 |
| 🗂️ `kit/entry-points.txt` | 那些入口檔的清單。兩支檢查器都讀它，所以一個工具不會在這裡有、在那裡漏。 |
| 📐 `SPEC.md` | 批准過的契約：目標、非目標、驗收條件、資料和 API 的格式。只能透過規格門修改，所以不會隨著狀態更新被清掉。 |
| 🧠 `METHOD.md` | 這個專案自己掙來的長效規則。**開始是空的，而且會一直空著**，直到真的踩到坑才填。 |
| 📌 `STATE.md` | 當前工作狀態。整份替換，絕不往後追加。 |
| 🐛 `GOTCHAS.md` | 綁定版本的陷阱，每條都有日期。相依套件消失後可以隨手刪掉。 |
| 📚 `kit/` | 框架的正典內容。**在消費端專案裡絕對不要改這裡** —— 更新時會被整個覆蓋。 |
| 🪝 `.claude/` | 薄殼 stub。每個都是一段 frontmatter 加一行指向 `kit/` 的路徑。 |
| ✅ `scripts/check.sh` | 對整個目錄結構做的結構檢查。只有一行的薄殼：真正的檢查器是 `kit/scripts/check.sh`，所以它的修正會跟著 `kit/` 一起更新。 |
| 🔄 `scripts/update-kit.sh` | 從上游拉一份新的 `kit/` 下來，連同 `kit/scripts/` 裡的腳本。它也是薄殼，所以會連自己一起更新。 |
| 📊 `scripts/progress.sh` | 用 `SPEC.md`、`STATE.md` 和 git 產生一頁獨立的 HTML —— 目標、每條驗收條件連同記錄下來的證據、上次檢視之後的變更、下一步，做成卡片，只在檔案裡寫了 id 的地方才連線 —— 然後開啟。它不儲存任何東西，所以不會過期。Windows 請用 `scripts/progress.ps1`。在 `AGENTS.md` 設定 `TRANSLATION` 就能有第二種語言。 |

分成兩層正是重點：📚 `kit/` 把每條規則只寫一次，每個 AI 工具各自拿到一個目錄的
🪝 薄殼 stub 指過去。要支援第二個工具，是再生一組 stub，而不是把規則再抄一遍。

## 🚪 一道指令，所有工具

你永遠不需要告訴 agent 要讀哪個檔案。不管是哪個工具打開這個專案，它的第一道
指令都一樣：**去讀 `AGENTS.md`**。凡是不會自己找到那個檔案的工具，都在它一定
會讀的位置上有一個小檔案，而那個檔案除了指路之外什麼都不說。

| 工具 | 它的檔案 | 怎麼載入 |
|---|---|---|
| 🤖 Claude Code | `CLAUDE.md` | ⚙️ `@AGENTS.md`，真的匯入 |
| ✏️ Cursor | `.cursor/rules/sparkforge.mdc` | ⚙️ frontmatter 裡的 `alwaysApply: true` |
| 🐙 GitHub Copilot | `.github/copilot-instructions.md` | 📄 它一定會讀的路徑 |
| 💠 Gemini CLI | `GEMINI.md` | 📄 它一定會讀的路徑 |
| 🧵 Cline | `.clinerules` | 📄 它一定會讀的路徑 |
| 🏄 Windsurf | `.windsurfrules` | 📄 它一定會讀的路徑 |
| 🌊 Codex CLI、Amp、DeepSeek Harness | `AGENTS.md` 本身 | ✅ 原生就讀，不需要入口 |

其中兩個是載入器自己認的機制，其餘是把話放在工具一定看得到的地方。⚠️ 絕對不要
把任何指令寫進這些檔案裡。兩個工具讀到兩套不同的規則，正是這整個安排要防的
那種失敗。

🗑️ 不用某個工具？把它的入口刪掉。那就是官方的退出方式，也正是為什麼
`check.sh` 把缺席的入口當成「刻意的」而不是「壞掉的」。

## 🚀 安裝

```bash
# 1. 把整個 template 複製進去。要用 "template/." 而不是 "template/*"，
#    否則會不聲不響地漏掉 .claude/、.cursor/、.github/ 和 .gitattributes。
#    兩個路徑都要加引號：裡面只要有一個空格就會整行壞掉
cp -R "/path/to/SparkForge/template/." "/path/to/my-project/"

cd "/path/to/my-project"
git init

# 2. 打開 AGENTS.md，把第一行的 "# SparkForge" 換成你自己的專案名稱。
#    這件事一定要在 stage 之前做：先 stage 的話，下面那個 commit 進去的
#    會是舊標題，而工作目錄顯示的是新的，兩邊不一致又不會有提示

# 3. 先 stage，再把可執行位元寫進 index。Windows 上工作樹裡的
#    mode 是假的，所以 chmod 做不到這件事
git add -A
git add --chmod=+x -- 'scripts/*.sh' 'kit/scripts/*.sh'

#    下面這行印出來的每一行，開頭都必須是 100755
git ls-files -s -- 'scripts/*.sh' 'kit/scripts/*.sh'

# 4. 驗證結構，然後 commit
bash scripts/check.sh
git commit -m "Adopt SparkForge"
```

⚠️ 在 Windows 上，請用 **Git Bash** 跑上面那段，不要用 PowerShell。在
PowerShell 打 `bash` 會命中 `C:\Windows\System32\bash.exe`，那是 WSL 的啟動器
而不是 Git Bash；沒裝發行版的話會噴 `execvpe(/bin/bash) failed`，而那個訊息
跟真正的原因完全沾不上邊。想留在 PowerShell 的話，用完整路徑呼叫 Git 自己的
bash：

```powershell
# 先找出 Git 實際裝在哪 —— 它不一定在 C 槽
(Get-Command git).Source

# 然後呼叫它旁邊那個 bash。前面的 & 不能省：少了它，PowerShell 會把
# 加引號的路徑當成字串直接印出來，而不是執行它
& "C:\Program Files\Git\bin\bash.exe" scripts/check.sh
```

接著打開你的 agent，**主動要它跑 bootstrap** —— 它不會自己觸發。🥾 Bootstrap
只跑一次，而且只在 `METHOD.md` 和 `STATE.md` 都還是空的時候跑，它會：

1. 把腳本帶著可執行位元放進 index —— 跟上面第 3 步做的是同一件事，為的是
   bootstrap 自己在主導安裝的那種情況。
2. 問你 `MODE` 和 `TEAM`，然後寫進 `AGENTS.md`。
3. 一項一項把環境指令填進去。如果這個專案真的沒有某個指令，它會寫 `none` ——
   缺席本身就是一項發現，不是一格空白。
4. 依 `MODE` 選定的深度跑一次規格門。
5. 把結果寫進 `SPEC.md`，並在 `STATE.md` 的 `Current Focus` 註明先做哪一部分。
6. **讓 `METHOD.md` 保持空白。** 這是硬規則。規則要從專案真正踩到的坑掙來，
   絕不能事先用猜的。

## 🧭 日常使用

記憶會自己載入：入口檔匯入 `AGENTS.md`，後者再匯入 `SPEC.md`、`METHOD.md`、
`STATE.md` 和 `GOTCHAS.md`。每個 session 一開場，這個專案學到的所有東西都已經在 context
裡了。

| 當你正在… | 讀這份 | 一句話版本 |
|---|---|---|
| 🚪 準備開一個新功能 | `kit/skills/spec-gate.md` | 把需求重述成一個*問題*，只問會卡住的問題，產出目標、非目標、驗收條件和資料／API 契約 —— 然後**停下來等人批准**。 |
| 🧪 看著一次全綠的測試 | `kit/skills/verification.md` | 第一次跑就全過的套件是未經驗證，不是正確。故意把程式碼弄壞，確認該失敗的那幾條真的失敗了。 |
| 🔍 在追一個失敗 | `kit/skills/diagnosis.md` | 間歇性失敗有它的*發生率*，跑一次量不出來。從結果讀出任何結論之前，先確認不是測試框架自己壞了。 |
| 👥 和其他人一起做 | `kit/skills/team-contract.md` | 一次講定資料／API 契約，以及哪些目錄歸誰負責。除此之外什麼都不要加。 |
| 💾 寫記憶 | `kit/skills/memory-update.md` | 狀態一變就寫，絕不留到最後。寫之前先重讀*整份*檔案：過期那一行永遠不在你剛才工作的地方。 |

### 🚨 規格門在這幾種情況不是選配

不管 `MODE` 寫什麼，只要改動碰到 🔐 認證、🛡️ 授權、💳 金流、🔑 secrets、
🗄️ 資料庫 migration，或 🌐 跨越一個以上的服務，就一定要先過規格門。其他地方才是
你自己判斷。

### 🧠 記憶的行為方式

- ✍️ **記憶是邊做邊寫的。** 狀態一改變 —— 完成一步、做了決定、有新發現、踩到坑
  —— agent 就當場寫下來，不用你開口，也絕不留到最後，因為額度用完或你換工具時，
  session 可能說斷就斷。開口要求仍然有效：說一聲，所有檔案就會立刻更新到最新。被
  委派出去的 subagent 在回傳之前寫，因為它的 context 會跟著它一起消失。
- 🔁 **`METHOD.md` 是累積的。** 要修一條規則就在原地改，而不是追加一條和它牴觸
  的。刪除則必須附上理由。
- 🧹 **`STATE.md` 是被整份替換的。** 不再為真的東西直接刪掉，不做封存。歷史由
  git 保管。
- ⚡ **被你自己的改動弄成假的那句話，要在同一步裡修掉**，修完才往下走。在那之前
  它會被當真。讓記錄保持為真是工作的一部分。

### 🕵️ 證據審查員

`kit/agents/evidence-reviewer.md` 是一個唯讀的 subagent，它的工具清單短得刻意
—— `Read`、`Grep`、`Glob`。它不能執行指令，因為一個能執行的 agent 會變成第二個
實作者，而不是第二雙眼睛。它只會用三句話之一回答：**Evidence holds.** ／
**Evidence insufficient.** 並指名是哪幾條規則沒過 ／ **Cannot judge.** 並指名
缺了什麼。

## 🔄 更新

```bash
# 從上游覆蓋 kit/。SPEC.md、METHOD.md、STATE.md、GOTCHAS.md
# 以及 AGENTS.md 的每一個段落都是你的，永遠不會被碰
scripts/update-kit.sh

# 上游新增或移除一個 skill，對應的 stub 也要跟著加或刪，
# 而這支腳本就是負責回報這件事的
bash scripts/check.sh
```

📣 如果某次更新開始支援一個你沒有入口檔的工具，`update-kit.sh` 會把它列出來。
它只報那次更新帶進來的，絕不報所有缺席的入口 —— 一個對每個你刻意不用的工具都
叫一次的警告，看兩次之後就沒人讀了。

📦 腳本搬進 `kit/scripts/` 之前就安裝的專案，`scripts/` 裡放的還是完整腳本。請手動
從 SparkForge 的 `template/scripts/` 複製那兩個薄殼過去覆蓋一次。在那之前，舊的腳
本會一直被執行，`kit/scripts/` 裡送來的修正永遠用不到。

📮 發現了屬於 SparkForge、而不是你專案本身的問題？例如一條規則被證明是錯的、一個
檢查漏抓了東西、一支腳本壞了。不要在本地改 `kit/`。agent 會像寫其他記憶一樣，把
它寫進你 `STATE.md` 的 `Upstream` 段落，一直留到上游處理完為止。放在你專案旁邊的
SparkForge 只要跑一個指令 `scripts/collect-upstream.sh`，就能一次讀出所有專案的這
個段落。🏅 你的專案第一個真正走過的框架規則也要寫在那裡：它比大多數改進都值錢。

## 🌡️ 成熟度

明講，因為這個框架自己的方法論就要求這樣。**它已經安裝在三個真實專案上，全都是
Windows。其中一個桌面工具已經做完規格裡的每一條驗收條件，每天都在用；另外兩個也
都通過了規格門，之後一直在開發。** 細節，以及哪些部分到現在都還沒被實際用過，記在
這個 repo 的 `STATE.md` 裡。

| 元件 | 狀態 |
|---|---|
| 🧪 `verification.md` | ✅ 規則萃取自真實事故，多數都附著一筆有記錄的。其中幾條現在已經有兩、三個專案的事件。 |
| 🔍 `diagnosis.md` | ✅ 同上 —— 萃取自一套在用的方法論，不是照規格寫出來的。 |
| 💾 `memory-update.md` | ✅ 同上。「邊做邊寫記憶」在出貨前實測過：完全不提記憶，agent 也會把下一步記下來；舊規則下則不會。 |
| ✅ `check.sh` | ✅ 跑得起來，而且抓出過真的漏洞，在這個 repo 裡和在使用它的專案裡都有。 |
| 🔄 `update-kit.sh` | ✅ 已經從真的遠端把真的改動拉進三個專案，包括現在這一版：腳本跟著 `kit/` 一起更新，在每個專案裡都在執行途中替換掉了自己。還沒遇過有人在本地改過 `kit/` 的情況。 |
| 🚪 各工具的入口檔 | 🟡 Claude Code 那個是載入器自己認的匯入，也已經被看著把一個真實專案的規則帶進 session。其他的都是靠叫 agent 去打開 `AGENTS.md`，而這種要求在這裡的實驗中被 agent 忽略過。它們都沒打開過。 |
| 📐 `SPEC.md` | 🟡 新加的。三個專案的規格都已經手動搬進來；規格門還沒有親自寫過一份。 |
| 🚪 `spec-gate.md` | 🟡 照規格寫的。在三個專案裡都產出過它該產出的四樣東西，每次都是 bootstrap 的第 4 步。從沒看過它自己觸發。 |
| 👥 `team-contract.md` | ⚠️ 照規格寫的。零執行。 |
| 🥾 `bootstrap.md` | ✅ 照規格寫的，三個專案都跑過。它不會自己啟動：要指名叫它。 |
| 🕵️ `evidence-reviewer.md` | ⚠️ 照規格寫的。零執行。 |
| 🎚️ `T0`／`T1`／`T2` 分級系統 | ⚠️ 從未被執行過。到目前為止那些標籤只是註解。 |

上面那段安裝流程實際走過三次，全都在 Windows 上，並依第一次踩到的坑修正過。macOS
和 Linux 上還沒人走過。🧗 在新平台上第一個照著跑的人是在開路 —— 把摩擦記下來，這
一節第一次被修正，靠的就是那份記錄。

## 🚫 SparkForge 不包含什麼

以下描述的是框架本身的邊界 —— SparkForge 不出貨什麼。它們對「用 SparkForge 的
專案可以做什麼」不作任何限制。

- ❌ 沒有內建的任務追蹤、看板或任務卡。
- ❌ 不對既有的程式碼庫做冷啟動掃描。SparkForge 的設計對象只有從第一個 commit
  就採用它的專案。
- ❌ 沒有為非軟體工作做的設計。
- ❌ 沒有 UI 設計系統，也沒有 mockup 關卡。
- ❌ 不收任何價值取決於全隊都採用的模組。這是新模組的入場考題：如果團隊裡剛好
  只有一個人用它，它還值得存在嗎？

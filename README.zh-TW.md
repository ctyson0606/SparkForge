<!-- Hero -->
<div align="center">
  <h1>🔥 SparkForge</h1>
  <p><b>給 AI 編碼 agent 用的工作流程框架</b>：複製進新專案後，它讓 agent 擁有會累積的記憶，以及判斷證據是否成立的方法；它本身不帶任何專案知識。</p>
  <p>
    <img alt="for: AI coding agents" src="https://img.shields.io/badge/for-AI%20coding%20agents-4d6bfe">
    <img alt="shell: bash" src="https://img.shields.io/badge/shell-bash-4d6bfe">
    <img alt="dependencies: git, bash, awk" src="https://img.shields.io/badge/dependencies-git%2C%20bash%2C%20awk-brightgreen">
    <img alt="license: MIT" src="https://img.shields.io/badge/license-MIT-blue">
  </p>
  <p>🌏 <a href="./README.zh-CN.md">简体中文</a> · 繁體中文 · <a href="./README.md">English</a></p>
</div>

<p align="center"><img src="docs/progress-page.png" alt="使用 SparkForge 的專案的進度頁" width="720"></p>

## ✨ 功能

- **會累積的記憶**：`SPEC.md`、`METHOD.md`、`STATE.md` 和 `GOTCHAS.md` 每個 session 都會載入，agent 在狀態一改變時就寫下來，不用等人叫。
- **一個指令，所有工具**：Claude Code、Cursor、Copilot、Gemini CLI、Cline、Windsurf、Codex CLI、Amp 和 DeepSeek Harness 都從 `AGENTS.md` 開始。
- **規格門**：一個功能從問題、目標和驗收標準開始，由人批准；碰到認證、付款、密鑰或資料庫遷移的改動不能跳過。
- **站得住的證據**：從真實事故提煉的規則，判斷一次通過的測試到底證明了什麼，以及如何把失敗追到原因。
- **進度頁**：一個指令就從規格、狀態和 git 生成一頁——帶證據的驗收標準、路線圖、功能指南、元件結構和工作時間線，支援英文加一種語言。
- **會失敗的檢查**：`scripts/check.sh` 檢查結構、stub、執行權限、README 各版本，以及 README 對 repository 的描述是否屬實。
- **從上游更新**：`scripts/update-kit.sh` 替換 `kit/`，並列出更新在 `kit/` 以外需要的東西。

## 🚀 安裝

前提：git 和 bash。Windows 上就是 Git for Windows 附帶的 Git Bash。

**方式一 · Git Bash、macOS 或 Linux**

```bash
# 複製整個範本。要用 "template/."，不能用 "template/*"，
# 否則 .claude/、.cursor/、.github/ 和 .gitattributes 會被悄悄漏掉
cp -R "/path/to/SparkForge/template/." "/path/to/my-project/"
cd "/path/to/my-project"
git init

# 在 stage 任何東西之前，把 AGENTS.md 第一行的 "# SparkForge"
# 換成你的專案名稱

# 先 stage，再在 index 裡設定執行權限：Windows 的工作目錄
# 沒有真正的權限位元，chmod 做不到
git add -A
git add --chmod=+x -- 'scripts/*.sh' 'kit/scripts/*.sh'
git commit -m "Adopt SparkForge"
```

**方式二 · 從 PowerShell**

<details>
<summary>想留在 PowerShell 裡時用這個</summary>

在 PowerShell 裡輸入 `bash`，會找到 `C:\Windows\System32\bash.exe`，那是 WSL 的啟動器；沒有安裝發行版時，它會報 `execvpe(/bin/bash) failed`。改用 Git 附帶的 bash：

```powershell
# Git 裝在哪裡；不一定在 C: 槽
(Get-Command git).Source

# & 不能省：沒有它，PowerShell 只會把引號裡的路徑印出來
& "C:\Program Files\Git\bin\bash.exe" scripts/check.sh
```

</details>

**驗證**

```bash
git ls-files -s -- 'scripts/*.sh' 'kit/scripts/*.sh'
bash scripts/check.sh
```

第一個指令的每一行都以 `100755` 開頭，第二個指令最後印出 `check.sh: all checks passed`。

## 🕹️ 使用

### 第一個 session

打開你的 agent，叫它**執行 bootstrap**；它不會自己開始。bootstrap 只跑一次，它會：

1. 把腳本連同執行權限 stage 進 index；
2. 詢問 `MODE` 和 `TEAM`，寫進 `AGENTS.md`；
3. 逐項填好 Environment facts，專案確實沒有的指令就寫 `none`；
4. 按 `MODE` 選擇的深度執行規格門；
5. 把結果寫進 `SPEC.md`，並讓 `STATE.md` 指向第一個要做的部分；
6. **讓 `METHOD.md` 保持空白**：規則要從專案真正踩到的坑裡得來，不能預先猜。

### 之後的每一天

記憶會自己載入：入口檔案匯入 `AGENTS.md`，`AGENTS.md` 再匯入四個記憶檔。agent 按情境使用 skill：

| 當你正在… | Skill | 一句話 |
| --- | --- | --- |
| 🚪 準備做一個功能 | `kit/skills/spec-gate.md` | 把需求重述成問題，只問會卡住的問題，寫出目標、非目標、驗收標準和合約，然後停下來等批准。 |
| 🧪 看著一次全綠的測試 | `kit/skills/verification.md` | 第一次就通過的測試是未驗證的。故意弄壞程式碼，看該失敗的測試有沒有失敗。 |
| 🔍 追查一個失敗 | `kit/skills/diagnosis.md` | 間歇性失敗有發生率，跑一次量不出來。 |
| 👥 和別人一起工作 | `kit/skills/team-contract.md` | 只約定一次合約，以及誰負責哪些目錄。 |
| 💾 寫記憶 | `kit/skills/memory-update.md` | 狀態一改變就寫；寫之前先重讀整個檔案。 |
| 📝 寫 README | `kit/skills/readme.md` | 就是這一頁的格式，三個語言版本，結構和指令都會被檢查。 |

### 這些情況下規格門不能省

不管 `MODE` 是什麼，任何碰到 🔐 認證、🛡️ 授權、💳 付款、🔑 密鑰、🗄️ 資料庫遷移，或 🌐 不止一個服務的改動，都要過規格門。

### 記憶怎麼運作

- **邊做邊寫**：做完一步、做了決定、踩到坑——馬上寫下，因為 session 隨時可能中斷。
- **`METHOD.md` 累積**：規則在原處修正，不另外加一條互相矛盾的。
- **`STATE.md` 整份取代**：不再成立的內容直接刪掉；歷史由 git 保存。
- **你的改動讓某個說法變錯，就在同一步修正**。

### 進度頁

```bash
bash scripts/progress.sh
```

它讀取 `SPEC.md`、`STATE.md` 和 git，不儲存任何東西，所以不會過時。在 `AGENTS.md` 設定 `TRANSLATION` 可以加一種語言：你叫 agent 打開頁面時它會先寫好翻譯，剩下的可以用瀏覽器機器翻譯。

### 更新

```bash
bash scripts/update-kit.sh
bash scripts/check.sh
```

第一個指令替換 `kit/`，並列出更新在 `kit/` 以外新需要的東西；第二個確認結果。屬於 SparkForge 而不是你專案的發現，寫在你 `STATE.md` 的 `Upstream` 底下，旁邊 SparkForge checkout 裡的 `scripts/collect-upstream.sh` 會讀到它。

## 🚪 一個指令，所有工具

自己找不到 `AGENTS.md` 的工具，在它一定會讀的路徑放一個小檔案，裡面只說該去哪裡。⚠️ 絕不要在這些檔案裡寫指示：兩個工具讀到兩套規則，正是這個安排要防止的。不用某個工具？刪掉它的入口檔就好。

| 工具 | 它的檔案 | 怎麼載入 |
| --- | --- | --- |
| 🤖 Claude Code | `CLAUDE.md` | `@AGENTS.md`，真正的匯入 |
| ✏️ Cursor | `.cursor/rules/sparkforge.mdc` | `alwaysApply: true` |
| 🐙 GitHub Copilot | `.github/copilot-instructions.md` | 它一定會讀的路徑 |
| 💠 Gemini CLI | `GEMINI.md` | 它一定會讀的路徑 |
| 🧵 Cline | `.clinerules` | 它一定會讀的路徑 |
| 🏄 Windsurf | `.windsurfrules` | 它一定會讀的路徑 |
| 🌊 Codex CLI、Amp、DeepSeek Harness | `AGENTS.md` 本身 | 原生讀取 |

## 🧰 專案會得到什麼

| 檔案 | 用途 |
| --- | --- |
| ⚙️ `AGENTS.md` | 入口，也是唯一負責分派的檔案：宣告、Environment facts、硬性規則、skill 表。 |
| 📐 `SPEC.md` | 已批准的合約。只能經過規格門修改。 |
| 🧠 `METHOD.md` | 這個專案掙來的規則。一開始是空的。 |
| 📌 `STATE.md` | 工作進行到哪。整份取代，從不追加。 |
| 🐛 `GOTCHAS.md` | 綁定版本的陷阱，每條都有日期。 |
| 📚 `kit/` | 框架本身。在專案裡絕不修改；更新時會被覆蓋。 |
| 🪝 `.claude/` | stub，每個都指向 `kit/`。 |
| ✅ `scripts/` | `check.sh`、`update-kit.sh` 和 `progress.sh` 的 stub，交給 `kit/scripts/` 執行。 |

## 🌡️ 成熟度

照實說明，因為這個框架自己的方法要求這樣做。它已安裝在五個專案：四個在 Windows，一個在 Linux 容器。其中一個桌面工具已經完成所有驗收標準，每天都在用。

| 元件 | 狀況 |
| --- | --- |
| 🧪 `verification.md`、🔍 `diagnosis.md`、💾 `memory-update.md` | ✅ 從真實事故提煉；好幾條規則帶著兩三個專案的事故紀錄。 |
| ✅ `check.sh`、🔄 `update-kit.sh` | ✅ 在每個專案都跑過；`update-kit.sh` 曾在執行中替換自己而不留痕跡。 |
| 🥾 `bootstrap.md`、🚪 `spec-gate.md` | 🟡 按規格寫成，在每個專案都跑過；規格門每次都是 bootstrap 的第四步，從沒自己觸發過。 |
| 📊 進度頁 | 🟡 每個專案都裝了；只在一個專案看到實際使用。 |
| 📝 `readme.md` | 🟡 新的。這一頁是它的第一次使用。 |
| 🚪 各工具的入口檔 | 🟡 Claude Code 的已觀察到有效；其他的是請 agent 打開 `AGENTS.md`，都還沒實際打開過。 |
| 👥 `team-contract.md`、🕵️ `evidence-reviewer.md`、🎚️ T0/T1/T2 分級 | ⚠️ 從未使用過。 |

## 🛠️ 開發與測試

這個 repository 存放框架本身；`template/` 是專案會得到的東西。任何改動之後：

```bash
bash scripts/check-repo.sh
```

選擇下一步要做什麼之前，先讀旁邊各專案記錄下來的東西：

```bash
bash scripts/collect-upstream.sh
```

## 📦 專案結構

```text
template/
template/kit/skills/
template/kit/scripts/
template/kit/readme-skeleton.md
scripts/check-repo.sh
scripts/collect-upstream.sh
source/METHOD.md
METHOD.md
STATE.md
docs/progress-page.png
```

- `template/`：專案複製進去的內容，它的內容會成為專案的根目錄；
- `template/kit/skills/`：正式的 skill，一個檔案一個；
- `template/kit/scripts/`：檢查器、更新器和進度頁；
- `template/kit/readme-skeleton.md`：這一頁的格式，供複製；
- `scripts/check-repo.sh`：先對 `template/` 執行附帶的檢查器，再執行只屬於這個 repository 的檢查；
- `scripts/collect-upstream.sh`：列出這個 checkout 旁邊的每個專案、它的 `kit/` 是否最新，以及它的 `Upstream`；
- `source/METHOD.md`：這些規則轉化前的方法論原文；
- `METHOD.md`、`STATE.md`：SparkForge 自己的記憶，和 `template/` 裡的空殼分開；
- `docs/progress-page.png`：上面那張截圖。

## ⚠️ 相容性與限制

- 在 Windows 上寫成，在 Linux 容器裡走過一遍；從沒在 macOS 上跑過，雖然腳本是照它的 bash 3.2 和 BSD awk 寫的。
- 沒有任務追蹤、看板或任務卡。
- 不掃描既有的程式碼：SparkForge 是給從第一個 commit 就採用它的專案。
- 沒有針對非軟體工作的設計，沒有 UI 設計系統，沒有設計稿關卡。
- 不收任何需要整個團隊都採用才有價值的模組。

## ❓ 常見問題

| 症狀 | 怎麼做 |
| --- | --- |
| PowerShell 裡出現 `execvpe(/bin/bash) failed` | 那是 WSL 的啟動器，不是 Git Bash；改用 Git Bash，或上面的方式二 |
| `check.sh` 說某個 shell 腳本在 index 裡沒有執行權限 | 對它點名的檔案執行 `git add --chmod=+x`；Windows 上 `chmod` 設定不了 |
| 複製後少了 `.claude/` 或 `.github/` | 複製時用了 `template/*`；重新複製 `template/.` |
| `update-kit.sh` 抓不到上游 | 它從不等待登入；改傳它印出的 SSH URL |
| 剛更新完 `check.sh` 就失敗 | 更新需要 `kit/` 以外的東西；照每一行失敗訊息的提示補上 |
| 進度頁全是英文，帶著 EN 標記 | 叫 agent 打開頁面，或按頁面上的翻譯按鈕 |

## 📄 授權

MIT，見 [LICENSE](LICENSE)。

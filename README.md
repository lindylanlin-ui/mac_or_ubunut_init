# Mac OS 一鍵安裝環境與程式の腳本

## 說明：<br>

使用 shell script 來安裝 MacOS 環境與套件，並且會自動安裝一些常用的軟體(cask)，以及設定一些常用的環境變數 (這些都是我常用的，可以根據個人需求自行調整)。

1. 首先要使用該腳本，請先將該檔案給 clone 下來，並且調整該 .sh 檔案可執行權限。
2. 檢查該腳本要安裝的內容是否為你所需要的，若不是，請自行修改。
3. 需要修改的設定參數，都放置在該腳本最上方，主要會修改的是 `brew_tap_array`、`brew_array`、`brew_cask`，該參數分別代表：
   1. `brew_tap_array`：安裝不再 homebrew 的第三方套件，例如：`hashicorp/tap`。
   2. `brew_array`：需要安裝的套件，例如：`k9s`。
   3. `brew_cask`：需要安裝的應用程式，例如：`notion`。
4. 修改完畢後，就可以執行該腳本，腳本會自動安裝所有的套件與應用程式，並且會自動設定環境變數

<br>

![圖片](https://raw.githubusercontent.com/880831ian/mac-install-kit/master/images/1.webp)

<br>

## 套件清單：<br>

### 命令列工具 (brew_array) - 35 個套件


| 套件名稱        | 用途             | 套件名稱       | 用途                |
| --------------- | ---------------- | -------------- | ------------------- |
| zsh             | Shell 環境       | kubernetes-cli | Kubernetes 管理工具 |
| bash-completion | Bash 自動補全    | kustomize      | Kubernetes 配置管理 |
| watch           | 定期執行命令     | helm           | Kubernetes 套件管理 |
| terraform       | 基礎架構即程式碼 | terragrunt     | Terraform 封裝工具  |
| kubectx         | Kubernetes 切換  | jq             | JSON 處理工具       |
| okteto          | K8s 開發工具     | k9s            | K8s TUI 管理介面    |
| shellcheck      | Shell 腳本檢查   | autojump       | 目錄快速跳轉        |
| hugo            | 靜態網站生成器   | wget           | 檔案下載工具        |
| telnet          | 網路測試工具     | tree           | 目錄樹狀顯示        |
| k6              | 負載測試工具     | fzf            | 模糊搜尋工具        |
| kor             | K8s 資源清理     | kubent         | K8s API 棄用檢查    |
| k8sgpt          | K8s AI 診斷      | k3d            | 輕量級 Kubernetes   |
| pv              | 進度顯示工具     | dialog         | 對話框工具          |
| ipcalc          | IP 計算工具      | yq             | YAML 處理工具       |
| helmfile        | Helm 批次管理    | awscli         | AWS 命令列工具      |
| granted         | AWS 帳號切換     | node           | Node.js             |
| go              | Go 語言          | webp           | WebP 圖片工具       |
| argocd          | GitOps 部署工具  | vault          | 密鑰管理工具        |

### GUI 應用程式 (brew_cask) - 20 個應用


| 應用程式           | 用途           | 應用程式        | 用途         |
| ------------------ | -------------- | --------------- | ------------ |
| 1password          | 密碼管理器     | google-chrome   | 瀏覽器       |
| chatgpt-atlas      | ChatGPT 客戶端 | iterm2          | 終端機       |
| visual-studio-code | 程式編輯器     | gitkraken       | Git GUI 工具 |
| postman            | API 測試工具   | docker          | 容器化平台   |
| telegram-desktop   | 即時通訊       | spotify         | 音樂串流     |
| raycast            | 啟動器工具     | logi-options+   | 羅技設備管理 |
| notion             | 筆記工具       | notion-calendar | 行事曆       |
| google-cloud-sdk   | GCP 工具       | openvpn-connect | VPN 工具     |
| chatgpt            | ChatGPT 桌面版 | amazon-q        | AWS AI 助理  |
| drawio             | 流程圖工具     | kiro            | 其他工具     |

<br>

## 自訂套件清單：<br>

### 新增套件

1. **新增命令列工具**：在 `brew_array` 中加入套件名稱

   ```bash
   brew_array=("zsh" "bash-completion" ... "你要加的套件名稱")
   ```
2. **新增 GUI 應用程式**：在 `brew_cask` 中加入應用程式名稱

   ```bash
   brew_cask=("1password" "google-chrome" ... "你要加的應用程式名稱")
   ```
3. **查詢套件名稱**：

   ```bash
   # 搜尋命令列工具
   brew search 套件名稱

   # 搜尋 GUI 應用程式
   brew search --cask 應用程式名稱
   ```

### 移除套件

直接從 `brew_array` 或 `brew_cask` 中刪除不需要的套件名稱即可。

<br>

## 移除已安裝套件：<br>

### 移除命令列工具

```bash
# 移除單一套件
brew uninstall 套件名稱

# 移除多個套件
brew uninstall 套件1 套件2 套件3

# 範例：移除 hugo 和 telnet
brew uninstall hugo telnet
```

### 移除 GUI 應用程式

```bash
# 移除應用程式（需加 --cask）
brew uninstall --cask 應用程式名稱

# 範例：移除 Spotify
brew uninstall --cask spotify

# 完全移除（包括設定檔）
brew uninstall --cask --zap spotify
```

### 清理系統

```bash
# 清理下載的安裝檔案快取
brew cleanup

# 查看可移除的依賴項
brew autoremove --dry-run

# 移除不再需要的依賴
brew autoremove
```

<br>

## iTerm2 設定：<br>

本腳本會自動匯入 iTerm2 配置檔，預設使用 `new_tuffy_iterm2_setting.json`。

### 使用不同的配置檔

修改 `install.sh` 中的 `PROFILE_FILE` 變數（第 322 行）：

```bash
PROFILE_FILE="你的配置檔名.json"
```

可選配置檔：

- `new_tuffy_iterm2_setting.json` - 整合版（大視窗 + Nerd Font）
- `Tuffy.json` - 原始 Tuffy 配置
- `pin-yi.json` - 原始 pin-yi 配置

### 匯出自己的 iTerm2 設定

1. [ ]  開啟 iTerm2
2. [ ]  進入 **iTerm2 → Preferences** (⌘,)
3. [ ]  切換到 **Profiles** 標籤
4. [ ]  點擊左下角 **Other Actions...** (⋯)
5. [ ]  選擇 **Save Profile as JSON...**
6. [ ]  存檔後放到此專案目錄，並修改 `PROFILE_FILE` 變數

<br>

## 備註：<br>

1. 需要查詢能夠安裝的套件與應用程式，可以到 [brew.sh](https://brew.sh/index_zh-tw) 查詢。
2. 查看已安裝 brew_tap_array 的套件，可以使用 `brew tap`。
3. 查看已安裝 brew_array 的套件，可以使用 `brew list`。
4. 查看已安裝 brew_cask 的應用程式，可以使用 `brew list --cask`。
5. 搜尋特定套件是否已安裝，可以使用 `brew list | grep 套件名稱`。

<br>

## 排除錯誤：<br>

由於該腳本是 For 給新電腦要設定環境時的一鍵安裝腳本，若以你已經用其他方式安裝過相同的程式或套件，可能會遇到以下圖片錯誤。

當我們遇到時，可以使用以下方式來解決，我們這邊用 docker 為例，我先使用網站的安裝檔案來安裝 docker，先從應用程式中刪除 docker，改用腳本來跑，會看到有紅字的錯誤訊息說 `Error: It seems there is already a Binary at 'XXX'.`，代表雖然把程式本身刪除，但他對應的檔案還在，所以我們要把它們都刪除，才能重新安裝。

![img](https://i.imgur.com/dcMLOpE.png)

docker 的對應檔案有這些：<br>
(超級多，所以建議一開始就使用 shell script 來安裝，不要用網站的安裝檔案來安裝)

![img](https://i.imgur.com/wY5z8oC.png)

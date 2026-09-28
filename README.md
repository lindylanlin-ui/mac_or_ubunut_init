# mac-or-ubuntu-init

用幾個簡單的 Shell 腳本，快速建立 macOS、Ubuntu 或 Zorin 的常用工作環境。

## 快速開始

先複製專案並進入目錄：

```bash
git clone <repository-url>
cd mac_or_ubunut_init
```

接著依照作業系統和用途，選擇一個入口腳本執行。第一次使用建議先閱讀腳本開頭的套件清單與設定開關。

### macOS

```bash
# 日常版
bash ./install.sh

# 工程師版
bash ./install-engineer.sh
```

### Ubuntu / Zorin

```bash
# 日常版
bash ./install-linux.sh

# 工程師版
bash ./install-linux-engineer.sh
```

Linux 腳本會使用 `sudo`，請先確認目前帳號有 sudo 權限。所有版本都需要網路連線；macOS 會安裝或使用 Homebrew，Linux 會使用 apt、snap 及部分官方下載來源。

## 瀏覽器與 VS Code

批次版與選單版都提供以下選項：

- macOS：Chrome、Brave、Firefox、Microsoft Edge 與 Visual Studio Code，透過 Homebrew cask 安裝。
- Ubuntu / Zorin：Chrome、Brave、Microsoft Edge 透過官方 apt 來源安裝；Firefox 與 Visual Studio Code 使用 snap。

Linux 的 Brave 與 Edge 會加入各自的官方套件來源，之後可由 apt 接收更新。

## 選單版：自行挑選安裝內容

如果不想一次安裝整套環境，可以使用選單版。選單會以勾選方式列出套件，並在每個選項旁提供簡短的繁體中文用途說明；使用空白鍵勾選，按 Enter 確認。

### macOS

```bash
# 日常選單版
bash ./install-mac-interactive.sh

# 工程師選單版
bash ./install-mac-engineer-interactive.sh
```

### Ubuntu / Zorin

```bash
# 日常選單版
bash ./install-linux-interactive.sh

# 工程師選單版
bash ./install-linux-engineer-interactive.sh
```

第一次執行時，若系統沒有 `dialog`，腳本會先安裝它來顯示選單。Linux 選取的工具若需要 `curl`、`git`、編譯工具或其他基礎依賴，必要依賴會自動補上。

## 該選哪個腳本？

| 需求 | 入口腳本 | 內容概略 |
| --- | --- | --- |
| macOS 日常使用 | [`install.sh`](./install.sh) | Homebrew、Shell 工具、常用 GUI App、Yazi 與基本設定 |
| macOS 工程師環境 | [`install-engineer.sh`](./install-engineer.sh) | 日常版，再加上 Kubernetes、Cloud、Terraform 與 ChatGPT、Antigravity、Claude、Gemini |
| Ubuntu / Zorin 日常使用 | [`install-linux.sh`](./install-linux.sh) | apt / snap、常用 GUI 與 Shell 工具、Yazi 與基本設定 |
| Ubuntu / Zorin 工程師環境 | [`install-linux-engineer.sh`](./install-linux-engineer.sh) | 日常版，再加上 Kubernetes、Cloud、Terraform 等工具 |

`install-mac-common.sh` 與 `install-linux-common.sh` 是共用執行邏輯，不是一般使用者的入口，請不要直接執行。

## 會修改哪些設定？

腳本可能會建立或更新以下使用者設定：

- `~/.zshrc`、`~/.zprofile`、`~/.bash_profile` 或 `~/.bashrc`
- `~/.vimrc`
- `~/.config/yazi/`
- macOS 的 iTerm2 Dynamic Profile

執行前如果已有自己的 Shell 設定，建議先備份。執行完成後，重新開啟終端機，或執行：

```bash
source ~/.zshrc
```

每次執行都會在 `logs/` 產生安裝紀錄，方便查找失敗項目。

## Yazi

Yazi 設定放在 [`yazi/`](./yazi/)。安裝流程會依作業系統選擇設定，並同步到 `~/.config/yazi/`：

- macOS：[`yazi/yazi.macos.toml`](./yazi/yazi.macos.toml)，使用 `open` 開啟檔案。
- Linux：[`yazi/yazi.linux.toml`](./yazi/yazi.linux.toml)，使用 `xdg-open` 開啟檔案。
- 共用主題與快捷鍵：[`theme.toml`](./yazi/theme.toml)、[`keymap.toml`](./yazi/keymap.toml)。
- [`shell.zsh`](./yazi/shell.zsh) 讓離開 Yazi 後，終端機保留在最後瀏覽的資料夾。

若圖示顯示成方塊，請在終端機使用 Nerd Font；macOS 版本會安裝 Meslo Nerd Font。

## 自訂安裝內容

通常只需要修改對應的入口腳本：

- macOS：修改 [`install.sh`](./install.sh) 或 [`install-engineer.sh`](./install-engineer.sh) 的 `brew_array`、`brew_cask` 與 `ENABLE_*` 開關。
- Linux：修改 [`install-linux.sh`](./install-linux.sh) 或 [`install-linux-engineer.sh`](./install-linux-engineer.sh) 的 apt、snap、手動安裝清單與 `ENABLE_*` 開關。

共用流程需要調整時，才修改 [`install-mac-common.sh`](./install-mac-common.sh) 或 [`install-linux-common.sh`](./install-linux-common.sh)。

## 專案檔案

- 批次安裝入口：[`install.sh`](./install.sh)、[`install-engineer.sh`](./install-engineer.sh)、[`install-linux.sh`](./install-linux.sh)、[`install-linux-engineer.sh`](./install-linux-engineer.sh)
- 選單安裝入口：[`install-mac-interactive.sh`](./install-mac-interactive.sh)、[`install-mac-engineer-interactive.sh`](./install-mac-engineer-interactive.sh)、[`install-linux-interactive.sh`](./install-linux-interactive.sh)、[`install-linux-engineer-interactive.sh`](./install-linux-engineer-interactive.sh)
- 選單共用工具：[`install-interactive-common.sh`](./install-interactive-common.sh)
- macOS iTerm2 設定：[`new_tuffy_iterm2_setting.json`](./new_tuffy_iterm2_setting.json)
- Vim 設定：[`vimrc.txt`](./vimrc.txt)
- Shell 範本：[`zshrc-template.txt`](./zshrc-template.txt)、[`zshrc-linux-template.zsh`](./zshrc-linux-template.zsh)、[`zshrc-zorin-template.txt`](./zshrc-zorin-template.txt)
- Git alias 範例：[`git_lg.txt`](./git_lg.txt)

以下檔案不是目前四個入口腳本的必要依賴，保留作為參考或舊版備份：[`Tuffy.json`](./Tuffy.json)、[`yazi_install_sh.zip`](./yazi_install_sh.zip)。目前 macOS 腳本使用的是 `new_tuffy_iterm2_setting.json`。

## 安全注意事項

目前檢查 Git 追蹤內容，沒有發現常見的 API key、access token、密碼、私鑰或 kubeconfig。這不代表未來新增檔案時可以省略檢查，請注意：

- 不要提交 `.env`、雲端憑證、SSH 私鑰、VPN 設定、`~/.kube/config` 或包含密碼的 log。
- `logs/` 已加入 `.gitignore`；若某個敏感檔案已經被 Git 追蹤，單純加入 `.gitignore` 不會把它移出版本庫。
- 安裝腳本會從 Homebrew、GitHub、Google、HashiCorp 等來源下載套件或安裝腳本，並可能使用 `sudo`。正式使用前請確認來源與腳本內容。
- 推送前至少確認：

  ```bash
  git status --short
  git diff --cached
  ```

若曾經把憑證提交到 GitHub，請立即撤銷／輪替憑證，並另外清理 Git 歷史；刪除檔案本身並不足夠。

## 常用 Homebrew 指令（macOS）

```bash
brew list
brew list --cask
brew search <套件名稱>
brew uninstall <套件名稱>
brew uninstall --cask <應用程式名稱>
brew cleanup
```

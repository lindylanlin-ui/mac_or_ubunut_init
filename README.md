# mac-install

用 shell script 快速建立 macOS / Ubuntu / Zorin 的常用環境。

目前已拆成多個入口腳本，重點是把「一般日常使用」和「工程師工作環境」分開，避免一支腳本同時安裝太多不相干的東西。

## 腳本總覽

### macOS

- [install.sh](/Users/tuffy330_lin/tuffy_temp_data/mac-install/install.sh)
  日常版。適合一般使用者或只需要基礎 shell 強化的人。
- [install-engineer.sh](/Users/tuffy330_lin/tuffy_temp_data/mac-install/install-engineer.sh)
  工程師版。包含日常版內容，再加上 Kubernetes / Cloud / Terraform 相關工具。
- [install-mac-common.sh](/Users/tuffy330_lin/tuffy_temp_data/mac-install/install-mac-common.sh)
  macOS 共用核心。通常不直接執行。

### Linux

- [install-linux.sh](/Users/tuffy330_lin/tuffy_temp_data/mac-install/install-linux.sh)
  Ubuntu / Zorin 日常版安裝腳本。
- [install-linux-engineer.sh](/Users/tuffy330_lin/tuffy_temp_data/mac-install/install-linux-engineer.sh)
  Ubuntu / Zorin 工程師版安裝腳本。
- [install-linux-common.sh](/Users/tuffy330_lin/tuffy_temp_data/mac-install/install-linux-common.sh)
  Linux 共用核心。通常不直接執行。

## 推薦使用情境


| 使用情境                      | 推薦腳本                    | 原因                                                                    |
| ----------------------------- | --------------------------- | ----------------------------------------------------------------------- |
| 一般日常使用的 Mac            | `install.sh`                | 保留 Homebrew、iTerm2、oh-my-zsh 與基礎工具，不會安裝過多工程師專用工具 |
| 工程師工作用的 Mac            | `install-engineer.sh`       | 除了日常環境外，還會補齊 Kubernetes、Cloud、Terraform 相關工具與設定    |
| Ubuntu / Zorin 一般日常使用   | `install-linux.sh`          | 安裝 Linux 日常環境與基礎 GUI / shell 設定，不會帶入太多工程師專用工具  |
| Ubuntu / Zorin 工程師工作環境 | `install-linux-engineer.sh` | 會再補上 Kubernetes、Terraform、GCloud、Helm 類工具與設定               |
| 不確定該用哪個 mac 腳本       | `install.sh`                | 日常版風險較低，安裝內容比較精簡，適合先從這版開始                      |

## 使用方式

### macOS 日常版

```bash
chmod +x install.sh
./install.sh
```

### macOS 工程師版

```bash
chmod +x install-engineer.sh
./install-engineer.sh
```

### Linux 日常版

```bash
chmod +x install-linux.sh
./install-linux.sh
```

### Linux 工程師版

```bash
chmod +x install-linux-engineer.sh
./install-linux-engineer.sh
```

## macOS 版本差異

### 日常版 install.sh

會安裝這類內容：

- Homebrew 本體
- 基礎 CLI 工具：`zsh`、`bash-completion`、`jq`、`shellcheck`、`wget`、`telnet`、`tree`、`fzf`、`pv`、`dialog`、`yq`、`webp`、`autojump`
- GUI App：`google-chrome`、`iterm2`、`visual-studio-code`、`raycast`、`openvpn-connect`、`wireguard`、`drawio`
- shell 強化：`oh-my-zsh`、`fzf-tab`、`zsh-autosuggestions`、`zsh-syntax-highlighting`
- 設定項：`PS1 prompt`、`.vimrc` 設定、iTerm2 profile 匯入

### 工程師版 install-engineer.sh

在日常版基礎上，另外會安裝或設定：

- Kubernetes / Cloud / IaC 工具
- `helm diff`
- `kubecolor`
- `gke-gcloud-auth-plugin`
- `slidev`
- `terraform` / `vault` / `aws` autocomplete
- `kubectl` / `kubens` / `kubectx` alias

## Linux 版本差異

### 日常版 install-linux.sh

會安裝這類內容：

- 基礎 CLI 工具：`zsh`、`bash-completion`、`jq`、`shellcheck`、`wget`、`telnet`、`tree`、`fzf`、`pv`、`dialog`、`webp`
- GUI / 桌面工具：`code`、`drawio`、`google-chrome`
- VPN / 網路：`wireguard`、`openvpn`、`network-manager-openvpn-gnome`
- shell 強化：`oh-my-zsh`、`fzf-tab`、`zsh-autosuggestions`、`zsh-syntax-highlighting`

### 工程師版 install-linux-engineer.sh

在日常版基礎上，另外會安裝或設定：

- `kubectl`、`helm`、`kubectx`
- `terraform`、`terragrunt`
- `gcloud`
- `k9s`、`kustomize`
- `aws-cli`
- `helm diff`
- `slidev`
- `gke-gcloud-auth-plugin`
- `autojump`

## Log 與執行結果

所有腳本都會自動建立 `logs/` 資料夾。

log 位置：

- macOS 日常版：`logs/install-mac-daily-時間戳.log`
- macOS 工程師版：`logs/install-mac-engineer-時間戳.log`
- Linux 日常版：`logs/install-linux-daily-時間戳.log`
- Linux 工程師版：`logs/install-linux-engineer-時間戳.log`

腳本執行結束後，畫面會直接列出：

- 本次安裝成功
- 原本已安裝或已設定
- 略過項目
- 找不到套件來源
- 安裝或設定失敗

如果安裝失敗，log 內會保留錯誤摘要。

## 自訂安裝內容

### macOS

如果你只想調整要安裝哪些 Homebrew 套件或 App，優先看入口腳本最上方：

- [install.sh](/Users/tuffy330_lin/tuffy_temp_data/mac-install/install.sh)
- [install-engineer.sh](/Users/tuffy330_lin/tuffy_temp_data/mac-install/install-engineer.sh)

主要變數：

- `brew_tap_array`
- `brew_array`
- `brew_cask`

主要功能開關：

- `ENABLE_OH_MY_ZSH`
- `ENABLE_FZF_TAB`
- `ENABLE_ZSH_AUTOSUGGESTIONS`
- `ENABLE_ZSH_SYNTAX_HIGHLIGHTING`
- `ENABLE_AUTOJUMP`
- `ENABLE_PS1`
- `ENABLE_VIMRC`
- `ENABLE_ITERM2_PROFILE`
- `ENABLE_KUBECOLOR`
- `ENABLE_SLIDEV`
- `ENABLE_HELM_DIFF`
- `ENABLE_GKE_GCLOUD_AUTH_PLUGIN`
- `ENABLE_TERRAFORM_AUTOCOMPLETE`
- `ENABLE_VAULT_AUTOCOMPLETE`
- `ENABLE_AWS_AUTOCOMPLETE`
- `ENABLE_K8S_ALIASES`

原則上：

- 只改日常版，就編輯 `install.sh`
- 只改工程師版，就編輯 `install-engineer.sh`
- 不建議直接改 `install-mac-common.sh`，除非你要調整共用執行邏輯

### Linux

Linux 版主要修改：

- `apt_prereq_array`
- `apt_array`
- `snap_array`
- `snap_classic_array`
- `manual_install_array`
- `unsupported_app_array`
- `ENABLE_ENGINEER_FEATURES`
- `ENABLE_AUTOJUMP`
- `ENABLE_SLIDEV`
- `ENABLE_HELM_DIFF`

## iTerm2 設定

macOS 腳本會匯入 [new_tuffy_iterm2_setting.json](/Users/tuffy330_lin/tuffy_temp_data/mac-install/new_tuffy_iterm2_setting.json)。

目前這份 profile 已調整成較可攜版本：

- `Working Directory` 不再綁定特定使用者路徑
- 字型改成較通用的 `Menlo-Regular 16`

如果要換成別的 JSON，請修改 [install-mac-common.sh](/Users/tuffy330_lin/tuffy_temp_data/mac-install/install-mac-common.sh) 內 `configure_iterm2_profile` 使用的檔名。

### 匯出自己的 iTerm2 設定

1. 開啟 iTerm2
2. 進入 `iTerm2 -> Preferences`
3. 切換到 `Profiles`
4. 點左下角 `Other Actions...`
5. 選 `Save Profile as JSON...`
6. 把檔案放到本專案目錄，再調整腳本引用

## 查詢與移除套件

### 查詢

```bash
brew search 套件名稱
brew search --cask 應用程式名稱
brew tap
brew list
brew list --cask
```

### 移除 CLI 套件

```bash
brew uninstall 套件名稱
```

### 移除 GUI App

```bash
brew uninstall --cask 應用程式名稱
brew uninstall --cask --zap 應用程式名稱
```

### 清理

```bash
brew cleanup
brew autoremove --dry-run
brew autoremove
```

## 備註

- macOS 可安裝套件可到 `brew.sh` 查詢
- Linux 腳本主要針對 Ubuntu / Zorin
- 第一次執行建議先看入口腳本上方的陣列與 `ENABLE_*` 開關是否符合需求

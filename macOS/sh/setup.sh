#!/usr/bin/env bash
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Logging
LOG_FILE="/tmp/setup_$(date +%Y%m%d_%H%M%S).log"
INSTALLED=()
SKIPPED=()
FAILED=()

log() { echo "[$(date +%H:%M:%S)] $*" >> "$LOG_FILE"; }
info() { echo -e "${BLUE}[INFO]${NC} $*"; log "INFO: $*"; }
ok() { echo -e "${GREEN}[OK]${NC} $*"; log "OK: $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; log "WARN: $*"; }
err() { echo -e "${RED}[ERROR]${NC} $*"; log "ERROR: $*"; }

# Ask y/n, $1=prompt, $2=default (y/n)
ask() {
    local prompt="$1" default="${2:-y}"
    local hint="Y/n"
    [[ "$default" == "n" ]] && hint="y/N"
    echo -en "${CYAN}?${NC} ${prompt} [${hint}]: "
    read -r ans
    ans="${ans:-$default}"
    [[ "${ans,,}" == "y" ]]
}

command_exists() { command -v "$1" &>/dev/null; }

# ── Phase 1: Prerequisites ──────────────────────────────────────────

echo -e "\n${BOLD}══════════════════════════════════════${NC}"
echo -e "${BOLD}  macOS Setup Script${NC}"
echo -e "${BOLD}══════════════════════════════════════${NC}\n"

info "Log file: $LOG_FILE"

# Xcode CLT
if xcode-select -p &>/dev/null; then
    ok "Xcode Command Line Tools already installed"
else
    info "Installing Xcode Command Line Tools..."
    xcode-select --install 2>/dev/null || true
    echo "Press any key after Xcode CLT installation completes..."
    read -rsn1
fi

# Homebrew
if command_exists brew; then
    ok "Homebrew already installed"
else
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add brew to PATH for Apple Silicon
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
fi

brew update >> "$LOG_FILE" 2>&1

# ── Phase 2: Interactive Menu ────────────────────────────────────────

echo -e "\n${BOLD}── Shell Configuration ──${NC}"
INSTALL_OMZ=false
INSTALL_P10K=false
ask "Oh My Zsh + plugins" "y" && INSTALL_OMZ=true
ask "Powerlevel10k theme" "y" && INSTALL_P10K=true

echo -e "\n${BOLD}── Dev Tools (brew install) ──${NC}"
DEV_TOOLS=(git wget curl tree jq htop tmux neovim)
SELECTED_DEV=()
for tool in "${DEV_TOOLS[@]}"; do
    ask "$tool" "y" && SELECTED_DEV+=("$tool")
done
INSTALL_NVM=false
INSTALL_PYTHON=false
INSTALL_OPENCLAW=false
ask "node (via nvm)" "y" && INSTALL_NVM=true
ask "python3" "y" && INSTALL_PYTHON=true
ask "openclaw" "y" && INSTALL_OPENCLAW=true

echo -e "\n${BOLD}── Apps (brew cask) ──${NC}"
declare -A CASK_APPS=(
    ["Google Chrome"]="google-chrome"
    ["Firefox"]="firefox"
    ["Visual Studio Code"]="visual-studio-code"
    ["iTerm2"]="iterm2"
    ["Docker"]="docker"
    ["Postman"]="postman"
    ["Raycast"]="raycast"
    ["Rectangle"]="rectangle"
    ["WeChat"]="wechat"
    ["Telegram"]="telegram"
    ["Ghostty"]="ghostty"
)
SELECTED_CASKS=()
for name in "Google Chrome" "Firefox" "Visual Studio Code" "iTerm2" "Ghostty" "Docker" "Postman" "Raycast" "Rectangle" "WeChat" "Telegram"; do
    ask "$name" "y" && SELECTED_CASKS+=("${CASK_APPS[$name]}")
done

echo -e "\n${BOLD}── Fonts ──${NC}"
FONTS=(font-fira-code-nerd-font font-meslo-lg-nerd-font)
SELECTED_FONTS=()
for font in "${FONTS[@]}"; do
    ask "$font" "y" && SELECTED_FONTS+=("$font")
done

# ── Phase 3: Install ─────────────────────────────────────────────────

echo -e "\n${BOLD}── Installing... ──${NC}\n"

brew_install() {
    local pkg="$1"
    if brew list "$pkg" &>/dev/null; then
        ok "$pkg already installed"
        SKIPPED+=("$pkg")
    else
        info "Installing $pkg..."
        if brew install "$pkg" >> "$LOG_FILE" 2>&1; then
            ok "$pkg installed"
            INSTALLED+=("$pkg")
        else
            err "Failed to install $pkg"
            FAILED+=("$pkg")
        fi
    fi
}

cask_install() {
    local pkg="$1"
    if brew list --cask "$pkg" &>/dev/null; then
        ok "$pkg already installed"
        SKIPPED+=("$pkg")
    else
        info "Installing $pkg..."
        if brew install --cask "$pkg" >> "$LOG_FILE" 2>&1; then
            ok "$pkg installed"
            INSTALLED+=("$pkg")
        else
            err "Failed to install $pkg"
            FAILED+=("$pkg")
        fi
    fi
}

# Shell
if $INSTALL_OMZ; then
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        ok "Oh My Zsh already installed"
        SKIPPED+=("oh-my-zsh")
    else
        info "Installing Oh My Zsh..."
        RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" >> "$LOG_FILE" 2>&1
        INSTALLED+=("oh-my-zsh")
    fi
    ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    declare -A OMZ_PLUGINS=(
        ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions"
        ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting"
        ["zsh-completions"]="https://github.com/zsh-users/zsh-completions"
    )
    for plugin in zsh-autosuggestions zsh-syntax-highlighting zsh-completions; do
        dest="$ZSH_CUSTOM/plugins/$plugin"
        if [[ -d "$dest" ]]; then
            ok "$plugin already installed"
            SKIPPED+=("$plugin")
        else
            info "Installing $plugin..."
            if git clone "${OMZ_PLUGINS[$plugin]}" "$dest" >> "$LOG_FILE" 2>&1; then
                ok "$plugin installed"
                INSTALLED+=("$plugin")
            else
                err "Failed to install $plugin"
                FAILED+=("$plugin")
            fi
        fi
    done
fi

if $INSTALL_P10K; then
    ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    dest="$ZSH_CUSTOM/themes/powerlevel10k"
    if [[ -d "$dest" ]]; then
        ok "Powerlevel10k already installed"
        SKIPPED+=("powerlevel10k")
    else
        info "Installing Powerlevel10k..."
        if git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$dest" >> "$LOG_FILE" 2>&1; then
            ok "Powerlevel10k installed"
            INSTALLED+=("powerlevel10k")
        else
            err "Failed to install Powerlevel10k"
            FAILED+=("powerlevel10k")
        fi
    fi
fi

# Dev tools
for pkg in "${SELECTED_DEV[@]}"; do
    brew_install "$pkg"
done

if $INSTALL_NVM; then
    if [[ -d "$HOME/.nvm" ]]; then
        ok "nvm already installed"
        SKIPPED+=("nvm")
    else
        info "Installing nvm..."
        if curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash >> "$LOG_FILE" 2>&1; then
            ok "nvm installed"
            INSTALLED+=("nvm")
            export NVM_DIR="$HOME/.nvm"
            # shellcheck source=/dev/null
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
            info "Installing latest Node.js LTS..."
            nvm install --lts >> "$LOG_FILE" 2>&1 && ok "Node.js LTS installed"
        else
            err "Failed to install nvm"
            FAILED+=("nvm")
        fi
    fi
fi

if $INSTALL_PYTHON; then
    brew_install python3
fi

if $INSTALL_OPENCLAW; then
    brew_install openclaw
fi

# Cask apps
for pkg in "${SELECTED_CASKS[@]}"; do
    cask_install "$pkg"
done

# Fonts
if [[ ${#SELECTED_FONTS[@]} -gt 0 ]]; then
    for font in "${SELECTED_FONTS[@]}"; do
        cask_install "$font"
    done
fi

# ── Summary ──────────────────────────────────────────────────────────

echo -e "\n${BOLD}══════════════════════════════════════${NC}"
echo -e "${BOLD}  Summary${NC}"
echo -e "${BOLD}══════════════════════════════════════${NC}"
[[ ${#INSTALLED[@]} -gt 0 ]] && echo -e "${GREEN}Installed (${#INSTALLED[@]}):${NC} ${INSTALLED[*]}"
[[ ${#SKIPPED[@]} -gt 0 ]]   && echo -e "${YELLOW}Skipped (${#SKIPPED[@]}):${NC} ${SKIPPED[*]}"
[[ ${#FAILED[@]} -gt 0 ]]    && echo -e "${RED}Failed (${#FAILED[@]}):${NC} ${FAILED[*]}"
echo -e "\nFull log: ${LOG_FILE}"
echo -e "${GREEN}Done!${NC}\n"

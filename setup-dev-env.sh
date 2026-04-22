#!/usr/bin/env zsh
# =============================================================================
#  Dev Environment Setup — New Employee Onboarding
#  Installs: Homebrew · pipx · poetry · nvm · node · pnpm · VS Code extensions
#  Configures: .zshrc · VS Code settings · Monaspace fonts · Git · GitHub
# =============================================================================

set -e

# ── Colours ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo "${BLUE}▸${RESET} $*"; }
success() { echo "${GREEN}✔${RESET} $*"; }
warn()    { echo "${YELLOW}⚠${RESET}  $*"; }
fail()    { echo "${RED}✘ ERROR:${RESET} $*"; exit 1; }
section() {
  echo ""
  echo "${BOLD}══════════════════════════════════════${RESET}"
  echo "${BOLD} $*${RESET}"
  echo "${BOLD}══════════════════════════════════════${RESET}"
}

# ── Guard: macOS + zsh ────────────────────────────────────────────────────────
[[ "$OSTYPE" == darwin* ]] || fail "This script is macOS-only."
[[ -n "$ZSH_VERSION" ]]   || warn "Not running in zsh — some steps may behave differently."

ZSHRC="$HOME/.zshrc"
touch "$ZSHRC"

# Helper: append a block to .zshrc only once (keyed on marker string)
append_zshrc() {
  local marker="$1"; local block="$2"
  grep -qF "$marker" "$ZSHRC" || printf '\n%s\n' "$block" >> "$ZSHRC"
}

# =============================================================================
section "1 · Xcode Command Line Tools"
# =============================================================================
if ! xcode-select -p &>/dev/null; then
  info "Installing Xcode CLT (a system prompt will appear — click Install)…"
  xcode-select --install
  echo ""
  echo "  Once the installer finishes, re-run this script to continue."
  exit 0
else
  success "Xcode CLT already installed"
fi

# =============================================================================
section "2 · Homebrew"
# =============================================================================
if ! command -v brew &>/dev/null; then
  info "Installing Homebrew…"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Apple Silicon path bootstrap
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    append_zshrc "# Homebrew" 'eval "$(/opt/homebrew/bin/brew shellenv)"'
  fi
else
  success "Homebrew already installed ($(brew --version | head -1))"
fi
brew update --quiet

# =============================================================================
section "3 · pipx"
# =============================================================================
if ! command -v pipx &>/dev/null; then
  info "Installing pipx…"
  brew install pipx
  pipx ensurepath
else
  success "pipx already installed ($(pipx --version))"
fi

append_zshrc "# Local bin first" \
'# Local bin first
export PATH="$HOME/.local/bin:$PATH"'

# =============================================================================
section "4 · Poetry"
# =============================================================================
if ! command -v poetry &>/dev/null; then
  info "Installing poetry via pipx…"
  pipx install poetry
else
  success "Poetry already installed ($(poetry --version))"
fi

info "Configuring Poetry globals…"
poetry config virtualenvs.in-project true        # .venv lives inside the project

# Attempt prefer-active-python (Poetry 1.x only — silently ignored on 2.x)
poetry config virtualenvs.prefer-active-python true 2>/dev/null || true

success "Poetry configured"

# =============================================================================
section "5 · nvm · Node LTS · pnpm"
# =============================================================================

# ── nvm ───────────────────────────────────────────────────────────────────────
if ! brew list nvm &>/dev/null 2>&1; then
  info "Installing nvm via Homebrew…"
  brew install nvm
fi
mkdir -p "$HOME/.nvm"

export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && . "/opt/homebrew/opt/nvm/nvm.sh"

append_zshrc "# --- nvm (Homebrew) ---" \
'# --- nvm (Homebrew) ---
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && . "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && . "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"'

# ── Node LTS ──────────────────────────────────────────────────────────────────
if ! command -v node &>/dev/null; then
  info "Installing Node LTS…"
  nvm install --lts
  nvm alias default 'lts/*'
else
  success "Node already installed ($(node --version))"
fi

# ── pnpm ──────────────────────────────────────────────────────────────────────
if ! command -v pnpm &>/dev/null; then
  info "Installing pnpm…"
  npm install -g pnpm
else
  success "pnpm already installed ($(pnpm --version))"
fi

append_zshrc "# pnpm" \
'# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end'

# ── Project-local binaries + auto-nvmrc hook ──────────────────────────────────
append_zshrc "# Project-local node binaries" \
'# Project-local node binaries
export PATH="./node_modules/.bin:$PATH"

# Auto-switch Node via .nvmrc
autoload -U add-zsh-hook
load-nvmrc() {
  local nvmrc_path
  nvmrc_path="$(nvm_find_nvmrc)"
  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version
    nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")
    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
      nvm use
    fi
  elif [ -n "$(PWD=$OLDPWD nvm_find_nvmrc)" ] && [ "$(nvm version)" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc'

# =============================================================================
section "6 · Git identity & GitHub"
# =============================================================================

# ── Global git config ─────────────────────────────────────────────────────────
CURRENT_GIT_NAME=$(git config --global user.name 2>/dev/null || true)
CURRENT_GIT_EMAIL=$(git config --global user.email 2>/dev/null || true)

if [[ -z "$CURRENT_GIT_NAME" ]]; then
  printf "${BLUE}?${RESET} Your full name for git commits (e.g. Jane Smith): "
  read GIT_NAME
  git config --global user.name "$GIT_NAME"
else
  success "git user.name already set: $CURRENT_GIT_NAME"
  GIT_NAME="$CURRENT_GIT_NAME"
fi

if [[ -z "$CURRENT_GIT_EMAIL" ]]; then
  printf "${BLUE}?${RESET} Your work email for git commits: "
  read GIT_EMAIL
  git config --global user.email "$GIT_EMAIL"
else
  success "git user.email already set: $CURRENT_GIT_EMAIL"
  GIT_EMAIL="$CURRENT_GIT_EMAIL"
fi

# Sensible global git defaults
git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global core.editor "code --wait"    # VS Code as default git editor
git config --global core.autocrlf input

success "Global git config applied"

# ── SSH key for GitHub ────────────────────────────────────────────────────────
SSH_KEY="$HOME/.ssh/id_ed25519"

if [[ -f "$SSH_KEY" ]]; then
  success "SSH key already exists at $SSH_KEY"
else
  info "Generating a new ed25519 SSH key…"
  ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$SSH_KEY" -N ""
  success "SSH key generated"
fi

# Ensure ssh-agent has the key loaded
eval "$(ssh-agent -s)" > /dev/null 2>&1
ssh-add --apple-use-keychain "$SSH_KEY" 2>/dev/null || ssh-add "$SSH_KEY" 2>/dev/null || true

# macOS: persist key in Keychain via ~/.ssh/config
SSH_CONFIG="$HOME/.ssh/config"
if ! grep -q "UseKeychain" "$SSH_CONFIG" 2>/dev/null; then
  mkdir -p "$HOME/.ssh"
  cat >> "$SSH_CONFIG" << 'SSHCONF'

Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
SSHCONF
  chmod 600 "$SSH_CONFIG"
  success "~/.ssh/config updated for GitHub"
fi

# ── Copy public key + prompt employee to add it ───────────────────────────────
pbcopy < "${SSH_KEY}.pub"
echo ""
echo "${BOLD}──────────────────────────────────────────────────────────────────${RESET}"
echo "${BOLD} ACTION REQUIRED: Add your SSH key to GitHub${RESET}"
echo "${BOLD}──────────────────────────────────────────────────────────────────${RESET}"
echo ""
echo "  Your public key has been copied to the clipboard."
echo ""
echo "  1. Open  ${BLUE}https://github.com/settings/ssh/new${RESET}"
echo "     (create a free account first if you don't have one)"
echo "  2. Title: something like \"Work MacBook $(date +%Y)\""
echo "  3. Key type: Authentication Key"
echo "  4. Paste the key (⌘V) and click Add SSH key"
echo ""
printf "${BLUE}?${RESET} Press Enter once you've added the key to GitHub… "
read _

# Verify the connection
info "Testing GitHub SSH connection…"
if ssh -T git@github.com -o StrictHostKeyChecking=accept-new 2>&1 | grep -q "successfully authenticated"; then
  success "GitHub SSH connection verified"
else
  warn "Could not verify GitHub connection automatically."
  warn "Run  ssh -T git@github.com  after setup to confirm."
fi

# ── GitHub CLI ────────────────────────────────────────────────────────────────
if ! command -v gh &>/dev/null; then
  info "Installing GitHub CLI (gh)…"
  brew install gh
else
  success "GitHub CLI already installed ($(gh --version | head -1))"
fi

echo ""
info "Logging into GitHub CLI (a browser window will open)…"
gh auth login --hostname github.com --git-protocol ssh --web || \
  warn "gh login skipped — run  gh auth login  later if needed."

# =============================================================================
section "7 · Monaspace Fonts"
# =============================================================================
FONT_DIR="$HOME/Library/Fonts"
if ls "$FONT_DIR"/Monaspace* &>/dev/null 2>&1; then
  success "Monaspace fonts already installed"
else
  info "Downloading Monaspace font family…"
  TMP_FONTS=$(mktemp -d)
  curl -fsSL \
    "https://github.com/githubnext/monaspace/releases/download/v1.101/monaspace-v1.101.zip" \
    -o "$TMP_FONTS/monaspace.zip"
  unzip -q "$TMP_FONTS/monaspace.zip" -d "$TMP_FONTS/"
  find "$TMP_FONTS" \( -name "*.otf" -o -name "*.ttf" \) | while read -r f; do
    cp "$f" "$FONT_DIR/"
  done
  rm -rf "$TMP_FONTS"
  success "Monaspace fonts installed to ~/Library/Fonts"
fi

# =============================================================================
section "8 · VS Code CLI + Extensions"
# =============================================================================
if ! command -v code &>/dev/null; then
  CODE_BIN="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
  if [[ -f "$CODE_BIN" ]]; then
    info "Registering VS Code 'code' CLI…"
    append_zshrc "# VS Code CLI" \
      'export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"'
    export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
  else
    warn "VS Code not found. Install from https://code.visualstudio.com then re-run."
  fi
else
  success "VS Code CLI available"
fi

if command -v code &>/dev/null; then
  info "Installing VS Code extensions…"

  EXTENSIONS=(
    # ── Icons ───────────────────────────────────────
    "PKief.material-icon-theme"
    # ── Formatting ──────────────────────────────────
    "esbenp.prettier-vscode"
    "charliermarsh.ruff"
    # ── Python ──────────────────────────────────────
    "ms-python.python"
    "ms-python.vscode-pylance"
    # ── Node / JS / TS ──────────────────────────────
    "dbaeumer.vscode-eslint"
    "christian-kohler.npm-intellisense"
    # ── RST / Docs ──────────────────────────────────
    "lextudio.restructuredtext"
    # ── Git ─────────────────────────────────────────
    "eamodio.gitlens"
    "github.vscode-pull-request-github"
    # ── General DX ──────────────────────────────────
    "editorconfig.editorconfig"
    "streetsidesoftware.code-spell-checker"
  )

  for ext in "${EXTENSIONS[@]}"; do
    if code --list-extensions 2>/dev/null | grep -qi "^${ext}$"; then
      success "  already installed: $ext"
    else
      info "  installing: $ext"
      code --install-extension "$ext" --force 2>/dev/null && \
        success "  installed:  $ext" || \
        warn    "  failed:     $ext  (install manually if needed)"
    fi
  done
fi

# =============================================================================
section "9 · VS Code User Settings"
# =============================================================================
VSCODE_SETTINGS_DIR="$HOME/Library/Application Support/Code/User"
mkdir -p "$VSCODE_SETTINGS_DIR"
SETTINGS_FILE="$VSCODE_SETTINGS_DIR/settings.json"

if [[ -f "$SETTINGS_FILE" ]]; then
  BACKUP="$SETTINGS_FILE.backup-$(date +%Y%m%d-%H%M%S)"
  warn "Existing settings.json backed up → $BACKUP"
  cp "$SETTINGS_FILE" "$BACKUP"
fi

# Note: workbench.colorTheme is intentionally omitted — employees pick their own.
cat > "$SETTINGS_FILE" << 'SETTINGS'
{
  "editor.fontFamily": "Monaspace Argon Var",
  "editor.fontSize": 14,
  "editor.fontVariations": "'wght' 350",
  "editor.lineHeight": 0,
  "editor.linkedEditing": true,
  "editor.multiCursorModifier": "ctrlCmd",
  "editor.snippetSuggestions": "top",
  "editor.suggestSelection": "first",
  "editor.tabSize": 2,
  "editor.inlineSuggest.enabled": true,
  "editor.fontLigatures": "'calt', 'liga'",
  "editor.formatOnSave": true,
  "editor.formatOnPaste": false,
  "editor.detectIndentation": true,
  "editor.tokenColorCustomizations": {
    "textMateRules": [
      {
        "scope": ["keyword.operator", "punctuation.separator"],
        "settings": { "fontStyle": "" }
      },
      {
        "scope": ["comment", "comment.block"],
        "settings": { "fontStyle": "italic", "foreground": "#F5F" }
      },
      {
        "name": "envKeys",
        "scope": "string.quoted.double.env,source.env,constant.numeric.env",
        "settings": { "foreground": "#19354900" }
      }
    ]
  },
  "terminal.integrated.fontFamily": "Monaspace Xenon Var",
  "terminal.integrated.fontSize": 14,
  "terminal.integrated.fontWeight": 500,
  "terminal.integrated.fontWeightBold": 800,
  "terminal.integrated.lineHeight": 1.5,
  "terminal.integrated.letterSpacing": 1,
  "terminal.integrated.fontLigatures": true,
  "workbench.iconTheme": "material-icon-theme",
  "workbench.editor.labelFormat": "medium",
  "workbench.editor.showTabs": "none",
  "workbench.sideBar.location": "right",
  "workbench.startupEditor": "newUntitledFile",
  "workbench.statusBar.visible": false,
  "files.autoSave": "onWindowChange",
  "search.useIgnoreFiles": true,
  "search.exclude": {
    "**/*.code-search": true,
    "**/bower_components": true,
    "**/node_modules": true
  },
  "diffEditor.ignoreTrimWhitespace": false,
  "explorer.openEditors.visible": 1,
  "security.workspace.trust.untrustedFiles": "open",
  "git.enableSmartCommit": true,
  "git.autofetch": true,
  "git.confirmSync": false,
  "git.ignoreRebaseWarning": true,
  "python.venvPath": "~/.cache/pypoetry/virtualenvs",
  "ruff.lineLength": 80,
  "eslint.enable": true,
  "eslint.validate": ["vue", "react", "typescript", "html", "javascript"],
  "extensions.ignoreRecommendations": true,
  "extensions.autoCheckUpdates": false,
  "extensions.autoUpdate": false,
  "update.mode": "manual",
  "[css]": { "editor.defaultFormatter": "esbenp.prettier-vscode" },
  "[handlebars]": { "editor.defaultFormatter": "esbenp.prettier-vscode" },
  "[html]": { "editor.defaultFormatter": "esbenp.prettier-vscode" },
  "[javascript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.fontLigatures": "'calt', 'ss01', 'ss02', 'ss03', 'ss04', 'liga'"
  },
  "[javascriptreact]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.fontLigatures": "'calt', 'ss01', 'ss02', 'ss03', 'ss04', 'liga'"
  },
  "[json]": { "editor.defaultFormatter": "esbenp.prettier-vscode" },
  "[jsonc]": { "editor.defaultFormatter": "esbenp.prettier-vscode" },
  "[markdown]": { "editor.defaultFormatter": "esbenp.prettier-vscode" },
  "[scss]": { "editor.defaultFormatter": "esbenp.prettier-vscode" },
  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.fontLigatures": "'calt', 'ss01', 'ss02', 'ss03', 'ss04', 'liga'"
  },
  "[typescriptreact]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.fontLigatures": "'calt', 'ss01', 'ss02', 'ss03', 'ss04', 'liga'"
  },
  "[csv]": {
    "editor.fontFamily": "Charis SIL",
    "editor.fontSize": 14,
    "editor.lineHeight": 1.5,
    "editor.fontLigatures": true
  },
  "[python]": {
    "editor.fontLigatures": "'calt', 'ss01', 'ss02', 'ss03', 'liga'"
  },
  "[go]": { "editor.fontLigatures": false },
  "[rust]": {
    "editor.fontLigatures": "'calt', 'ss01', 'ss02', 'ss03', 'ss08', 'ss09', 'liga'"
  },
  "window.zoomLevel": 0,
  "python.defaultInterpreterPath": "/opt/homebrew/bin/python3",
  "files.exclude": { "**/__pycache__": true },
  "python-envs.terminal.autoActivationType": "off",
  "explorer.confirmDelete": false,
  "js/ts.updateImportsOnFileMove.enabled": "always",
  "diffEditor.maxComputationTime": 0,
  "workbench.secondarySideBar.defaultVisibility": "hidden"
}
SETTINGS
success "VS Code settings.json written (theme left unset — pick your own!)"

# =============================================================================
section "10 · pnew — Poetry new-project helper"
# =============================================================================
# Installs a `pnew <project-name>` shell function that:
#   1. Runs `poetry new <name>`
#   2. Appends the team ruff config + Celonis package source to pyproject.toml
#   3. Runs `poetry add --group dev ruff` so ruff is present from day one

append_zshrc "# pnew — poetry new with team defaults" \
'# pnew — poetry new with team defaults
pnew() {
  if [[ -z "$1" ]]; then
    echo "Usage: pnew <project-name>"
    return 1
  fi
  poetry new "$1" && cd "$1" || return 1
  cat >> pyproject.toml << '"'"'TOML'"'"'

[tool.ruff]
line-length = 80
exclude = [
  ".venv",
  "__pycache__",
]

[tool.ruff.format]
quote-style = "single"
indent-style = "tab"
docstring-code-format = true

[tool.ruff.lint]
select = [
    "E",
    "F",
    "UP",
    "B",
    "SIM",
    "I",
]

[[tool.poetry.source]]
name = "celonis"
url = "https://pypi.celonis.cloud/"
priority = "supplemental"
TOML
  poetry add --group dev ruff
  echo "✔ Project $1 ready with team defaults."
}'

success "pnew helper added to ~/.zshrc"

# =============================================================================
section "All done!"
# =============================================================================
echo ""
echo "${GREEN}${BOLD}Setup complete.${RESET} Next steps:"
echo ""
echo "  1. ${BOLD}Restart your terminal${RESET} or run:  ${BLUE}source ~/.zshrc${RESET}"
echo ""
echo "  2. ${BOLD}Pick a VS Code theme${RESET} — press ⌘K ⌘T inside VS Code."
echo "     Popular picks: One Dark Pro · Catppuccin · Tokyo Night · GitHub Theme"
echo ""
echo "  3. ${BOLD}Starting a new Python project?${RESET}"
echo "     Use ${BLUE}pnew my-project-name${RESET} instead of  poetry new."
echo "     It injects the team ruff config and Celonis source automatically."
echo ""
echo "  4. ${BOLD}Adding pycelonis to an existing project:${RESET}"
echo "     ${BLUE}poetry source add --priority supplemental celonis https://pypi.celonis.cloud/${RESET}"
echo "     ${BLUE}poetry add pycelonis${RESET}"
echo ""
echo "  5. ${BOLD}Charis SIL${RESET} (CSV font, optional):"
echo "     https://software.sil.org/charis/"
echo ""
echo "${BLUE}Happy coding!${RESET}"
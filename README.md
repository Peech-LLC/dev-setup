# dev-setup

## Before you start — get Claude to help you

The easiest way to get set up is to let Claude walk you through the whole
process. Before you have GitHub access or any dev tools installed, you can still
load Claude's instructions directly in your browser:

1. Open **[claude.ai](https://claude.ai)** and start a new conversation
2. Open this link and select all the text (`⌘A`), then copy it (`⌘C`):
   **[raw.githubusercontent.com/your-org/dev-setup/main/CLAUDE.md](https://raw.githubusercontent.com/your-org/dev-setup/main/CLAUDE.md)**
3. Paste it (`⌘V`) into the Claude conversation and send it
4. Claude will take it from there — just follow its instructions

> **No GitHub account yet?** That's fine. Claude knows you're starting from
> scratch and will help you create one during setup.

If you'd rather just run the script yourself without Claude, continue below.

---

## Manual setup

New here? One command gets your machine ready.

```bash
zsh <(curl -fsSL https://raw.githubusercontent.com/your-org/dev-setup/main/setup-dev-env.sh)
```

> Run this in Terminal on your first day. It takes about 5–10 minutes and will
> pause to ask for your name, email, and one manual step to add an SSH key to
> GitHub. Everything else is automatic.

---

## What it installs

| Tool | Purpose |
|---|---|
| **Homebrew** | macOS package manager |
| **pipx** | Isolated Python tool installs |
| **Poetry** | Python dependency & virtualenv management |
| **nvm + Node LTS** | Node version manager + current LTS release |
| **pnpm** | Fast Node package manager |
| **Monaspace** | Editor & terminal font family |
| **VS Code extensions** | Ruff, Prettier, Pylance, ESLint, GitLens, and more |

## What it configures

- **`.zshrc`** — Homebrew path, pipx path, nvm init, pnpm, project-local `node_modules/.bin`, and auto-switching Node versions via `.nvmrc`
- **Poetry** — `virtualenvs.in-project true` so `.venv` always lives inside your project (VS Code picks it up automatically)
- **Git** — your name, email, `main` as the default branch, VS Code as the default editor
- **GitHub** — generates an ed25519 SSH key, walks you through adding it to GitHub, and installs + authenticates the `gh` CLI
- **VS Code `settings.json`** — team-standard fonts, ligatures, format-on-save, language-specific formatters

## Starting a new Python project

Use `pnew` instead of `poetry new`:

```bash
pnew my-project-name
```

This runs `poetry new`, then automatically appends the team ruff config and
the Celonis package source to `pyproject.toml`, and adds ruff as a dev
dependency. You're linting-ready before you write a single line of code.

### Adding pycelonis to an existing project

```bash
poetry source add --priority supplemental celonis https://pypi.celonis.cloud/
poetry add pycelonis
```

## After the script finishes

1. **Restart your terminal** (or `source ~/.zshrc`)
2. **Pick a VS Code theme** — press `⌘K ⌘T` and choose whatever you like
3. **Charis SIL font** — only needed if you work with CSV files in VS Code: https://software.sil.org/charis/

## Re-running the script

The script is safe to re-run at any time. Every install step checks whether the
tool already exists before doing anything, and `.zshrc` blocks are only appended
once. Useful if a step failed mid-way, or if we've updated the script since your
first run.

## VS Code extensions installed

| Extension | Purpose |
|---|---|
| `PKief.material-icon-theme` | File icons |
| `esbenp.prettier-vscode` | JS/TS/CSS/HTML formatter |
| `charliermarsh.ruff` | Python linter & formatter |
| `ms-python.python` | Python language support |
| `ms-python.vscode-pylance` | Python type checking |
| `dbaeumer.vscode-eslint` | JavaScript/TypeScript linting |
| `christian-kohler.npm-intellisense` | npm module autocomplete |
| `lextudio.restructuredtext` | RST / Sphinx docs |
| `eamodio.gitlens` | Git blame, history, and more |
| `github.vscode-pull-request-github` | PRs and issues inside VS Code |
| `editorconfig.editorconfig` | Consistent editor config across projects |
| `streetsidesoftware.code-spell-checker` | Spell checking in code and comments |

## Linting standards

All Python projects use [Ruff](https://docs.astral.sh/ruff/) with these settings
(injected automatically by `pnew`, or paste into an existing `pyproject.toml`):

```toml
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
    "E",    # pycodestyle
    "F",    # Pyflakes
    "UP",   # pyupgrade
    "B",    # flake8-bugbear
    "SIM",  # flake8-simplify
    "I",    # isort
]
```

---

## Updating this script

Make changes to `setup-dev-env.sh`, commit to `main`, and add an entry to
`CHANGELOG.md`. New hires will always pull the latest version via curl. For
significant changes, consider tagging a release so there's a clear reference
point.

## Requirements

- macOS (Apple Silicon or Intel)
- An internet connection
- Terminal running zsh (the macOS default since Catalina)

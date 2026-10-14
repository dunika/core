# Core

Shared macOS shell, keyboard, and editor configuration for personal and work
laptops. Core contains reusable aliases and Git helpers, Zsh plugins and setup,
the Powerlevel10k theme, Karabiner mappings, and optional VS Code preferences.

## Quick setup

Install [Homebrew](https://brew.sh/) first, then the shell dependencies:

```sh
brew install powerlevel10k zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search fzf
brew install --cask font-hack-nerd-font font-fira-code
```

These packages are available from [Homebrew](https://formulae.brew.sh/formula/powerlevel10k).
Set your terminal font to **Hack Nerd Font**; the VS Code preferences use
**Fira Code** for the editor and **Hack Nerd Font** for the terminal.

Clone the standalone Core repository, replacing `REPOSITORY_URL` with its clone
URL. Include submodules to fetch [enhancd](https://github.com/b4b4r07/enhancd):

```sh
git clone --recurse-submodules REPOSITORY_URL "$HOME/core"
bash "$HOME/core/zsh/_core/setup.sh"
```

Start a new terminal. The setup script appends a source line to
`${ZDOTDIR:-$HOME}/.zshrc`, backs up an existing file, and leaves its contents
intact. Running it again does not duplicate the line. It creates no symlinks.

For another startup file, pass its path:

```sh
bash "$HOME/core/zsh/_core/setup.sh" "$HOME/.config/zsh/.zshrc"
```

If the clone missed its submodule, run `git -C "$HOME/core" submodule update --init`.

## Manual setup

Instead of running the script, add this to your existing `.zshrc`:

```zsh
source "$HOME/core/zsh/.zshrc"
```

Use the actual checkout path if Core lives elsewhere. Keep laptop-specific
aliases, work exports, and credentials in your local startup file, after the
Core source line when you want them to override shared defaults. Shell history
and completion caches stay in your local Zsh directory, outside Core.

The optional early environment file can be sourced from your existing
`.zshenv` if you use Volta or Rust:

```zsh
source "$HOME/core/zsh/.zshenv"
```

## What is shared

| Files | Purpose |
| --- | --- |
| `zsh/_core/aliases.sh` | Reload, system info, and npm/pnpm validation shortcuts |
| `zsh/_core/git.sh`, `git_functions.sh` | Git shortcuts and helpers; run `git_help` |
| `zsh/.zshrc`, `.p10k.zsh`, `zsh/enhancd` | Shell setup, theme, and directory navigation |
| `zsh/_core/setup.sh` | Backed-up, repeatable setup of the source line |
| `karabiner.json` | Caps Lock Hyper, Vim navigation, and Control-Backspace mappings |
| `settings.json` | Optional VS Code editor, terminal, formatting, and language preferences |

Homebrew supplies autosuggestions, syntax highlighting, history substring
search, and Powerlevel10k. enhancd is an upstream Git submodule. Volta, Bun,
Rust, Ruby, npm, pnpm, and `neofetch` are optional; their shortcuts need the
corresponding tools installed.

Some Git shortcuts change history: `gc` stages files when nothing is staged,
commits, and pushes with `--force-with-lease`; `grm` squashes, rebases, and
pushes rewritten history. Review `git_help` before using these shortcuts.

## Keyboard and editor preferences

Install [Karabiner-Elements](https://karabiner-elements.pqrs.org/) if you want
the keyboard mappings. Back up your existing configuration before copying
`karabiner.json` to `~/.config/karabiner/karabiner.json`. The file includes
overrides for several keyboard models; adjust them for the work laptop.

For VS Code, open **Preferences: Open User Settings (JSON)** and merge the
preferences from `settings.json`. Choose the settings you want to share with
the work laptop rather than replacing its entire configuration.

## Inside CPU

CPU uses Core at `core/` as a submodule. Its startup files source Core by path;
CPU-specific launchers, work configuration, backups, and history remain in CPU.
Commit changes in Core first, then stage `core` in CPU to record the new commit.

The CPU submodule URL is currently local-only. Set it to Core's separate remote
before using CPU on another machine. Select a license before public release.

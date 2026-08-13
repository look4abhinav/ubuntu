# Ubuntu Server Setup Automation

A one-command setup that transforms a minimal Ubuntu server into a fully configured development environment: Zsh, GNU Stow-managed dotfiles, Docker, Neovim, and modern CLI tools.

## Overview

This repo orchestrates the installation and ships its own Ubuntu-specific dotfiles in `dotfiles/`. These are copied to `~/dotfiles` and stowed from there (mirroring the Arch setup's layout, but kept completely separate from it).

## Features

- **System update** via apt
- **Zsh** installed and set as the default shell
- **Dotfiles** bundled in `dotfiles/`, copied to `~/dotfiles`, and stowed (left untouched on re-runs)
- **Docker** from the official repo, service enabled, user added to the `docker` group
- **CLI tools**: `eza`, `fzf`, `fd`, `neovim`, `tmux`, `uv`, `zoxide`, `bat` (+ Catppuccin themes), `ripgrep`, `shellcheck`, `shfmt`
- **Modular**: every tool is installable independently

## Prerequisites

- Ubuntu (recent LTS), non-root user with `sudo`, internet access, Bash.

## Quick Start

One-liner (clones to a temp dir, runs setup, cleans up):

```bash
curl -sL https://setup.look4abhinav.in | bash
```

Or manually:

```bash
git clone https://github.com/look4abhinav/ubuntu
cd ubuntu
bash setup.sh
```

Run individual tools with `bash tools/<tool>.sh`.

## Project Structure

```
ubuntu/
├── install.sh      # one-liner bootstrap
├── setup.sh        # main orchestration script
├── lib.sh          # shared helpers (logging, guarded apt update)
├── README.md
├── dotfiles/       # Ubuntu-specific configs (copied to ~/dotfiles and stowed)
└── tools/          # one script per tool
    ├── stow.sh     # copies dotfiles to ~/dotfiles and stows
    ├── zsh.sh
    ├── bat.sh
    ├── docker.sh
    ├── eza.sh
    ├── fd.sh
    ├── fzf.sh
    ├── neovim.sh
    ├── tmux.sh
    ├── uv.sh
    └── zoxide.sh
```

Dotfiles are bundled in `dotfiles/` and stowed from `~/dotfiles` (same layout as the Arch setup, but a separate set of configs).

## Customization

- **Add a tool**: drop `foo.sh` in `tools/` and append `foo` to the `tools` array in `setup.sh`.
- **Change dotfiles**: edit `dotfiles/` in this repo (or `~/dotfiles` after setup), then `stow -d ~/dotfiles -t ~ .`. Re-running `setup.sh` will not overwrite an existing `~/dotfiles`.

## Notes

- Scripts use `set -euo pipefail` and refuse to run as root.
- `apt-get update` runs once per setup (30-minute guard) even though each tool is a separate process.
- Adding the user to the `docker` group takes effect after re-login (or `newgrp docker`).
- Tool installers never edit shell rc files; PATH and shell integration are managed by the stowed `.zshrc`.

## License

MIT

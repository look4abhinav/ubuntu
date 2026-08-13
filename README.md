# Ubuntu Server Setup Automation

A one-command setup that transforms a minimal Ubuntu server into a fully configured development environment: Zsh, GNU Stow-managed dotfiles, Docker, Neovim, and modern CLI tools.

## Overview

This repo orchestrates the installation while the [dotfiles repo](https://github.com/look4abhinav/dotfiles) holds the actual configuration. That repo is shared with the Arch Linux setup, so a single `.zshrc`/`.gitconfig`/Neovim/Tmux configuration drives both machines.

## Features

- **System update** via apt
- **Zsh** installed and set as the default shell
- **Dotfiles** cloned from `look4abhinav/dotfiles` to `~/dotfiles` and stowed (never updated automatically after first run)
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
└── tools/          # one script per tool
    ├── stow.sh     # clones dotfiles to ~/dotfiles and stows
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

Dotfiles live in the separate [dotfiles](https://github.com/look4abhinav/dotfiles) repo, stowed from `~/dotfiles` (same layout as the Arch setup).

## Customization

- **Add a tool**: drop `foo.sh` in `tools/` and append `foo` to the `tools` array in `setup.sh`.
- **Change dotfiles**: edit `~/dotfiles` directly, then `stow -d ~/dotfiles -t ~ .`. Re-running `setup.sh` will not touch your dotfiles.

## Notes

- Scripts use `set -euo pipefail` and refuse to run as root.
- `apt-get update` runs once per setup (30-minute guard) even though each tool is a separate process.
- Adding the user to the `docker` group takes effect after re-login (or `newgrp docker`).
- Tool installers never edit shell rc files; PATH and shell integration are managed by the stowed `.zshrc`.

## License

MIT

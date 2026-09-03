# Ubuntu Server Setup Automation

A one-command setup that transforms a minimal Ubuntu server into a fully configured development environment: Zsh, GNU Stow-managed dotfiles, Docker, Neovim, and modern CLI tools.

## Overview

This repo orchestrates the installation. The Ubuntu-specific dotfiles live in a separate repo ([`ubuntu-dotfiles`](https://github.com/look4abhinav/ubuntu-dotfiles)), which is cloned into `~/dotfiles` and stowed from there.

## Features

- **System update** via apt
- **Zsh** installed and set as the default shell
- **Dotfiles** cloned from [`ubuntu-dotfiles`](https://github.com/look4abhinav/ubuntu-dotfiles) into `~/dotfiles`, then stowed
- **Docker** from the official repo, service enabled, user added to the `docker` group
- **CLI tools**: `eza`, `fzf`, `fd`, `neovim`, `tmux`, `uv`, `zoxide`, `bat` (+ Catppuccin themes), `ripgrep`, `shellcheck`, `shfmt`
- **Modular**: every tool is installable independently

## Prerequisites

- Ubuntu (recent LTS), non-root user with `sudo`, internet access, Bash.
- Architecture: `x86_64` (amd64) or `aarch64` (arm64). Neovim and its formatters
  are installed from GitHub release binaries that are only published for these
  two architectures; all other tools are architecture-agnostic (apt packages or
  official installers that auto-detect the platform).

## Quick Start

One-liner (clones to a temp dir, runs setup, cleans up):

```bash
curl -sL https://look4abhinav.in/ubuntu | bash
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
    ├── stow.sh     # clones ubuntu-dotfiles to ~/dotfiles and stows
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

Dotfiles live in the separate [`ubuntu-dotfiles`](https://github.com/look4abhinav/ubuntu-dotfiles) repo and are cloned into `~/dotfiles` and stowed from there.

## Customization

- **Add a tool**: drop `foo.sh` in `tools/` and append `foo` to the `tools` array in `setup.sh`.
- **Change dotfiles**: edit the [`ubuntu-dotfiles`](https://github.com/look4abhinav/ubuntu-dotfiles) repo (or `~/dotfiles` after setup), then `stow -d ~/dotfiles -t ~ .`. Re-running `setup.sh` pulls updates if `~/dotfiles` is the `ubuntu-dotfiles` repo, otherwise it leaves `~/dotfiles` untouched.

## Notes

- Scripts use `set -euo pipefail` and refuse to run as root.
- `apt-get update` runs once per setup (30-minute guard) even though each tool is a separate process.
- Adding the user to the `docker` group takes effect after re-login (or `newgrp docker`).
- Tool installers never edit shell rc files; PATH and shell integration are managed by the stowed `.zshrc`.

## License

MIT

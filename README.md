# Ubuntu VPS Setup Automation

A comprehensive automated setup script for configuring a fresh Ubuntu server with modern development tools and shell configurations.

## Overview

This project provides a one-command setup to transform a minimal Ubuntu server into a fully configured development environment. It automates the installation and configuration of essential tools, development utilities, and shell customizations.

## Features

- ✅ **System Update**: Automatic apt package manager update and upgrade
- ✅ **Zsh Shell**: Installation and configuration of Zsh with modern shell features
- ✅ **Dotfiles Management**: Automated deployment using GNU Stow
- ✅ **Docker**: Complete Docker installation with user group configuration
- ✅ **Modern CLI Tools**:
  - `bat` - Modern replacement for `cat` with syntax highlighting
  - `eza` - Modern replacement for `ls` with better colors and icons
  - `fzf` - Command-line fuzzy finder for enhanced terminal navigation
  - `Neovim` - Modern vim-based text editor
  - `Tmux` - Terminal multiplexer for session management
  - `uv` - Fast Python package installer
  - `Zoxide` - Smarter `cd` command with learning capabilities
- ✅ **Modular Architecture**: Each tool is installable independently

## Prerequisites

- **OS**: Ubuntu (tested on recent LTS versions)
- **Access**: Root/sudo privileges required for system-level installations
- **Network**: Internet connection for package downloads
- **Shell**: Bash (used for script execution)

## Project Structure

```
ubuntu/
├── .gitignore         # Git ignore rules
├── README.md          # This file
├── setup.sh           # Main orchestration script
├── lib/               # Shared libraries
│   └── utils.sh       # Utility functions (logging, checks)
├── dotfiles/          # Configuration files (stow packages)
│   └── [config files]
└── tools/             # Individual tool installation scripts
    ├── docker.sh      # Docker installation
    ├── eza.sh         # eza CLI tool installation
    ├── fzf.sh         # fzf fuzzy finder installation
    ├── neovim.sh      # Neovim editor installation
    ├── stow.sh        # GNU Stow installation (invoked by setup.sh)
    ├── tmux.sh        # Tmux multiplexer installation
    ├── uv.sh          # uv Python package manager installation
    ├── zoxide.sh      # Zoxide smart cd installation
    └── zsh.sh         # Zsh shell installation
```

## Installation

### Quick Start

Run the complete setup with one command:

```bash
git clone https://github.com/look4abhinav/ubuntu
cd ubuntu
bash setup.sh
```

### Individual Tool Installation

You can run individual tool scripts, but ensure `lib/utils.sh` is accessible (the scripts expect it in `../lib/`):

```bash
# Install only Docker
bash ./tools/docker.sh

# Install only Zsh with configurations
bash ./tools/zsh.sh
```

## Usage

### After Installation

1. **Shell Restart**: You may need to restart your shell or start a new terminal session
   ```bash
   zsh
   ```

2. **Log Out and Back In**: For some changes (like default shell or docker group), you may need to fully log out and back in

3. **Verify Installation**: Check that tools are properly installed
   ```bash
   zsh --version
   docker --version
   nvim --version
   tmux -V
   fzf --version
   eza --version
   zoxide --version
   uv --version
   ```

## Customization

### Modifying Dotfiles

Dotfiles are managed in `./dotfiles/`. To customize:

1. Modify files in the `dotfiles` directory
2. Run `tools/stow.sh` (or let `setup.sh` handle it) to deploy changes
3. The setup script will automatically backup conflicts

### Adding New Tools

To add a new tool installation script:

1. Create a new script in `./tools/` (e.g., `newtool.sh`)
2. Make sure it sources `../lib/utils.sh` for helpers.
3. Make it executable (`chmod +x tools/newtool.sh`).
4. The `setup.sh` script will automatically find and run it (no need to edit an array).

## Troubleshooting

### Script Execution Issues

- Ensure the script has execute permissions:
  ```bash
  chmod +x ./setup.sh
  chmod +x ./tools/*.sh
  ```

- Run with bash explicitly:
  ```bash
  bash ./setup.sh
  ```

### Individual Tool Issues

- Check internet connectivity for package downloads
- Verify sudo privileges: `sudo -v`
- Check system logs for specific error messages

### Shell Configuration Issues

- Ensure Zsh is properly installed: `zsh --version`
- Check `.zshrc` configuration in home directory
- Restart shell session or log out/in

## System Requirements

- **Minimum RAM**: 512 MB (512 MB minimum, 1 GB+ recommended)
- **Minimum Disk Space**: 2 GB free space
- **Ubuntu Version**: 18.04 LTS or newer (tested with 20.04 LTS, 22.04 LTS, 24.04 LTS)

## Safety Notes

⚠️ **Important**:
- This script uses `set -e` to exit on any error
- System package upgrades are enabled and may restart services
- Adding user to docker group has security implications - use on trusted systems only
- Review the scripts before running on production systems
- Create system snapshots/backups before running on critical servers

## Contributing

Contributions are welcome! To contribute:

1. Test scripts thoroughly on a fresh Ubuntu instance
2. Ensure compatibility with recent Ubuntu LTS versions
3. Follow existing script conventions and style
4. Add comments for complex operations
5. Update this README with any new tools or features

## License

[Add your license here - e.g., MIT, GPL-3.0, etc.]

## Support

For issues or questions:

1. Check existing GitHub issues
2. Review script contents and comments
3. Test individual tool scripts in isolation
4. Provide output logs when reporting issues

## Future Enhancements

Potential additions for future versions:

- [ ] Non-interactive mode with configuration file support
- [ ] Tool selection/deselection during setup
- [ ] Configuration templates for different use cases
- [ ] Rollback functionality
- [ ] Support for other Linux distributions (Debian, Fedora, etc.)
- [ ] Automated backup of existing configurations
- [ ] Installation verification tests

## Additional Resources

- **GNU Stow**: https://www.gnu.org/software/stow/
- **Zsh**: https://www.zsh.org/
- **Neovim**: https://neovim.io/
- **Docker**: https://docs.docker.com/
- **fzf**: https://github.com/junegunn/fzf
- **Tmux**: https://github.com/tmux/tmux
- **Zoxide**: https://github.com/ajeetdsoutn/zoxide

---

**Last Updated**: February 2026

**Maintainer**: [Abhinav Srivastava]

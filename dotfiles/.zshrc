# =============================================================================
# 1. INSTANT PROMPT & ENVIRONMENT
# =============================================================================
# Enable Powerlevel10k instant prompt.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# PATH: fzf (~/.fzf), uv/formatters (~/.local/bin), Neovim (/opt/nvim-linux)
export PATH="$PATH:$HOME/.fzf/bin:$HOME/.local/bin:/opt/nvim-linux/bin"
export EDITOR='nvim'

if [[ -d "$HOME/.opencode/bin" ]]; then
  export PATH="$PATH:$HOME/.opencode/bin"
fi

# =============================================================================
# 2. ZINIT PACKAGE MANAGER
# =============================================================================
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname "$ZINIT_HOME")"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# =============================================================================
# 3. THEME & PLUGINS
# =============================================================================
zinit ice depth=1; zinit light romkatv/powerlevel10k

# Defer OMZ snippets
zinit wait lucid for \
    OMZL::git.zsh \
    OMZP::git \
    OMZP::gh \
    OMZP::sudo \
    OMZP::ubuntu \
    OMZP::uv \
    OMZP::aws \
    OMZP::python \
    OMZP::command-not-found

# Defer heavy plugins & completions
zinit wait lucid for \
    atinit"zicompinit; zicdreplay" \
        zsh-users/zsh-completions \
        Aloxaf/fzf-tab \
    atload"!_zsh_autosuggest_start" \
        zsh-users/zsh-autosuggestions \
    atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" \
        zsh-users/zsh-syntax-highlighting

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# =============================================================================
# 4. HISTORY
# =============================================================================
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# =============================================================================
# 5. KEYBINDINGS
# =============================================================================
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region
bindkey ' ' magic-space
bindkey -s '^Ga' 'git add .'
bindkey -s '^Gc' 'git commit -m ""\C-b'

# =============================================================================
# 6. COMPLETION STYLING
# =============================================================================
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -alh $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -alh $realpath'

# =============================================================================
# 7. ALIASES
# =============================================================================
alias nv='nvim'
alias c='clear'
alias ls='eza -alh'
alias up='sudo apt update; sudo apt upgrade -y'
alias ca='clear; :> ~/.zsh_history'
alias path='print -l -- ${(s/:/)PATH}'
alias zrc='nv ~/.zshrc && exec zsh'
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias upy='UV_NO_MODIFY_PATH=1 uv self update; uv tool upgrade --all'
alias pyc='fd -H -I "^(__pycache__|\.ruff_cache|\.pytest_cache|\.mypy_cache|\.ipynb_checkpoints|\.eggs|\.tox)$|\.(egg-info|egg|pyc|pyo)$" -X rm -rf'

# =============================================================================
# 8. CACHED SHELL INTEGRATIONS (fzf, zoxide, uv)
# =============================================================================
# Generate each integration once (fast startup) and only when the tool is
# installed; never leave a stale/empty cache file behind.
EVAL_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh_evals"
mkdir -p "$EVAL_CACHE_DIR"

if (( $+commands[fzf] )) && [[ ! -f "$EVAL_CACHE_DIR/fzf.zsh" ]]; then
  fzf --zsh > "$EVAL_CACHE_DIR/fzf.zsh" 2>/dev/null || rm -f "$EVAL_CACHE_DIR/fzf.zsh"
fi
[[ -f "$EVAL_CACHE_DIR/fzf.zsh" ]] && source "$EVAL_CACHE_DIR/fzf.zsh"

if (( $+commands[zoxide] )) && [[ ! -f "$EVAL_CACHE_DIR/zoxide.zsh" ]]; then
  zoxide init --cmd cd zsh > "$EVAL_CACHE_DIR/zoxide.zsh" 2>/dev/null || rm -f "$EVAL_CACHE_DIR/zoxide.zsh"
fi
[[ -f "$EVAL_CACHE_DIR/zoxide.zsh" ]] && source "$EVAL_CACHE_DIR/zoxide.zsh"

if (( $+commands[uv] )) && [[ ! -f "$EVAL_CACHE_DIR/uv.zsh" ]]; then
  uv generate-shell-completion zsh > "$EVAL_CACHE_DIR/uv.zsh" 2>/dev/null || rm -f "$EVAL_CACHE_DIR/uv.zsh"
fi
[[ -f "$EVAL_CACHE_DIR/uv.zsh" ]] && source "$EVAL_CACHE_DIR/uv.zsh"

# =============================================================================
# 9. HOOKS
# =============================================================================
chpwd() {
    emulate -L zsh
    if [[ -n "$VIRTUAL_ENV" ]]; then
        local env_root="${VIRTUAL_ENV:h}"
        if [[ "$PWD" != "$env_root"* ]]; then
            deactivate
        fi
    fi

    local venv_name=".venv"
    if [[ -d "$venv_name" ]]; then
        local absolute_venv_path="$PWD/$venv_name"
        if [[ "$VIRTUAL_ENV" == "$absolute_venv_path" ]]; then
            return
        fi
        source "$venv_name/bin/activate"
    fi
}

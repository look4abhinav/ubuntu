# =============================================================================
# 1. INSTANT PROMPT & ENVIRONMENT
# =============================================================================
# Enable Powerlevel10k instant prompt.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# PATH modifications
export PATH="$PATH:$HOME/.local/bin:/opt/nvim-linux/bin"

# =============================================================================
# 2. ZINIT PACKAGE MANAGER
# =============================================================================
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# =============================================================================
# 3. THEME & PLUGINS
# =============================================================================

zinit ice depth=1; zinit light romkatv/powerlevel10k

# Defer OMZ Snippets
zinit wait lucid for \
    OMZL::git.zsh \
    OMZP::git \
    OMZP::gh \
    OMZP::sudo \
    OMZP::ubuntu \
    OMZP::aws \
    OMZP::python \
    OMZP::command-not-found

# Defer Heavy Plugins & Completions 
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
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}"'
alias upy='uv self update; uv tool upgrade --all'
alias pyc='find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null && find . -type d -name .ruff_cache -exec rm -rf {} + 2>/dev/null'

# =============================================================================
# 8. CACHED INTEGRATIONS
# =============================================================================

mkdir -p "$HOME/.cache/zsh_integrations"

if [[ ! -f "$HOME/.cache/zsh_integrations/fzf.zsh" ]]; then
    fzf --zsh > "$HOME/.cache/zsh_integrations/fzf.zsh"
fi
source "$HOME/.cache/zsh_integrations/fzf.zsh"

if [[ ! -f "$HOME/.cache/zsh_integrations/zoxide.zsh" ]]; then
    zoxide init --cmd cd zsh > "$HOME/.cache/zsh_integrations/zoxide.zsh"
fi
source "$HOME/.cache/zsh_integrations/zoxide.zsh"

if [[ ! -f "$HOME/.cache/zsh_integrations/uv.zsh" ]]; then
    uv generate-shell-completion zsh > "$HOME/.cache/zsh_integrations/uv.zsh"
fi
source "$HOME/.cache/zsh_integrations/uv.zsh"

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

# ~/.zshrc

# ─── 1) PATH ────────────────────────────────────────────────────────────────
# put Homebrew Python 3.13 at the front
export PATH="/opt/homebrew/opt/python@3.13/libexec/bin:$PATH"


# ─── 2) ZSH OPTION “FISH-LIKE” CONVENIENCES ────────────────────────────────
setopt AUTO_CD               # auto-cd: type a directory name and cd into it
setopt CORRECT               # autocorrect: fix minor typos in commands
setopt SHARE_HISTORY         # share history across all sessions immediately
setopt HIST_IGNORE_ALL_DUPS  # ignore duplicate history entries
setopt EXTENDED_GLOB         # extended globbing (fish-style ⟨…⟩ wildcards)


# ─── 3) HISTORY ─────────────────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000


# ─── 4) COMPLETION ──────────────────────────────────────────────────────────
autoload -Uz compinit
compinit


# ─── 5) SYNTAX HIGHLIGHTING & AUTOSUGGESTIONS ─────────────────────────────
# (brew install zsh-syntax-highlighting zsh-autosuggestions)
if [ -r /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
if [ -r /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi


# ─── 6) PROMPT (“PURE” OR POWERLEVEL10K) ────────────────────────────────────
# (brew install romkatv/powerlevel10k/powerlevel10k)
if type p10k >&/dev/null; then
  # Powerlevel10k installed via Homebrew
  if [ -r /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme ]; then
    source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme
  fi
  [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
elif type promptinit >&/dev/null; then
  autoload -Uz promptinit; promptinit
  prompt pure
else
  # fallback: simple fish-like prompt
  setopt PROMPT_SUBST
  PROMPT='%F{cyan}%n@%m%f:%F{yellow}%~%f %F{green}»%f '
fi


# ─── 7) PLUGINS & ALIASES ───────────────────────────────────────────────────
# autojump (brew install autojump)
if [ -f /opt/homebrew/etc/profile.d/autojump.sh ]; then
  source /opt/homebrew/etc/profile.d/autojump.sh
fi

# handy aliases
alias ll='ls -lh'
alias la='ls -lha'
alias gs='git status'
alias gl='git log --oneline --graph --decorate'


# ─── 8) KEYBINDINGS ─────────────────────────────────────────────────────────
bindkey -v  # vi-style editing


# EOF


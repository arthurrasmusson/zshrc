# ~/.zshrc

# ─── 1) PATH ────────────────────────────────────────────────────────────────
# put Homebrew Python 3.13 at the front
export PATH="/opt/homebrew/opt/python@3.13/libexec/bin:$PATH"


# ─── 2) ZSH OPTION “FISH-LIKE” CONVENIENCES ────────────────────────────────
# auto-cd: type a directory name and you’ll cd into it
setopt AUTO_CD
# autocorrect: fix minor typos in commands
setopt CORRECT
# share history across all sessions immediately
setopt SHARE_HISTORY
# ignore duplicate history entries
setopt HIST_IGNORE_ALL_DUPS
# extended globbing (fish ⟨…⟩-style wildcards)
setopt EXTENDED_GLOB


# ─── 3) HISTORY ─────────────────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000


# ─── 4) COMPLETION ──────────────────────────────────────────────────────────
autoload -Uz compinit
compinit


# ─── 5) SYNTAX HIGHLIGHTING & AUTOSUGGESTIONS ─────────────────────────────
# (install via Homebrew: brew install zsh-syntax-highlighting zsh-autosuggestions)
if [ -r /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

if [ -r /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi


# ─── 6) PROMPT (“PURE”-STYLE) ───────────────────────────────────────────────
# (you can install via: brew install romkatv/powerlevel10k/powerlevel10k)
if type p10k >&/dev/null; then
  # if you use Powerlevel10k…
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
[ -r /opt/homebrew/share/autojump/autojump.zsh ] && source /opt/homebrew/share/autojump/autojump.zsh

# handy aliases
alias ll='ls -lh'
alias la='ls -lha'
alias gs='git status'
alias gl='git log --oneline --graph --decorate'


# ─── 8) KEYBINDINGS ─────────────────────────────────────────────────────────
# vi-style editing
bindkey -v

# EOF


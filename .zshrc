# ~/.zshrc

# ─── 1) OS DETECTION ───────────────────────────────────────────────────
case "$(uname -s)" in
  Darwin)
    ZSH_OS="macos" ;;
  Linux)
    if [ -f /etc/os-release ]; then
      . /etc/os-release
      ZSH_OS="$ID"
    else
      ZSH_OS="linux"
    fi ;;
  *)
    ZSH_OS="unknown" ;;
esac

# ─── 2) PATH ────────────────────────────────────────────────────────────
# user-local bin
export PATH="$HOME/.local/bin:$PATH"
# Homebrew Python (macOS only)
if [ "$ZSH_OS" = "macos" ]; then
  export PATH="/opt/homebrew/opt/python@3.13/libexec/bin:$PATH"
fi

# ─── 3) FISH-LIKE ZSH OPTIONS ─────────────────────────────────────────────
setopt AUTO_CD               # auto-cd: type a directory name and cd into it
setopt CORRECT               # autocorrect: fix minor typos in commands
setopt SHARE_HISTORY         # share history across all sessions immediately
setopt HIST_IGNORE_ALL_DUPS  # ignore duplicate history entries
setopt EXTENDED_GLOB         # fish-style wildcards

# ─── 4) HISTORY ───────────────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# ─── 5) COMPLETION ─────────────────────────────────────────────────────────
autoload -Uz compinit
compinit

# ─── 6) SYNTAX HIGHLIGHTING & AUTOSUGGESTIONS ─────────────────────────────
# (installed via brew or distro)
for plugin in zsh-syntax-highlighting zsh-autosuggestions; do
  if [ -r "/opt/homebrew/share/$plugin/$plugin.zsh" ]; then
    source "/opt/homebrew/share/$plugin/$plugin.zsh"
  elif [ -r "/usr/share/$plugin/$plugin.zsh" ]; then
    source "/usr/share/$plugin/$plugin.zsh"
  fi
done

# ─── 7) PROMPT (PURE OR POWERLEVEL10K) ────────────────────────────────────
if type p10k &>/dev/null; then
  # macOS brew path
  if [ -r "/opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme" ]; then
    source "/opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme"
  # common linux path
  elif [ -r "/usr/share/powerlevel10k/powerlevel10k.zsh-theme" ]; then
    source "/usr/share/powerlevel10k/powerlevel10k.zsh-theme"
  fi
  [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
elif type promptinit &>/dev/null; then
  autoload -Uz promptinit; promptinit
  prompt pure
else
  setopt PROMPT_SUBST
  PROMPT='%F{cyan}%n@%m%f:%F{yellow}%~%f %F{green}»%f '
fi

# ─── 8) AUTOJUMP ─────────────────────────────────────────────────────────
if [ "$ZSH_OS" = "macos" ]; then
  [ -f /opt/homebrew/etc/profile.d/autojump.sh ] && source /opt/homebrew/etc/profile.d/autojump.sh
else
  [ -f /etc/profile.d/autojump.sh ] && source /etc/profile.d/autojump.sh
fi

# ─── 9) ALIASES & KEYBINDINGS ─────────────────────────────────────────────
alias ll='ls -lh'
alias la='ls -lha'
alias gs='git status'
alias gl='git log --oneline --graph --decorate'
bindkey -v  # vi-mode editing

# ─── 10) ZSHTOOL: INSTALL & UPDATE ────────────────────────────────────────
zshtool() {
  local cmd="$1"
  case "$cmd" in
    install)
      case "$ZSH_OS" in
        macos)
          brew install zsh-syntax-highlighting zsh-autosuggestions romkatv/powerlevel10k/powerlevel10k autojump git ;;
        arch)
          sudo pacman -Sy --needed zsh-syntax-highlighting zsh-autosuggestions powerlevel10k autojump git ;;
        ubuntu)
          sudo apt update && sudo apt install -y zsh-syntax-highlighting zsh-autosuggestions powerlevel10k autojump git ;;
        fedora)
          sudo dnf install -y zsh-syntax-highlighting zsh-autosuggestions powerlevel10k autojump git ;;
        rhel)
          sudo yum install -y epel-release && sudo yum install -y zsh-syntax-highlighting zsh-autosuggestions powerlevel10k autojump git ;;
        gentoo)
          sudo emerge --ask app-shells/zsh-syntax-highlighting app-shells/zsh-autosuggestions app-shells/powerlevel10k app-shells/autojump dev-vcs/git ;;
        *)
          echo "Unsupported OS for install: $ZSH_OS" ;;
      esac
      ;;

    update)
      case "$ZSH_OS" in
        macos)
          brew update && brew upgrade ;;
        arch)
          sudo pacman -Syu ;;
        ubuntu)
          sudo apt update && sudo apt upgrade -y ;;
        fedora)
          sudo dnf upgrade -y ;;
        rhel)
          sudo yum update -y ;;
        gentoo)
          sudo emerge --sync && sudo emerge --update --deep @world ;;
        *)
          echo "Unsupported OS for update: $ZSH_OS" ;;
      esac
      echo "Pulling latest .zshrc..."
      git -C "$HOME/Git/zshrc" pull origin main ;;

    *)
      echo "Usage: zshtool {install|update}" ;;
  esac
}

# EOF


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

# ─── 2) PATH & ENVIRONMENT ─────────────────────────────────────────────
# user-local bins
export PATH="$HOME/.local/bin:$PATH"
# Homebrew Python (macOS)
if [ "$ZSH_OS" = "macos" ]; then
  export PATH="/opt/homebrew/opt/python@3.13/libexec/bin:$PATH"
fi
# CUDA (Linux)
if [ "$ZSH_OS" != "macos" ] && command -v nvcc &>/dev/null; then
  export CUDA_HOME="$(dirname "$(dirname "$(command -v nvcc)")")"
  export PATH="$CUDA_HOME/bin:$PATH"
  export LD_LIBRARY_PATH="$CUDA_HOME/lib64:$LD_LIBRARY_PATH"
fi

# ─── 3) FISH-LIKE ZSH OPTIONS ─────────────────────────────────────────────
setopt AUTO_CD               # auto-cd: type a directory name and cd into it
setopt CORRECT               # autocorrect: fix minor typos in commands
setopt SHARE_HISTORY         # share history across all sessions immediately
setopt HIST_IGNORE_ALL_DUPS  # ignore duplicate history entries
setopt EXTENDED_GLOB         # fish-style globbing

# ─── 4) HISTORY ───────────────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# ─── 5) COMPLETION & PLUGINS ──────────────────────────────────────────────
autoload -Uz compinit
compinit
# Syntax highlighting & autosuggestions
for plugin in zsh-syntax-highlighting zsh-autosuggestions; do
  if [ -r "/opt/homebrew/share/$plugin/$plugin.zsh" ]; then
    source "/opt/homebrew/share/$plugin/$plugin.zsh"
  elif [ -r "/usr/share/$plugin/$plugin.zsh" ]; then
    source "/usr/share/$plugin/$plugin.zsh"
  fi
done

# ─── 6) PROMPT (PURE OR POWERLEVEL10K) ────────────────────────────────────
if type p10k &>/dev/null; then
  # Homebrew path
  [ -r "/opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme" ] && source "/opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme"
  # Linux path
  [ -r "/usr/share/powerlevel10k/powerlevel10k.zsh-theme" ] && source "/usr/share/powerlevel10k/powerlevel10k.zsh-theme"
  [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
elif type promptinit &>/dev/null; then
  autoload -Uz promptinit; promptinit; prompt pure
else
  setopt PROMPT_SUBST
  PROMPT='%F{cyan}%n@%m%f:%F{yellow}%~%f %F{green}»%f '
fi

# ─── 7) AUTOJUMP ─────────────────────────────────────────────────────────
if [ "$ZSH_OS" = "macos" ]; then
  [ -f /opt/homebrew/etc/profile.d/autojump.sh ] && source /opt/homebrew/etc/profile.d/autojump.sh
elif [ -f /etc/profile.d/autojump.sh ]; then
  source /etc/profile.d/autojump.sh
fi

# ─── 8) ALIASES & KEYBINDINGS ─────────────────────────────────────────────
alias ll='ls -lh'
alias la='ls -lha'
alias gs='git status'
alias gl='git log --oneline --graph --decorate'
bindkey -v  # vi-mode editing

# ─── 9) ZSHTOOL: INSTALL, UPDATE, NVIDIA & GIT HELPERS ────────────────────
zshtool() {
  local cmd="$1" sub="$2"
  case "$cmd" in
    install)
      # core tools on all
      case "$ZSH_OS" in
        macos)
          # ensure Homebrew
          if ! command -v brew &>/dev/null; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
          fi
          brew install git python3 pip3 gcc visual-studio-code --cask veracrypt ghidra little-snitch blockblock helper
          brew install zsh-syntax-highlighting zsh-autosuggestions romkatv/powerlevel10k/powerlevel10k autojump
          ;;
        arch)
          sudo pacman -Sy --needed git python python-pip gcc code veracrypt ghidra zsh-syntax-highlighting zsh-autosuggestions powerlevel10k autojump nvidia-gds cuda nvidia-docker
          ;;
        ubuntu)
          sudo apt update && sudo apt install -y git python3 python3-pip gcc code veracrypt ghidra zsh-syntax-highlighting zsh-autosuggestions powerlevel10k autojump nvidia-gds cuda nvidia-docker2
          ;;
        fedora)
          sudo dnf install -y git python3 python3-pip gcc code veracrypt ghidra zsh-syntax-highlighting zsh-autosuggestions powerlevel10k autojump nvidia-gds cuda nvidia-docker2
          ;;
        rhel)
          sudo yum install -y epel-release && sudo yum install -y git python3 python3-pip gcc code veracrypt ghidra zsh-syntax-highlighting zsh-autosuggestions powerlevel10k autojump nvidia-gds cuda nvidia-docker2
          ;;
        gentoo)
          sudo emerge --ask dev-vcs/git dev-lang/python dev-python/pip sys-devel/gcc app-editors/vscode app-crypt/veracrypt app-forensics/ghidra app-shells/zsh-syntax-highlighting app-shells/zsh-autosuggestions app-shells/powerlevel10k app-shells/autojump nvidia-gds cuda-toolkit nvidia-docker
          ;;
        *) echo "Unsupported OS for install: $ZSH_OS" ;;
      esac
      # set up gitconfig
      cat >~/.gitconfig <<EOF
[user]
	email = arthur@vgpu.io
	name = Arthur Hanson Rasmusson
EOF
      ;;

    update)
      case "$ZSH_OS" in
        macos)
          brew update && brew upgrade
          ;;
        arch)
          sudo pacman -Syu
          ;;
        ubuntu)
          sudo apt update && sudo apt upgrade -y
          ;;
        fedora)
          sudo dnf upgrade -y
          ;;
        rhel)
          sudo yum update -y
          ;;
        gentoo)
          sudo emerge --sync && sudo emerge --update --deep @world
          ;;
        *) echo "Unsupported OS for update: $ZSH_OS" ;;
      esac
      echo "Pulling latest .zshrc..."
      git -C "$HOME/Git/zshrc" pull origin master
      ;;

    nvidia)
      case "$sub" in
        status)
          echo "Checking NVIDIA services..."
          sudo systemctl is-active nvidia-fabricmanager.service
          sudo systemctl is-active nvidia-persistenced.service
          echo "Kernel modules loaded:"
          lsmod | grep -E 'nvidia|nvidia_fs'
          echo "NVIDIA-Docker present:"
          command -v nvidia-docker || echo "nvidia-docker not found"
          echo "/etc/cufile.json:"
          [ -f /etc/cufile.json ] && echo "configured" || echo "missing"
          echo "Mellanox NICs:"
          lsmod | grep mlx5_core || echo "Mellanox driver missing"
          echo "CUDA & nvcc:"
          command -v nvcc &>/dev/null && nvcc --version || echo "nvcc not found"
          ;;

        install)
          echo "Installing NVIDIA stack..."
          zshtool install  # ensure core dependencies
          case "$ZSH_OS" in
            ubuntu|rhel|fedora)
              sudo apt install -y nvidia-gds cuda nvidia-driver nvidia-docker2
              ;;
            arch)
              sudo pacman -Sy --needed nvidia-gds cuda nvidia nvidia-docker
              ;;
            gentoo)
              sudo emerge --ask nvidia-gds cuda-toolkit nvidia-drivers nvidia-docker
              ;;
          esac
          ;;

        update)
          echo "Updating NVIDIA stack..."
          case "$ZSH_OS" in
            macos) echo "Use brew upgrade for NVIDIA packages" ;;
            ubuntu|rhel|fedora)
              sudo apt update && sudo apt upgrade -y nvidia-gds cuda nvidia-driver nvidia-docker2
              ;;
            arch)
              sudo pacman -Syu nvidia-gds cuda nvidia nvidia-docker
              ;;
            gentoo)
              sudo emerge --update --deep nvidia-gds cuda-toolkit nvidia-drivers nvidia-docker
              ;;
          esac
          ;;

        tensorrt-llm)
          if [ "$3" = init ]; then
            echo "Cloning TRT-LLM..."
            mkdir -p "$HOME/Git"
            git clone git@github.com:NVIDIA/TensorRT-LLM.git "$HOME/Git/TensorRT-LLM"
            cd "$HOME/Git/TensorRT-LLM"
            git remote rename origin nvidia
            git remote add arthurrasmusson git@github.com:arthurrasmusson/TensorRT-LLM.git
          fi
          ;;

        *) echo "Usage: zshtool nvidia {status|install|update|tensorrt-llm init}" ;;
      esac
      ;;

    git)
      if [ "$sub" = push ]; then
        echo "Committing and pushing zshrc..."
        cd "$HOME/Git/zshrc"
        git add .
        msg="$(date +'%Y-%m-%d_%H-%M-%S')"
        git commit -m "$msg"
        git push
      else
        echo "Usage: zshtool git push"
      fi
      ;;

    *)
      echo "Usage: zshtool {install|update|nvidia|git}" ;;
  esac
}

# EOF


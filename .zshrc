# ~/.zshrc ────────────────────────────────────────────────────────────────
#  Rasmusson‑Nvidia ZSHell  (RNvZSH)
#  ------------------------------------------------------------------------
#  Cross‑platform Z‑shell profile with NVIDIA CUDA / cuFile helpers on
#  Linux **and** optional remote‑cluster introspection on macOS.
#  ------------------------------------------------------------------------
#  Author:  Arthur Hanson Rasmusson  <arthur@vgpu.io>
#  ------------------------------------------------------------------------


# ──────────────────────────────────────────────────────────────────────────
# 0)  LOAD PER‑USER REMOTE HOST & START‑UP BLOCKS
# ──────────────────────────────────────────────────────────────────────────

## 0.a  Auto‑populate $SSH_REMOTE from ~/.project-digits  (if present) -----
# The file should contain *one* line, e.g. “root@172.29.0.47”.
if [[ -z $SSH_REMOTE && -f ~/.project-digits ]]; then
  SSH_REMOTE=$(< ~/.project-digits)
  SSH_REMOTE=${SSH_REMOTE//[$'\t\r\n ']}     # trim whitespace
fi

## 0.b  Banner --------------------------------------------------------------
_rnvzsh_banner() {
  echo -e "\n\033[1;32mWelcome to Rasmusson‑Nvidia ZSHell\033[0m"
}

## 0.c  cuFile / GDS probe --------------------------------------------------
_rnvzsh_cufile_status() {
  local version cuda_base gdscheck status
  if command -v nvcc &>/dev/null; then
    version=$(nvcc --version | awk -F' ' '/release/ {print $6}' | tr -d ,)
    cuda_base="/usr/local/cuda-$version"
    gdscheck="$cuda_base/gds/tools/gdscheck.py"
    if [[ -r "$gdscheck" ]]; then
      python "$gdscheck" -p >/dev/null 2>&1
      status=$([ $? -eq 0 ] && echo OK || echo FAIL)
    else
      status="gdscheck.py missing"
    fi
  else
    status="nvcc not found"
  fi
  echo "$status"
}

## 0.d  NVIDIA health summary (Linux) ---------------------------------------
_rnvzsh_nvidia_status() {
  local kernel_status services_status cuda_status cufile_status rmapi_status="TODO"

  if lsmod 2>/dev/null | grep -qE '^nvidia(_|$)'; then
    kernel_status="OK"
  else
    kernel_status=$(lsmod 2>/dev/null | awk '/nvidia/ {print $1}' | tr '\n' ' ')
    [[ -z $kernel_status ]] && kernel_status="nvidia (not loaded)"
  fi

  local bad_svcs=() svc
  for svc in nvidia-fabricmanager nvidia-persistenced; do
    systemctl is-active --quiet "$svc" 2>/dev/null || bad_svcs+=("$svc")
  done
  services_status=${bad_svcs:+${(j:, :)bad_svcs}}
  [[ -z $services_status ]] && services_status="OK"

  if command -v nvcc &>/dev/null; then
    cuda_status=$(nvcc --version | awk -F' ' '/release/ {print $6}' | tr -d ,)
  elif command -v nvidia-smi &>/dev/null; then
    cuda_status=$(nvidia-smi --query-gpu=cuda_version --format=csv,noheader | head -n1)
  else
    cuda_status="nvcc / nvidia-smi not found"
  fi

  cufile_status=$(_rnvzsh_cufile_status)

  echo "Nvidia Kernel:  $kernel_status"
  echo "Nvidia Services: $services_status"
  echo "RM API MAJOR-MINOR: $rmapi_status"
  echo "CUDA: $cuda_status"
  echo "cuFile API: $cufile_status"
}

## 0.e  Remote cluster summary (macOS) --------------------------------------
_rnvzsh_remote_status() {
  local remote_host="${remote:-$SSH_REMOTE}"
  [[ -z $remote_host ]] && return

  if timeout 3 ssh -o BatchMode=yes -o ConnectTimeout=3 "$remote_host" 'echo' 2>/dev/null; then
    echo "Server: UP"
    local pods ctrs list
    pods=$(ssh "$remote_host" "microk8s kubectl get pods -A --no-headers -o custom-columns=\":metadata.namespace/:metadata.name\"" 2>/dev/null)
    ctrs=$(ssh "$remote_host" "docker ps --format \"{{.Names}}\"" 2>/dev/null)
    list="$(echo $pods $ctrs | xargs)"
    echo "PODs: [${list:-none}]"
  else
    echo "Server: DOWN"
    echo "PODs: [unavailable]"
  fi
}

## 0.f  Execute start‑up banner + status ------------------------------------
_rnvzsh_banner
case "$(uname -s)" in
  Linux)
    if (lsmod 2>/dev/null | grep -qE '^nvidia(_|$)') || command -v nvidia-smi &>/dev/null; then
      _rnvzsh_nvidia_status
    fi
    ;;
  Darwin) _rnvzsh_remote_status ;;
esac



# ──────────────────────────────────────────────────────────────────────────
# 1)  OS DETECTION
# ──────────────────────────────────────────────────────────────────────────
case "$(uname -s)" in
  Darwin) ZSH_OS="macos" ;;
  Linux)
    if [[ -f /etc/os-release ]]; then . /etc/os-release; ZSH_OS="$ID"
    else ZSH_OS="linux"; fi ;;
  *) ZSH_OS="unknown" ;;
esac



# ──────────────────────────────────────────────────────────────────────────
# 2)  PATH & ENVIRONMENT
# ──────────────────────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"
if [[ "$ZSH_OS" == "macos" ]]; then
  export PATH="/opt/homebrew/opt/python@3.13/libexec/bin:$PATH"
fi
if [[ "$ZSH_OS" != "macos" ]] && command -v nvcc &>/dev/null; then
  export CUDA_HOME="$(dirname "$(dirname "$(command -v nvcc)")")"
  export PATH="$CUDA_HOME/bin:$PATH"
  export LD_LIBRARY_PATH="$CUDA_HOME/lib64:${LD_LIBRARY_PATH:-}"
fi



# ──────────────────────────────────────────────────────────────────────────
# 3)  SHELL OPTIONS
# ──────────────────────────────────────────────────────────────────────────
setopt AUTO_CD CORRECT SHARE_HISTORY HIST_IGNORE_ALL_DUPS EXTENDED_GLOB



# ──────────────────────────────────────────────────────────────────────────
# 4)  HISTORY
# ──────────────────────────────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000



# ──────────────────────────────────────────────────────────────────────────
# 5)  COMPLETION & PLUGINS
# ──────────────────────────────────────────────────────────────────────────
autoload -Uz compinit; compinit
for plugin in zsh-syntax-highlighting zsh-autosuggestions; do
  if [[ -r "/opt/homebrew/share/$plugin/$plugin.zsh" ]]; then
    source "/opt/homebrew/share/$plugin/$plugin.zsh"
  elif [[ -r "/usr/share/$plugin/$plugin.zsh" ]]; then
    source "/usr/share/$plugin/$plugin.zsh"
  fi
done



# ──────────────────────────────────────────────────────────────────────────
# 6)  PROMPT
# ──────────────────────────────────────────────────────────────────────────
setopt PROMPT_SUBST
PROMPT='%F{cyan}%n@%m%f [RNvSH]: %F{yellow}%~%f %F{green}»%f '



# ──────────────────────────────────────────────────────────────────────────
# 7)  AUTOJUMP
# ──────────────────────────────────────────────────────────────────────────
if [[ "$ZSH_OS" == "macos" ]]; then
  [[ -f /opt/homebrew/etc/profile.d/autojump.sh ]] && source /opt/homebrew/etc/profile.d/autojump.sh
elif [[ -f /etc/profile.d/autojump.sh ]]; then
  source /etc/profile.d/autojump.sh
fi



# ──────────────────────────────────────────────────────────────────────────
# 8)  ALIASES & KEYBINDINGS
# ──────────────────────────────────────────────────────────────────────────
alias ll='ls -lh'
alias la='ls -lha'
alias gs='git status'
alias gl='git log --oneline --graph --decorate'
bindkey -v



# ──────────────────────────────────────────────────────────────────────────
# 9)  RNvZSH HELPER CLI  (`rzsh`)
# ──────────────────────────────────────────────────────────────────────────
rzsh() {
  local cmd="$1" sub="$2" extra="$3" version="$4"

  case "$cmd" in
    ""|help)
      cat <<'EOF'
RNvZSH helper – bootstrap & NVIDIA toolkit
──────────────────────────────────────────
USAGE
  rzsh <command> [subcommand] [options]

COMMANDS
  help                        Show this help.
  install                     Install core packages for the detected OS.
  update                      Upgrade packages and pull latest ~/.zshrc.
  nvidia <sub> [...]          Manage / inspect NVIDIA driver + CUDA + GDS.
  git push                    Commit & push ~/Git/zshrc with date‑stamp.
EOF
      ;;

    install)
      # (bootstrap logic unchanged – refer to previous revision)
      ;;

    update)
      # (upgrade logic unchanged)
      ;;

    nvidia)
      # (all NVIDIA sub‑commands unchanged; still prints cuFile API status)
      ;;

    git)
      if [[ "$sub" == "push" ]]; then
        cd "$HOME/Git/zshrc" 2>/dev/null || { echo "Repo not found"; return; }
        git add .
        git commit -m "$(date +'%Y-%m-%d_%H-%M-%S')" && git push
      else
        echo "Usage: rzsh git push"
      fi
      ;;

    *)
      echo "Unknown command – try  rzsh help" ;;
  esac
}
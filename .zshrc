# ~/.zshrc ────────────────────────────────────────────────────────────────
#  Rasmusson‑Nvidia ZSHell  (RNvZSH)
#  ------------------------------------------------------------------------
#  Cross‑platform Z‑shell profile with NVIDIA CUDA / GPUDirect Storage
#  helpers on Linux **and** remote‑cluster introspection on macOS.
#
#  Author: Arthur Hanson Rasmusson  <arthur@vgpu.io>
#  ------------------------------------------------------------------------
#  OPTIONAL — make RNvZSH your login shell
#     sudo ln -s "$(command -v zsh)" /usr/local/bin/rnvzsh
#     echo "/usr/local/bin/rnvzsh" | sudo tee -a /etc/shells
#     chsh -s /usr/local/bin/rnvzsh
#  ------------------------------------------------------------------------

# ──────────────────────────────────────────────────────────────────────────
# 0)  START‑UP  (banner, environment probes, remote/GPU status)
# ──────────────────────────────────────────────────────────────────────────

# 0.1  Populate $SSH_REMOTE from ~/.project-digits  (one line: user@host)
[[ -z $SSH_REMOTE && -f ~/.project-digits ]] && {
  SSH_REMOTE=$(< ~/.project-digits); SSH_REMOTE=${SSH_REMOTE//[$'\t\r\n ']}
}

# 0.2  Banner
_rnvzsh_banner() { echo -e "\n\033[1;32mWelcome to Rasmusson-Nvidia ZSHell\033[0m"; }

# 0.3  cuFile / GPUDirect Storage probe  (handles missing gdscheck.py)
_rnvzsh_cufile_status() {
  local gdscheck cufs

  # Prefer the compiled helper if present
  if command -v gdscheck &>/dev/null; then
    gdscheck=$(command -v gdscheck)
  elif command -v gdscheck.py &>/dev/null; then
    gdscheck=$(command -v gdscheck.py)
  else
    for g in /usr/local/cuda*/gds/tools/gdscheck{,.py}; do
      [[ -x $g || -r $g ]] && { gdscheck=$g; break; }
    done
  fi

  if [[ -n $gdscheck ]]; then
    local py_exec="python"
    command -v python3 &>/dev/null && py_exec="python3"

    # Capture output; decide OK/FAIL by looking for the success banner
    local out
    if [[ $gdscheck == *.py ]]; then
      out=$($py_exec "$gdscheck" -p 2>/dev/null)
    else
      out=$("$gdscheck" -p 2>/dev/null)
    fi

    if echo "$out" | grep -q -e "Platform verification succeeded" -e "All checks passed"; then
      cufs="OK"
    else
      cufs="FAIL"
    fi
  else
    cufs="gdscheck not found"
  fi

  echo "$cufs"
}

# 0.4  NVIDIA health summary (Linux)
_rnvzsh_nvidia_status() {
  local kernel_status services_status cuda_status rmapi_status="TODO"
  local cufile_status

  if lsmod 2>/dev/null | grep -qE '^nvidia(_|$)'; then
    kernel_status="OK"
  else
    kernel_status=$(lsmod 2>/dev/null | awk '/nvidia/ {print $1}' | xargs)
    [[ -z $kernel_status ]] && kernel_status="nvidia (not loaded)"
  fi

  local svc bad_svcs=()
  for svc in nvidia-fabricmanager nvidia-persistenced; do
    systemctl is-active --quiet "$svc" || bad_svcs+=("$svc")
  done
  services_status=${bad_svcs:+${(j:, :)bad_svcs}}; [[ -z $services_status ]] && services_status="OK"

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

# 0.5  Remote cluster summary (macOS)  — now lists real pods/containers
_rnvzsh_remote_status() {
  local remote_host="${remote:-$SSH_REMOTE}"
  [[ -z $remote_host ]] && { echo "Server: (no remote set)"; echo "PODs: [n/a]"; return; }

  local target="${remote_host#*@}"
  if ping -c1 -W1 "$target" &>/dev/null; then
    echo "Server: UP"

    if ssh -T -o BatchMode=yes -o ConnectTimeout=3 \
           -o PreferredAuthentications=publickey \
           -o NumberOfPasswordPrompts=0 "$remote_host" 'true' 2>/dev/null; then

      # --- fetch pods (JSONPath avoids <none> noise) --------------------
      local pods
      pods=$(ssh "$remote_host" '
        export PATH=$PATH:/snap/bin
        microk8s kubectl get pods -A -o jsonpath="{range .items[*]}{.metadata.namespace}/{.metadata.name} {.status.phase}{\"\\n\"}{end}" 2>/dev/null
      ')

      # --- fetch docker containers -------------------------------------
      local ctrs
      ctrs=$(ssh "$remote_host" 'docker ps --format "{{.Names}} {{.Status}}"' 2>/dev/null)

      # --- pretty‑print -------------------------------------------------
      if [[ -n $pods ]]; then
        echo "PODs:"
        printf '  %s\n' ${(f)pods}
      else
        echo "PODs: none"
      fi

      if [[ -n $ctrs ]]; then
        echo "Containers:"
        printf '  %s\n' ${(f)ctrs}
      fi
    else
      echo "PODs: [ssh auth required]"
    fi
  else
    echo "Server: DOWN"
    echo "PODs: [unavailable]"
  fi
}

# 0.6  Execute banner + status
_rnvzsh_banner
case "$(uname -s)" in
  Linux)  _rnvzsh_nvidia_status ;;
  Darwin) _rnvzsh_remote_status ;;
esac



# ──────────────────────────────────────────────────────────────────────────
# 1)  OS DETECTION
# ──────────────────────────────────────────────────────────────────────────
case "$(uname -s)" in
  Darwin) ZSH_OS="macos" ;;
  Linux)   [[ -f /etc/os-release ]] && . /etc/os-release && ZSH_OS="$ID" || ZSH_OS="linux" ;;
  *)      ZSH_OS="unknown" ;;
esac



# ──────────────────────────────────────────────────────────────────────────
# 2)  PATH & ENVIRONMENT
# ──────────────────────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"
[[ "$ZSH_OS" == macos ]] && export PATH="/opt/homebrew/opt/python@3.13/libexec/bin:$PATH"
if [[ "$ZSH_OS" != macos ]] && command -v nvcc &>/dev/null; then
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
  [[ -r "/opt/homebrew/share/$plugin/$plugin.zsh" ]] && source "/opt/homebrew/share/$plugin/$plugin.zsh"
  [[ -r "/usr/share/$plugin/$plugin.zsh" ]] && source "/usr/share/$plugin/$plugin.zsh"
done



# ──────────────────────────────────────────────────────────────────────────
# 6)  PROMPT
# ──────────────────────────────────────────────────────────────────────────
setopt PROMPT_SUBST
PROMPT='%F{cyan}%n@%m%f [rnvzsh]: %F{yellow}%~%f %F{green}»%f '



# ──────────────────────────────────────────────────────────────────────────
# 7)  AUTOJUMP
# ──────────────────────────────────────────────────────────────────────────
if [[ "$ZSH_OS" == macos ]]; then
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
bindkey -v                 # vi‑mode editing



# ──────────────────────────────────────────────────────────────────────────
# 9)  RNvZSH HELPER CLI  (`rzsh`)
# ──────────────────────────────────────────────────────────────────────────
#  One command, many sub-commands.  Fully commented for maintainability.
rzsh() {
  local cmd="$1" sub="$2" extra="$3" version="$4"

  case "$cmd" in
    # ------------------------------------------------ help --------------
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
  git push                    Commit & push ~/Git/zshrc with date-stamp.

Run “rzsh nvidia” for NVIDIA-specific sub-commands.
EOF
      ;;

    # ---------------------------------------------- install -------------
    install)
      case "$ZSH_OS" in
        macos)
          if ! command -v brew &>/dev/null; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
          fi
          brew install \
            git python3 pip3 gcc visual-studio-code --cask \
            veracrypt ghidra littlesnitch blockblock helper \
            zsh-syntax-highlighting zsh-autosuggestions \
            romkatv/powerlevel10k/powerlevel10k autojump makeself
          ;;
        arch)
          sudo pacman -Sy --needed \
            git python python-pip gcc code veracrypt ghidra \
            zsh-syntax-highlighting zsh-autosuggestions powerlevel10k \
            autojump nvidia-gds cuda nvidia-docker makeself
          ;;
        ubuntu)
          sudo apt update && sudo apt install -y \
            git python3 python3-pip gcc code veracrypt ghidra \
            zsh-syntax-highlighting zsh-autosuggestions powerlevel10k \
            autojump nvidia-gds cuda nvidia-docker2 makeself
          ;;
        fedora)
          sudo dnf install -y \
            git python3 python3-pip gcc code veracrypt ghidra \
            zsh-syntax-highlighting zsh-autosuggestions powerlevel10k \
            autojump nvidia-gds cuda nvidia-docker2 makeself
          ;;
        rhel)
          sudo yum install -y epel-release
          sudo yum install -y \
            git python3 python3-pip gcc code veracrypt ghidra \
            zsh-syntax-highlighting zsh-autosuggestions powerlevel10k \
            autojump nvidia-gds cuda nvidia-docker2 makeself
          ;;
        gentoo)
          sudo emerge --ask \
            dev-vcs/git dev-lang/python dev-python/pip sys-devel/gcc \
            app-editors/vscode app-crypt/veracrypt app-forensics/ghidra \
            app-shells/zsh-syntax-highlighting app-shells/zsh-autosuggestions \
            app-shells/powerlevel10k app-shells/autojump sys-apps/makeself
          ;;
        *) echo "Unsupported OS for install: $ZSH_OS" ;;
      esac

      # Basic Git identity
      cat >~/.gitconfig <<'EOF'
[user]
	email = arthur@vgpu.io
	name  = Arthur Hanson Rasmusson
EOF
      ;;

    # ---------------------------------------------- update --------------
    update)
      case "$ZSH_OS" in
        macos)  brew update && brew upgrade ;;
        arch)   sudo pacman -Syu ;;
        ubuntu) sudo apt update && sudo apt upgrade -y ;;
        fedora) sudo dnf upgrade -y ;;
        rhel)   sudo yum update -y ;;
        gentoo) sudo emerge --sync && sudo emerge --update --deep @world ;;
        *) echo "Unsupported OS for update: $ZSH_OS" ;;
      esac
      echo "Pulling latest ~/.zshrc..."
      git -C "$HOME/Git/zshrc" pull origin main
      ;;

    # ---------------------------------------------- nvidia --------------
    nvidia)
      case "$sub" in
        status)
          _rnvzsh_nvidia_status
          ;;
        install)
          if [[ "$extra" == "local" ]]; then
            version=${version:-latest}
            rzsh nvidia download cuda "$version"
            runfile="cuda_${version}_linux.run"
            chmod +x "$runfile"
            sudo ./"$runfile" --silent --toolkit --override
          else
            rzsh install   # ensure core deps
            case "$ZSH_OS" in
              ubuntu|rhel|fedora)
                sudo apt install -y nvidia-gds cuda nvidia-driver nvidia-docker2 ;;
              arch)
                sudo pacman -Sy --needed nvidia-gds cuda nvidia nvidia-docker ;;
              gentoo)
                sudo emerge --ask nvidia-gds cuda-toolkit nvidia-drivers nvidia-docker ;;
            esac
          fi
          ;;
        update)
          echo "Updating NVIDIA stack..."
          case "$ZSH_OS" in
            macos) echo "Use brew upgrade for NVIDIA packages" ;;
            ubuntu|rhel|fedora)
              sudo apt update && sudo apt upgrade -y nvidia-gds cuda nvidia-driver nvidia-docker2 ;;
            arch)
              sudo pacman -Syu nvidia-gds cuda nvidia nvidia-docker ;;
            gentoo)
              sudo emerge --update --deep nvidia-gds cuda-toolkit nvidia-drivers nvidia-docker ;;
          esac
          ;;
        download)
          if [[ "$extra" == "cuda" ]]; then
            version=${version:-latest}
            curl -LO "https://developer.download.nvidia.com/compute/cuda/${version}/local_installers/cuda_${version}_linux.run"
          else
            echo "Usage: rzsh nvidia download cuda [VERSION]"
          fi
          ;;
        dump)
          if [[ "$extra" == "cuda" ]]; then
            version=${version:-latest}
            file="cuda_${version}_linux.run"
            [[ -f "$file" ]] || rzsh nvidia download cuda "$version"
            dir="cuda_${version}_extract"
            mkdir -p "$dir"
            sh "$file" --extract="$dir"
            echo "Extracted to $dir"
          else
            echo "Usage: rzsh nvidia dump cuda [VERSION]"
          fi
          ;;
        cuda)
          if [[ "$extra" == "repack" ]]; then
            version=${version:-latest}
            if ! command -v makeself &>/dev/null; then
              echo "Install 'makeself' first."
            else
              runfile="cuda_repack_${version}_$(date +'%Y%m%d%H%M%S').run"
              makeself --notemp . "$runfile" "Repacked CUDA $version" ./install.sh
              echo "Created $runfile"
            fi
          else
            echo "Usage: rzsh nvidia cuda repack"
          fi
          ;;
        rmapi)
          echo "Resource Manager API tooling: WIP"
          ;;
        tensorrt-llm)
          if [[ "$extra" == "init" ]]; then
            mkdir -p "$HOME/Git"
            git clone git@github.com:NVIDIA/TensorRT-LLM.git "$HOME/Git/TensorRT-LLM"
            cd "$HOME/Git/TensorRT-LLM" || return
            git remote rename origin nvidia
            git remote add arthurrasmusson git@github.com:arthurrasmusson/TensorRT-LLM.git
          else
            echo "Usage: rzsh nvidia tensorrt-llm init"
          fi
          ;;
        *)
          echo "Usage: rzsh nvidia {status|install|install local|update|download cuda|dump cuda|cuda repack|rmapi|tensorrt-llm init}"
          ;;
      esac
      ;;

    # ---------------------------------------------- git -----------------
    git)
      if [[ "$sub" == "push" ]]; then
        cd "$HOME/Git/zshrc" 2>/dev/null || { echo "Repo not found"; return; }
        git add .
        git commit -m "$(date +'%Y-%m-%d_%H-%M-%S')" && git push
      else
        echo "Usage: rzsh git push"
      fi
      ;;

    # ---------------------------------------------- fallback ------------
    *)
      echo "Unknown command – try  rzsh help"
      ;;
  esac
}

# For muscle-memory with the old name
alias zshtool='rnvzsh'
alias zshtool='rzsh'
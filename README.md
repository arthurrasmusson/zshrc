# Rasmusson‑Nvidia ZSHell (RNvZSH)
*A zero‑hassle Z‑shell profile tailored for CUDA
development on **Project Digits** machines.*

---

## ⚡ Quick start
```bash
# 1. Clone the repo
git clone https://github.com/arthurrasmusson/zshrc.git ~/Git/zshrc

# 2. Activate it
ln -sf ~/Git/zshrc/.zshrc ~/.zshrc

# 3. Launch a new terminal → enjoy the green banner!
````

> **Login shell (optional)**
>
> ```bash
> sudo ln -s "$(command -v zsh)" /usr/local/bin/rnvzsh
> echo "/usr/local/bin/rnvzsh" | sudo tee -a /etc/shells
> chsh -s /usr/local/bin/rnvzsh
> ```

> **Remote helper (macOS)**
> Create `~/.project-digits` containing one line, e.g.
> `root@172.29.0.47` – or export `remote=…`.
> Every macOS shell start then shows a *Server UP/DOWN* banner plus a
> live list of MicroK8s pods & Docker containers on the remote.

---

## 🧰 What RNvZSH gives you

| Area                  | Highlights                                                                                                                                 |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| **Banner**            | *Welcome …* plus driver / CUDA / cuFile **OK/FAIL** (Linux) or remote‑cluster status (macOS).                                              |
| **Prompt**            | `alice@box [rnvzsh]: ~/path »`                                                                                                             |
| **Plugins**           | `zsh-syntax-highlighting`, `zsh-autosuggestions`, `autojump`.                                                                              |
| **Theme**             | Auto‑detects *Powerlevel10k* → *Pure* → minimal fallback.                                                                                  |
| **History & options** | Shared, deduped history; vi‑mode key‑bindings.                                                                                             |
| **Generic CUDA env**  | Automatically exports `$CUDA_HOME`, `$PATH`, `$LD_LIBRARY_PATH`, etc. for the *latest* `/usr/local/cuda‑*` tree—no edits between versions. |
| **NGC key**           | If `~/.NGC-KEY` exists it is sourced automatically.                                                                                        |
| **Helper CLI**        | One command – `rzsh` – covers install, update, NVIDIA management, git push, and **interactive SSH (`connect zsh`)**.                       |

---

## 📝 Top‑level `rzsh` commands

| Command                   | What it does                                                                                                  |
| ------------------------- | ------------------------------------------------------------------------------------------------------------- |
| `rzsh help`               | Global help screen.                                                                                           |
| `rzsh install`            | Bootstrap packages for the current OS (brew/apt/dnf/pacman/…).                                                |
| `rzsh update`             | Upgrade those packages & pull the latest dot‑files.                                                           |
| `rzsh connect zsh [host]` | SSH to *host* (or `$SSH_REMOTE`/`~/.project-digits`) and start a login **zsh** – CUDA env ready on first try. |
| `rzsh git push`           | Snapshot & push your `~/Git/zshrc` with a date‑stamp commit.                                                  |

---

## 🔧 `rzsh nvidia` sub‑commands

| Sub‑command           | Description                                                                                                    |
| --------------------- | -------------------------------------------------------------------------------------------------------------- |
| `status`              | Verbose report: kernel modules, services, driver & CUDA versions, per‑GPU table, cuFile probe (`gdscheck -p`). |
| `install`             | Install driver + CUDA from distro repositories.                                                                |
| `install local [VER]` | Install from a downloaded `cuda_<ver>_linux.run`.                                                              |
| `update`              | Upgrade NVIDIA packages only.                                                                                  |
| `download cuda <VER>` | Fetch the `.run` installer but don’t install.                                                                  |
| `dump cuda <VER>`     | Extract a `.run` file to `./cuda_<ver>_extract/`.                                                              |
| `cuda repack <VER>`   | Re‑package an extracted toolkit (needs `makeself`).                                                            |
| `rmapi`               | Placeholder for Resource‑Manager API helpers.                                                                  |
| `tensorrt-llm init`   | Clone NVIDIA/TensorRT‑LLM and add your fork remote.                                                            |

Run `rzsh nvidia help` to see the table at any time.

---

## 🔍 Remote‑status logic (macOS)

```text
┌─ ping 1 s ──┐
│             │
│    reachable? ── no → "Server: DOWN"
│             │
└─ yes ─ ssh (BatchMode) ─┐
                          │
                key works? │
               ┌───────────┘
               ▼
 "Server: UP" + live list of
 - microk8s pods (JSONPath – no <none>)
 - docker ps names/status
```

No additional tooling is required on your Mac; everything runs through
OpenSSH.

---

## 🛡️ License

GPL v3 – hack away; please credit and open PRs!

---

*Crafted with ☕ + tensor cores by Arthur Rasmusson*
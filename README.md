# Rasmusson‑Nvidia ZSHell (RNvZSH)
*Arthur's Nvidia Z‑shell configuration for CUDA development on Project Digits.*

---

## 🔧 Quick & Easy Setup
```bash
# 1. grab the files
git clone https://github.com/arthurrasmusson/zshrc.git ~/Git/zshrc   

# 2. drop the profile in place
ln -sf ~/Git/zshrc/.zshrc ~/.zshrc                        

# 3. open a new terminal  ➜  enjoy the green banner!
````

> **macOS extra:**
> If you regularly SSH into a Linux build box, set
> Create ~/.project-digits and put your username and remote inside.
> Example : root@0.0.0.0
> RNvZSH will show a *Server UP/DOWN* line and list running
> microk8s pods + Docker containers each time you start Terminal.

> **Login shell (optional):**
> `sudo ln -s "$(command -v zsh)" /usr/local/bin/rnvzsh && \
>  echo "/usr/local/bin/rnvzsh" | sudo tee -a /etc/shells && \
>  chsh -s /usr/local/bin/rnvzsh`

That’s **it**—no plug‑in managers, no 300‑line installer script.
Clone, link, reload. Done.

---

## 🐚 What you get out‑of‑the‑box

* **Banner & health block** – “Welcome to Rasmusson‑Nvidia ZSHell”
  plus live driver/CUDA/cuFile status (Linux) **or** remote cluster
  status (macOS).
* **Prompt** – `alice@mybox [RNvSH]: ~/code »`
* **Powerlevel10k** if present, otherwise Pure, otherwise a tidy fallback.
* **Plugins** – syntax highlighting, autosuggestions, autojump.
* **Shared history**, sane options, vi‑mode key‑bindings.
* **A one‑stop helper** command called **`rzsh`**.

---

## 📜 Command reference (verbose)

| Command                           | Purpose                                | Detailed behaviour                                                                                                                                                                                                                                                                                                                              |
| --------------------------------- | -------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `rzsh help`                       | Built‑in manual.                       | Prints the same table you are reading plus examples.                                                                                                                                                                                                                                                                                            |
| `rzsh install`                    | Bootstrap a fresh system.              | Detects distro (macOS brew, Ubuntu apt, Arch pacman, Fedora dnf, RHEL yum, Gentoo emerge) and installs: Git, Python 3, VS Code, Veracrypt, Ghidra, Z‑shell plugins, Powerlevel10k, Autojump, **and** NVIDIA prerequisites (`cuda`, `nvidia‑gds`, `nvidia‑docker`) on Linux. Creates a minimal `~/.gitconfig` so `git commit` works immediately. |
| `rzsh update`                     | Keep things current.                   | Runs the appropriate package‑manager upgrade command *and* pulls the latest version of this repo into `~/Git/zshrc`.                                                                                                                                                                                                                            |
| `rzsh nvidia status`              | Instant driver health.                 | Shows: Loaded kernel modules or missing ones, status of `nvidia‑fabricmanager` and `nvidia‑persistenced` services, CUDA toolkit version, **cuFile API** probe (`gdscheck.py -p`).                                                                                                                                                               |
| `rzsh nvidia install`             | Install drivers from distro repos.     | Uses apt/dnf/pacman/etc. to pull the meta‑packages *nvidia‑driver*, *cuda*, *nvidia‑docker2*, *nvidia‑gds*.                                                                                                                                                                                                                                     |
| `rzsh nvidia install local <ver>` | Install drivers from `.run` installer. | Downloads `cuda_<ver>_linux.run` if missing, runs it silently (`--toolkit --override`). Good for air‑gapped servers.                                                                                                                                                                                                                            |
| `rzsh nvidia update`              | Update drivers & CUDA.                 | Runs the package‑manager upgrade path for only NVIDIA packages.                                                                                                                                                                                                                                                                                 |
| `rzsh nvidia download cuda <ver>` | Just download the `.run`.              | Leaves the file in the current directory; no installation.                                                                                                                                                                                                                                                                                      |
| `rzsh nvidia dump cuda <ver>`     | Inspect the `.run`.                    | Extracts the installer into `./cuda_<ver>_extract/` so you can peek at RPM/DEB payloads.                                                                                                                                                                                                                                                        |
| `rzsh nvidia cuda repack <ver>`   | Re‑bundle an extracted toolkit.        | Requires `makeself`; turns the folder back into a smaller self‑extracting archive—handy for staging custom toolkits.                                                                                                                                                                                                                            |
| `rzsh nvidia rmapi`               | (stub) RM API tooling.                 | Placeholder for future Resource Manager API scripts.                                                                                                                                                                                                                                                                                            |
| `rzsh nvidia tensorrt-llm init`   | Fork helper.                           | Clones NVIDIA’s **TensorRT‑LLM** repo, adds your personal fork remote.                                                                                                                                                                                                                                                                          |
| `rzsh git push`                   | One‑liner dot‑file commit.             | Adds **all** changes in `~/Git/zshrc`, commits with a timestamp message, pushes to *origin*. Perfect for “save & forget” snapshots.                                                                                                                                                                                                             |

---

## 🔍 How the remote check works (macOS)

1. Set an env variable: `export remote=myuser@gpu‑box` (or use `SSH_REMOTE`).
2. On Terminal start RNvZSH runs a 3‑second SSH banner probe.

   * If it connects – it prints **Server: UP** and executes:

     * `microk8s kubectl get pods -A` (lists pods)
     * `docker ps --format "{{.Names}}"` (lists containers)
   * If it times‑out – it prints **Server: DOWN**.
3. Output is compressed into one line:
   `PODs: [namespace/app  db/mysql  web_frontend]`

No extra Python, no local MicroK8s needed on your Mac.

---

## ✒️ License

GPLv3.  Fork, copy, cherry‑pick—just drop a star if you like it.

---

*Made with ☕ and \:gpu: by Arthur H. Rasmusson.*
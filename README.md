# 🧹 Interactive System & Developer Cache Cleanup

A full-featured cleanup utility for **Windows, Debian/Ubuntu, and Fedora/RHEL** that safely purges junk, caches, and temporary files from both your **development environment** and your **system**, without touching personal data or breaking configurations.

---

## ✨ Features

✅ **Interactive prompts** – you choose what to clean (no accidental nuking).  
✅ **Safe by design** – preserves settings, credentials, logins, and history.  

✅ **Multi-tool developer cleanup:**
- npm / node_modules
- pip / conda / Python (detects all installs automatically)
- Docker, Bun, Gradle, Flutter, VS / JetBrains IDEs
- LM Studio (keeps chat history + settings)
  
✅ **System cleanup:**
- Windows Temp, Prefetch, and optional Search Index rebuild
- Linux `/tmp`, `/var/tmp`, thumbnails, APT / DNF package cache, and systemd journals
  
✅ **Browser cleanup (optional):**
- Chrome, Edge, Brave, Firefox, Tor, Mullvad, Comet, Incognition, and others  
- Clears cache only (sessions and profiles remain intact)
  
✅ **Readable, modular PowerShell / Bash code**  
✅ **No reinstalls, no registry edits, no unsafe operations**

---

## 🧰 Installation & Usage

### Windows

If your system blocks scripts:

1. **Download or clone** this repo:
   ```powershell
   git clone https://github.com/LizzieNya/clear-dev-caches-win.git
   cd clear-dev-caches-win
2. Run PowerShell as **Administrator**.
3. Execute the script
   ```powershell
    .\winclean-swissknife.ps1
Follow on-screen prompts (type y or n for each section).

### Linux (Debian / Ubuntu / Fedora / RHEL)

1. **Download or clone** this repo:
   ```bash
   git clone https://github.com/LizzieNya/clear-dev-caches-win.git
   cd clear-dev-caches-win
   ```
2. Run the appropriate script with Bash:
   ```bash
   # Debian / Ubuntu
   bash debclean-swissknife.sh

   # Fedora / RHEL
   bash fedclean-swissknife.sh
   ```
3. Follow the on-screen prompts (type y or n for each section).

> **Note:** On filesystems that do not support Unix execute permissions (e.g. NTFS), run the scripts with `bash` instead of `./script.sh`.

What it cleans:

| Category         | Description                                                                 |
| ---------------- | --------------------------------------------------------------------------- |
| **Dev caches**   | npm, pip, conda, Docker, Bun, Gradle, Flutter, VSCode, IntelliJ, etc.       |
| **Python**       | Detects all python/python3 installations and purges pip caches.             |
| **LM Studio**    | Removes models/logs but preserves history & settings.json.                  |
| **Windows temp** | Clears `%TEMP%`, `%windir%\Temp`, and Prefetch safely.                      |
| **Linux temp**   | Clears `/tmp`, `/var/tmp`, thumbnails, APT/DNF cache, and systemd journals. |
| **Search index** | Windows Search, GNOME Tracker, or KDE Baloo index rebuild.                  |
| **Browsers**     | Wipes cache, GPU cache, shader cache for Chromium & Firefox-based browsers. |

## ⚠️ Safety Notes
- Make sure no browsers or IDEs are open while running the cleanup.

- Always close running containers or VMs before deleting Docker data.
- Everything removed will rebuild automatically when reopened.
- For peace of mind, create a restore point before running.

## 🧭 Why This Exists
If you’re a developer with:
- Multiple Python installs,
- Half a dozen browsers,
- Endless toolchains like npm, conda, Docker, Flutter, etc.,

this script gives you a clean slate — without reinstalling anything.
Think of it as “the digital equivalent of emptying your junk drawer."


## 🛡 License
This project is released under the MIT License.
Use, modify, and share freely — just don’t blame it if your system runs too fast afterward (or not at all!).

## 💬 Contributing
Issues and PRs are welcome!
Got an edge case or another browser to add? Open a pull request.

## 🌟 Support
If you find this useful:

⭐ Star the repo
🐛 Open an issue for bugs
🧩 Share improvements or feature requests
Or contribute!

## Built with 🥀 and a severe lack of storage space.

  ## 🧑‍💻 Example Output
  ```mathematica
=== INTERACTIVE CLEANUP ===

Delete developer caches and build artifacts (npm, pip, conda, docker, gradle, flutter, etc.)? (y/n) y

--- Deleting developer caches ---
Deleting C:\Users\notebook\.npm
Deleting C:\Users\notebook\.docker
Deleting C:\Users\notebook\.gradle
Deleting C:\Users\notebook\.flutter
Deleting C:\Users\notebook\.m2
Deleting C:\Users\notebook\.vs
Cleaning LM Studio cache (keeping history & settings)
Purging pip cache for C:\Users\notebook\miniconda3\python.exe
Purging pip cache for C:\Users\notebook\anaconda3\python.exe
npm WARN using --force Recommended protections disabled.
npm cache cleared.
conda clean --all -y
Will remove 2 index cache(s).
Will remove 4 package cache(s).
Proceed ([y]/n)? y
Removed 6 cache(s).

Removing node_modules folders
Deleting C:\Users\notebook\Desktop\project-alpha\node_modules
Deleting C:\Users\notebook\Desktop\webapp\node_modules
Deleting C:\Users\notebook\src\archive\node_modules

Clearing pip / conda / npm caches
pip cache purge
Files removed: 2,351

--- Developer cleanup complete ---

Clear Windows temp files and Prefetch? (y/n) y
--- Deleting system temp files ---
Removing C:\Users\notebook\AppData\Local\Temp\*
Removing C:\Windows\Temp\*
Removing C:\Windows\Prefetch\*
Windows temporary files cleared successfully.

Rebuild Windows Search index (delete old index)? (y/n) y
--- Rebuilding Search index ---
Stopping Windows Search service...
The Windows Search service was stopped successfully.
Deleting C:\ProgramData\Microsoft\Search\Data\
Turn Search service back on after cleanup? (y/n) y
Starting Windows Search service...
The Windows Search service was started successfully.

Clear browser caches (keep sessions/logins)? (y/n) y
--- Cleaning browser caches ---

Clearing Chromium cache: C:\Users\notebook\AppData\Local\Google\Chrome\User Data\Default\Cache
Clearing Chromium cache: C:\Users\notebook\AppData\Local\Microsoft\Edge\User Data\Default\Cache
Clearing Chromium cache: C:\Users\notebook\AppData\Local\BraveSoftware\Brave-Browser\User Data\Default\GPUCache
Clearing Chromium cache: C:\Users\notebook\AppData\Local\Comet\User Data\Default\ShaderCache
Clearing Chromium cache: C:\Users\notebook\AppData\Local\Incognition\User Data\Default\Media Cache

Clearing Firefox cache: C:\Users\notebook\AppData\Mozilla\Firefox\Profiles\default-release
Clearing Firefox cache: C:\Users\notebook\AppData\Mozilla\Firefox\Profiles\dev-edition
Clearing Firefox cache: C:\Users\notebook\AppData\Mullvad Browser\Browser\TorBrowser\Data\Browser\profile.default
Clearing Firefox cache: C:\Users\notebook\AppData\Tor Browser\Browser\TorBrowser\Data\Browser\profile.default

--- Browser cache cleanup complete ---

✅ Cleanup finished. Restart is recommended.

Summary:
- Developer caches cleared: 17 folders
- node_modules removed: 3 projects
- Python pip caches cleared: 2 installs
- Windows temp + prefetch cleaned
- Search index rebuilt
- Browser caches cleared (sessions preserved)
Approximate space freed: 24.6 GB

  ## 🐧 Linux Example Output
  ```
=== INTERACTIVE CLEANUP ===

Delete developer caches and build artifacts (npm, pip, conda, docker, gradle, flutter, etc.)? (y/n) y

--- Deleting developer caches ---
Deleting /home/user/.npm
Deleting /home/user/.docker
Deleting /home/user/.gradle
Deleting /home/user/.flutter
Deleting /home/user/.m2
Deleting /home/user/.vs
Cleaning LM Studio cache (keeping history & settings)
Purging pip cache for /home/user/.local/bin/python3
Purging pip cache for /home/user/miniconda3/bin/python
npm cache cleared.
conda clean --all -y
Removed 6 cache(s).

Removing node_modules folders
Deleting /home/user/Desktop/project-alpha/node_modules
Deleting /home/user/Desktop/webapp/node_modules
Deleting /home/user/src/archive/node_modules

--- Developer cleanup complete ---

Clear system temp files, thumbnails, and APT package cache? (y/n) y
--- Deleting system temp files ---
Cleaning APT package cache...
Vacuuming systemd journals...

Rebuild search index (GNOME Tracker / KDE Baloo)? (y/n) y
--- Rebuilding search index ---
Resetting GNOME Tracker index...
Purging KDE Baloo index...
Turn search service back on after cleanup? (y/n) y
Restarting Baloo...

Clear browser caches (keep sessions/logins)? (y/n) y
--- Cleaning browser caches ---

Clearing cache: /home/user/.config/google-chrome/Default/Cache
Clearing cache: /home/user/.config/BraveSoftware/Brave-Browser/Default/GPUCache
Clearing cache: /home/user/.config/microsoft-edge/Default/Code Cache
Clearing cache: /home/user/.mozilla/firefox/default-release/cache2
Clearing cache: /home/user/.var/app/org.mozilla.firefox/data/firefox/profiles.default/cache2

--- Browser cache cleanup complete ---

Cleanup finished. Restart is recommended.
```

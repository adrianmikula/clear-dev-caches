# 🧹 Interactive System & Developer Cache Cleanup

A full-featured cleanup utility for **Windows, Debian/Ubuntu, and Fedora/RHEL** that safely purges junk, caches, and temporary files from both your **development environment** and your **system**, without touching personal data or breaking configurations.

---

## ✨ Features

✅ **Interactive prompts** – you choose what to clean (no accidental nuking).  
✅ **Safe by design** – preserves settings, credentials, logins, and history.  

✅ **Multi-tool developer cleanup:**
- Conservative pruning for npm, pnpm, uv, Composer, and mise
- Separately confirmed full cleanup for npm, Yarn, Bun, pip, conda, Poetry, uv, Go, Composer, NuGet, Dart/Flutter, and mise caches/tool installations
- Aggressive removal of `node_modules` and locked Composer `vendor` trees under `${SOURCE_ROOT:-$HOME/Source}`
- Exact generated caches for Next.js, PHPUnit, and IntelliJ development sandboxes
  
✅ **System cleanup:**
- Windows Temp, Prefetch, and optional Search Index rebuild
- Linux temporary files through systemd-tmpfiles policy, plus thumbnails, APT / DNF package cache, curated safe `/var/cache` clearing (with reporting of unknown directories), Flatpak `/var/lib/flatpak/repo/tmp`, and systemd journals

✅ **Optional backups:**
- Local archives are stored under `${XDG_STATE_HOME:-$HOME/.local/state}/clear-dev-caches/backups`
- Local archives can optionally be uploaded to PixelDrain
  
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
| **Dev prune**    | Uses tool-owned prune/GC commands without removing project dependencies.    |
| **Dev full**     | Clears redownloadable caches and confirmed project dependency directories.  |
| **Project cache**| Clears `.next/cache`, `.next/dev/cache`, `.phpunit.cache`, and IntelliJ sandbox caches under `SOURCE_ROOT`. |
| **AI caches**    | Removes verified cache/log/tool-output paths while preserving app state.    |
| **Windows temp** | Clears `%TEMP%`, `%windir%\Temp`, and Prefetch safely.                      |
| **Linux temp**   | Uses systemd-tmpfiles policy, thumbnails, package caches, curated `/var/cache` allowlist, Flatpak repo temp, and journal vacuuming. |
| **Search index** | Windows Search, GNOME Tracker, or KDE Baloo index rebuild.                  |
| **Browsers**     | Wipes cache, GPU cache, shader cache for Chromium & Firefox-based browsers. |
| **Downloads**    | Deletes old Downloads, Trash, and installer binaries (ZIP, DEB, TAR, etc.) older than 1 week. |

## ⚠️ Safety Notes
- Close browsers, IDEs, development servers, test runners, and package-manager processes before cleanup.
- The conservative developer option uses standard prune or garbage-collection commands. The aggressive option removes dependency caches, `node_modules` and Composer `vendor` directories under `SOURCE_ROOT`, and all mise-managed tool installations while preserving mise configuration files; restore tools with `mise install`. Offline builds may stop working until dependencies are restored.
- Maven settings/repositories, Gradle JDKs/settings, Cargo credentials/binaries, Docker configuration, AI histories/settings/models, game runtimes, and user-created Krita resources are preserved.
- Next.js cleanup removes only `.next/cache` and `.next/dev/cache`. IntelliJ cleanup removes only generated `build/idea-sandbox/system/caches` directories.
- Linux temp cleanup follows systemd-tmpfiles policy and only clears `/var/cache` directories listed in `var-cache-linux.properties`, preserving the directory itself, package-manager caches, and special caches such as BIND and debconf. Other `/var/cache` directories are reported (with size) but not deleted. Without systemd-tmpfiles, only current-user top-level files, symlinks, and empty directories older than seven days are eligible.
- Local backups cover enumerated filesystem targets, not caches cleared internally by tool commands. PixelDrain upload is optional; review the archive's sensitivity before uploading it.
- Always close running containers or VMs before deleting container or VM data.

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

Prune unused developer-tool caches (npm, pnpm, uv, Composer, mise)? (y/n) y
Fully clear redownloadable developer caches and project dependencies? (y/n) y

--- Pruning developer-tool caches ---
Verifying and pruning npm cache...
Pruning pnpm store...

--- Fully clearing developer caches and dependencies ---
Deleting /home/user/Source/project-alpha/node_modules
Deleting /home/user/Source/php-plugin/vendor
Deleting /home/user/Source/webapp/.next/dev/cache
Clearing npm cache...
Clearing pip cache...
Clearing Composer cache...

Clear system temp files, thumbnails, and APT package cache? (y/n) y
--- Cleaning system temp files ---
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

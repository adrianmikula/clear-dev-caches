#!/usr/bin/env bash
# ======================================================================
# INTERACTIVE FULL CLEANUP – SAFE VERSION WITH CLI + OPTIONAL BACKUP
# Debian/Ubuntu edition
# ======================================================================
set -uo pipefail

# ---------------------- HELPERS ----------------------
ask_yn() {
    local msg="$1"
    local ans
    read -rp "$msg (y/n) " ans
    [[ "$ans" =~ ^[Yy] ]]
}

_create_backup() {
    local workdir="${XDG_STATE_HOME:-$HOME/.local/state}/clear-dev-caches/backups"
    mkdir -p "$workdir" || return 1
    chmod 700 "$workdir" 2>/dev/null || true
    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    local archive="$workdir/cleanup-backup-$timestamp.tar.gz"
    local existing=()
    local p
    for p in "$@"; do
        { [ -e "$p" ] || [ -L "$p" ]; } && existing+=("$p")
    done
    if [ ${#existing[@]} -eq 0 ]; then
        echo "No existing filesystem paths to backup." >&2
        return 1
    fi
    if tar -czf "$archive" -C / "${existing[@]/#/}"; then
        chmod 600 "$archive" 2>/dev/null || true
        echo "$archive"
        return 0
    fi
    echo "Failed to create backup archive." >&2
    return 1
}

_upload_pixeldrain() {
    local file="$1"
    local api_key="${2:-}"
    [ -f "$file" ] || return 1
    local cmd=(curl -s -X POST "https://pixeldrain.com/api/file" -F "file=@$file")
    if [ -n "$api_key" ]; then
        local token
        token=$(printf ':%s' "$api_key" | base64 -w0)
        cmd+=(-H "Authorization: Basic $token")
    fi
    local resp
    resp=$("${cmd[@]}")
    [ -n "$resp" ] || return 1
    echo "$resp"
}

_save_backup_metadata() {
    local resp="$1"
    local archive="$2"
    local metafile="${archive%.tar.gz}.pixeldrain.json"
    cat > "$metafile" <<EOF
{
  "uploaded_at": "$(date -Iseconds)",
  "archive_path": "$archive",
  "pixeldrain": $resp
}
EOF
    chmod 600 "$metafile" 2>/dev/null || true
    echo "Metadata saved to $metafile"
}

_run_tool() {
    local executable="$1"
    local label="$2"
    shift 2
    command -v "$executable" >/dev/null 2>&1 || return 0
    echo "$label"
    "$executable" "$@" || echo "Warning: $executable cache cleanup failed; continuing." >&2
}

_run_mise_tool() {
    local label="$1"
    shift
    local mise_bin
    mise_bin=$(command -v mise 2>/dev/null || true)
    if [ -z "$mise_bin" ] && [ -x "$HOME/.local/bin/mise" ]; then
        mise_bin="$HOME/.local/bin/mise"
    fi
    [ -n "$mise_bin" ] || return 0
    echo "$label"
    "$mise_bin" "$@" || echo "Warning: mise command failed; continuing." >&2
}

_delete_targets() {
    local path
    for path in "$@"; do
        if [ -e "$path" ] || [ -L "$path" ]; then
            echo "Deleting $path"
            rm -rf -- "$path"
        fi
    done
}

# ---------------------- PROPERTIES FILE READERS ----------------------
_read_properties() {
    local file="$1"
    [ -f "$file" ] || return 0
    while IFS= read -r line; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$line" ]] && continue
        echo "$line"
    done < "$file"
}

_get_paths_from_props() {
    local file="$1"
    local home="${2:-$HOME}"
    while IFS= read -r rel; do
        [ -e "$home/$rel" ] && echo "$home/$rel"
    done < <(_read_properties "$file")
}

_get_project_cache_targets() {
    local root="${SOURCE_ROOT:-$HOME/Source}"
    [ -d "$root" ] || return 0
    root=$(realpath "$root") || return 0
    find "$root" -xdev -user "$(id -un)" -type d \( \
        -path '*/build/idea-sandbox/system/caches' -o \
        -path '*/.next/cache' -o \
        -path '*/.next/dev/cache' -o \
        -name '.phpunit.cache' \
    \) -prune -print 2>/dev/null
}

_get_dependency_targets() {
    local root="${SOURCE_ROOT:-$HOME/Source}"
    [ -d "$root" ] || return 0
    root=$(realpath "$root") || return 0
    find "$root" -xdev -user "$(id -un)" -type d \( -name node_modules -o -name vendor \) -prune -print0 2>/dev/null |
        while IFS= read -r -d '' dir; do
            if [ "$(basename "$dir")" = "vendor" ]; then
                if [ ! -f "$(dirname "$dir")/composer.json" ] || [ ! -f "$(dirname "$dir")/composer.lock" ]; then
                    continue
                fi
            fi
            echo "$dir"
        done
}

# ---------------------- TARGET SETS ----------------------
get_dev_cache_targets() {
    local props
    props="$(dirname "${BASH_SOURCE[0]}")/dev-caches-linux.properties"
    { _get_paths_from_props "$props" "$HOME"; _get_project_cache_targets; } | sort -u
}

get_ai_cache_targets() {
    local props
    props="$(dirname "${BASH_SOURCE[0]}")/ai-caches-linux.properties"
    _get_paths_from_props "$props" "$HOME"
}

get_system_temp_targets() {
    local targets=(
        "$HOME/.cache/thumbnails"
        "$HOME/.cache/flatpak"
        "$HOME/.cache/folks"
        "$HOME/.cache/fontconfig"
        "$HOME/.cache/gnome-desktop-thumbnailer"
        "$HOME/.cache/gnome-software"
        "$HOME/.cache/mesa_shader_cache"
        "$HOME/.cache/mesa_shader_cache_db"
        "$HOME/.cache/radv_builtin_shaders"
    )
    local t
    for t in "${targets[@]}"; do
        [ -e "$t" ] && echo "$t"
    done
}

get_temp_fallback_targets() {
    local dir
    for dir in /tmp /var/tmp; do
        [ -d "$dir" ] || continue
        find "$dir" -xdev -mindepth 1 -maxdepth 1 -user "$(id -un)" -mtime +6 \
            \( -type f -o -type l -o -type d -empty \) -print 2>/dev/null
    done
}

get_search_index_targets() {
    local targets=(
        "$HOME/.cache/tracker3"
        "$HOME/.local/share/baloo"
    )
    for t in "${targets[@]}"; do
        [ -e "$t" ] && echo "$t"
    done
}

get_browser_cache_targets() {
    local home="$HOME"
    local chromium_bases=(
        "$home/.config/google-chrome"
        "$home/.config/google-chrome-beta"
        "$home/.config/google-chrome-unstable"
        "$home/.config/chromium"
        "$home/.config/edge"
        "$home/.config/microsoft-edge"
        "$home/.config/microsoft-edge-beta"
        "$home/.config/microsoft-edge-dev"
        "$home/.config/BraveSoftware/Brave-Browser"
        "$home/.config/BraveSoftware/Brave-Browser-Beta"
        "$home/.config/BraveSoftware/Brave-Browser-Nightly"
        "$home/.cache/BraveSoftware"
        "$home/.config/comet"
        "$home/.config/incognition"
    )
    for base in "${chromium_bases[@]}"; do
        [ -d "$base" ] || continue
        find "$base" -type d \( \
            -name "Cache" -o \
            -name "Cache2" -o \
            -name "Code Cache" -o \
            -name "GPUCache" -o \
            -name "ShaderCache" -o \
            -name "Media Cache" \
        \) -print0 2>/dev/null | while IFS= read -r -d '' dir; do
            echo "$dir"
        done
    done

    local firefox_profiles=(
        "$home/.mozilla/firefox"
        "$home/.var/app/org.mozilla.firefox/data/firefox"
        "$home/.local/share/torbrowser/tbb/x86_64/tor-browser_en-US/Browser/TorBrowser/Data/Browser/profile.default"
        "$home/.local/share/mullvad-browser/mullvad-browser_en-US/Browser/TorBrowser/Data/Browser/profile.default"
    )
    for p in "${firefox_profiles[@]}"; do
        [ -d "$p" ] || continue
        for profile in "$p"/*; do
            [ -d "$profile/cache2" ] && echo "$profile/cache2"
        done
    done
}

get_downloads_trash_targets() {
    local targets=(
        "$HOME/Downloads"
        "$HOME/.local/share/Trash/files"
        "$HOME/.local/share/Trash/expunged"
        "$HOME/.local/share/Trash/info"
    )
    for t in "${targets[@]}"; do
        [ -d "$t" ] || continue
        find "$t" -mindepth 1 -mtime +6 -print0 2>/dev/null \
            | while IFS= read -r -d '' item; do
                echo "$item"
            done
    done
}

get_download_installer_targets() {
    local d="$HOME/Downloads"
    [ -d "$d" ] || return 0
    find "$d" -maxdepth 1 -type f -mtime +6 -iregex '.*\.\(zip\|tar\|tgz\|gz\|bz2\|xz\|7z\|deb\|rpm\|dmg\|pkg\|exe\|msi\|appimage\|run\|sh\)$' -print 2>/dev/null
}

get_container_targets() {
    local props
    props="$(dirname "${BASH_SOURCE[0]}")/containers-caches-linux.properties"
    _get_paths_from_props "$props" "$HOME"
}

get_var_cache_targets() {
    local props
    props="$(dirname "${BASH_SOURCE[0]}")/var-cache-linux.properties"
    [ -f "$props" ] || return 0
    local name
    while IFS= read -r name; do
        name="${name#"${name%%[![:space:]]*}"}"
        name="${name%"${name##*[![:space:]]}"}"
        [ -z "$name" ] && continue
        name="${name##*/}"
        [[ "$name" == "." || "$name" == ".." ]] && continue
        local dir="/var/cache/$name"
        [ -d "$dir" ] && [ ! -L "$dir" ] && echo "$dir"
    done < <(_read_properties "$props")
}

clear_var_cache_contents() {
    local target
    while IFS= read -r target; do
        [ -d "$target" ] || continue
        if [ -n "$(find "$target" -mindepth 1 -print -quit 2>/dev/null)" ]; then
            echo "Clearing contents of $target"
            if [ "$EUID" -eq 0 ]; then
                find "$target" -mindepth 1 -delete 2>/dev/null || true
            else
                sudo find "$target" -mindepth 1 -delete 2>/dev/null || true
            fi
        fi
    done < <(get_var_cache_targets)
}

report_var_cache_summary() {
    local allowed=()
    local dir
    while IFS= read -r dir; do
        allowed+=("$(basename "$dir")")
    done < <(get_var_cache_targets)

    local special=(apt bind debconf dnf yum PackageKit rpm dpkg private)

    local preserved=()
    local s
    for s in "${special[@]}"; do
        [ -d "/var/cache/$s" ] && preserved+=("/var/cache/$s")
    done
    if [ ${#preserved[@]} -gt 0 ]; then
        echo "  Preserving package-manager/special /var/cache directories: ${preserved[*]}"
    fi

    while IFS= read -r -d '' dir; do
        local base
        base=$(basename "$dir")
        local is_known=false
        if [ ${#allowed[@]} -gt 0 ]; then
            local a
            for a in "${allowed[@]}"; do
                if [ "$a" = "$base" ]; then is_known=true; break; fi
            done
        fi
        if ! $is_known; then
            local sp
            for sp in "${special[@]}"; do
                if [ "$sp" = "$base" ]; then is_known=true; break; fi
            done
        fi
        $is_known && continue
        local size
        size=$(du -sh --one-file-system -- "$dir" 2>/dev/null | awk '{print $1}')
        [ -n "$size" ] && echo "  Unknown /var/cache directory (not cleared): $dir ($size)"
    done < <(find /var/cache -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
}

clear_flatpak_repo_tmp() {
    local dir="/var/lib/flatpak/repo/tmp"
    [ -d "$dir" ] || return 0
    [ ! -L "$dir" ] || return 0
    if [ -n "$(find "$dir" -mindepth 1 -print -quit 2>/dev/null)" ]; then
        echo "Clearing contents of $dir"
        if [ "$EUID" -eq 0 ]; then
            find "$dir" -mindepth 1 -delete 2>/dev/null || true
        else
            sudo find "$dir" -mindepth 1 -delete 2>/dev/null || true
        fi
    fi
}

# ---------------------- MAIN CLEANUP LOGIC ----------------------
run_cleanup() {
    echo ""
    echo "=== INTERACTIVE CLEANUP ==="
    echo ""

    local main_mount
    local main_free_before=0
    main_mount=$(_get_main_mount)
    if [ -n "$main_mount" ]; then
        main_free_before=$(df -B1 --output=avail "$main_mount" 2>/dev/null | tail -n 1 | tr -d ' ')
    fi
    [ -n "$main_free_before" ] || main_free_before=0
    echo "Main drive: ${main_mount:-unknown}"
    echo "Free space before: $(_format_bytes "$main_free_before")"
    echo ""

    local do_dev_prune=false
    local do_dev_aggressive=false
    local do_ai=false
    local do_system=false
    local do_search=false
    local restart_search=false
    local do_browser=false
    local do_backup=false
    local do_upload=false
    local do_downloads=false
    local do_download_installers=false
    local do_containers=false
    local pixeldrain_key=""

    ask_yn "Prune unused developer-tool caches (npm, pnpm, uv, Composer, mise)?" && do_dev_prune=true
    ask_yn "Fully clear redownloadable developer caches, mise tool installations, and project dependencies?" && do_dev_aggressive=true
    ask_yn "Delete AI agent caches and logs (preserve settings, sessions, and history)?" && do_ai=true
    ask_yn "Clear system temp files, thumbnails, APT package cache, and general /var/cache contents?" && do_system=true
    ask_yn "Rebuild search index (GNOME Tracker / KDE Baloo)?" && do_search=true
    if $do_search; then
        ask_yn "Turn search service back on after cleanup?" && restart_search=true
    fi
    ask_yn "Clear browser caches (keep sessions/logins)?" && do_browser=true
    ask_yn "Delete old Downloads, Trash, and installer binaries (ZIP, DEB, TAR, etc.) older than 1 week?" && do_downloads=true && do_download_installers=true
    ask_yn "Clear container/VM caches (virt-manager, etc.)?" && do_containers=true
    ask_yn "Create a local tar.gz backup of filesystem targets before deleting?" && do_backup=true
    if $do_backup && ask_yn "Upload the local backup to PixelDrain?"; then
        do_upload=true
        read -rsp "Pixeldrain API key (leave blank for anonymous upload): " pixeldrain_key
        echo ""
    fi

    local all_targets=()
    local dev_targets=()
    local dependency_targets=()
    local ai_targets=()
    local system_targets=()
    local temp_targets=()
    local search_targets=()
    local browser_targets=()
    local downloads_targets=()
    local download_installer_targets=()
    local container_targets=()

    if $do_dev_aggressive; then
        while IFS= read -r line; do dev_targets+=("$line"); done < <(get_dev_cache_targets)
        all_targets+=("${dev_targets[@]}")
    fi
    if $do_dev_aggressive; then
        while IFS= read -r line; do dependency_targets+=("$line"); done < <(_get_dependency_targets)
        all_targets+=("${dependency_targets[@]}")
    fi
    if $do_ai; then
        while IFS= read -r line; do ai_targets+=("$line"); done < <(get_ai_cache_targets)
        all_targets+=("${ai_targets[@]}")
    fi
    if $do_system; then
        while IFS= read -r line; do system_targets+=("$line"); done < <(get_system_temp_targets)
        all_targets+=("${system_targets[@]}")
        if ! command -v systemd-tmpfiles >/dev/null 2>&1; then
            while IFS= read -r line; do temp_targets+=("$line"); done < <(get_temp_fallback_targets)
            all_targets+=("${temp_targets[@]}")
        fi
    fi
    if $do_search; then
        while IFS= read -r line; do search_targets+=("$line"); done < <(get_search_index_targets)
        all_targets+=("${search_targets[@]}")
    fi
    if $do_browser; then
        while IFS= read -r line; do browser_targets+=("$line"); done < <(get_browser_cache_targets)
        all_targets+=("${browser_targets[@]}")
    fi
    if $do_downloads; then
        while IFS= read -r line; do downloads_targets+=("$line"); done < <(get_downloads_trash_targets)
        all_targets+=("${downloads_targets[@]}")
    fi
    if $do_download_installers; then
        while IFS= read -r line; do download_installer_targets+=("$line"); done < <(get_download_installer_targets)
        all_targets+=("${download_installer_targets[@]}")
    fi
    if $do_containers; then
        while IFS= read -r line; do container_targets+=("$line"); done < <(get_container_targets)
        all_targets+=("${container_targets[@]}")
    fi

    local backup_archive=""
    if $do_backup && [ ${#all_targets[@]} -gt 0 ]; then
        echo ""
        echo "--- Creating backup archive ---"
        backup_archive=$(_create_backup "${all_targets[@]}") || backup_archive=""
        if [ -n "$backup_archive" ] && [ -f "$backup_archive" ]; then
            echo "Backup created: $backup_archive"
            if $do_upload; then
                local resp
                resp=$(_upload_pixeldrain "$backup_archive" "$pixeldrain_key") || resp=""
                if [ -n "$resp" ]; then
                    _save_backup_metadata "$resp" "$backup_archive"
                    echo "Backup uploaded to PixelDrain."
                else
                    echo "PixelDrain upload failed." >&2
                fi
            fi
        fi
    fi

    if $do_dev_prune; then
        echo ""
        echo "--- Pruning developer-tool caches ---"
        _run_tool npm "Verifying and pruning npm cache..." cache verify
        _run_tool pnpm "Pruning pnpm store..." store prune
        _run_tool uv "Pruning uv cache..." cache prune
        _run_tool composer "Garbage-collecting Composer cache..." clear-cache --gc
        _run_mise_tool "Pruning mise cache..." cache prune
    fi

    if $do_dev_aggressive; then
        echo ""
        echo "--- Fully clearing developer caches and dependencies ---"
        _delete_targets "${dev_targets[@]}" "${dependency_targets[@]}"
        _run_tool npm "Clearing npm cache..." cache clean --force
        _run_tool yarn "Clearing Yarn cache..." cache clean
        _run_tool bun "Clearing Bun cache..." pm cache rm --global
        if command -v pip >/dev/null 2>&1; then
            _run_tool pip "Clearing pip cache..." cache purge
        else
            _run_tool pip3 "Clearing pip cache..." cache purge
        fi
        _run_tool conda "Clearing Conda caches..." clean --all -y
        _run_tool poetry "Clearing Poetry caches..." --no-interaction cache clear --all
        _run_tool uv "Clearing uv cache..." cache clean
        _run_tool go "Clearing Go build, test, module, and fuzz caches..." clean -cache -testcache -modcache -fuzzcache
        _run_tool composer "Clearing Composer cache..." clear-cache
        _run_tool dotnet "Clearing NuGet caches..." nuget locals all --clear
        if command -v dart >/dev/null 2>&1; then
            _run_tool dart "Clearing Dart Pub cache..." pub cache clean --force
        else
            _run_tool flutter "Clearing Flutter Pub cache..." pub cache clean --force
        fi
        _run_mise_tool "Clearing mise cache..." cache clear
        _run_mise_tool "Removing all mise-managed tool installations..." uninstall --all --yes
    fi

    if $do_ai; then
        echo ""
        echo "--- Deleting AI agent caches ---"
        for path in "${ai_targets[@]}"; do
            if [ -e "$path" ]; then
                echo "Deleting $path"
                rm -rf "$path"
            fi
        done
    fi

    if $do_system; then
        echo ""
        echo "--- Cleaning system temp files ---"
        if command -v systemd-tmpfiles >/dev/null 2>&1; then
            systemd-tmpfiles --user --clean 2>/dev/null || true
            sudo systemd-tmpfiles --clean 2>/dev/null || systemd-tmpfiles --clean 2>/dev/null || true
        else
            _delete_targets "${temp_targets[@]}"
        fi
        _delete_targets "${system_targets[@]}"
        if command -v apt-get >/dev/null 2>&1; then
            echo "Removing obsolete APT packages (apt-get autoclean)..."
            sudo apt-get autoclean 2>/dev/null || true
            echo "Cleaning APT package cache (apt-get clean)..."
            sudo apt-get clean 2>/dev/null || apt-get clean 2>/dev/null || true
        elif command -v apt >/dev/null 2>&1; then
            echo "Cleaning APT package cache..."
            sudo apt clean 2>/dev/null || apt clean 2>/dev/null || true
        fi
        echo "Clearing allowed /var/cache directories..."
        clear_var_cache_contents
        echo "Review of other /var/cache directories:"
        report_var_cache_summary
        echo "Clearing Flatpak repo temp directory..."
        clear_flatpak_repo_tmp
        if command -v journalctl >/dev/null 2>&1; then
            echo "Vacuuming systemd journals..."
            sudo journalctl --vacuum-time=3d 2>/dev/null || journalctl --vacuum-time=3d 2>/dev/null || true
        fi
    fi

    if $do_search; then
        echo ""
        echo "--- Rebuilding search index ---"
        if command -v tracker3 >/dev/null 2>&1; then
            echo "Resetting GNOME Tracker index..."
            tracker3 reset --hard 2>/dev/null || true
        elif command -v tracker >/dev/null 2>&1; then
            echo "Resetting Tracker index..."
            tracker reset --hard 2>/dev/null || true
        fi
        if command -v balooctl >/dev/null 2>&1; then
            echo "Purging KDE Baloo index..."
            balooctl purge 2>/dev/null || true
            if $restart_search; then
                echo "Restarting Baloo..."
                balooctl enable 2>/dev/null || true
            else
                echo "Leaving Baloo disabled."
                balooctl disable 2>/dev/null || true
            fi
        fi
        if [ ${#search_targets[@]} -gt 0 ]; then
            for path in "${search_targets[@]}"; do
                if [ -e "$path" ]; then
                    echo "Deleting $path"
                    rm -rf "$path"
                fi
            done
        fi
    fi

    if $do_browser; then
        echo ""
        echo "--- Cleaning browser caches ---"
        for path in "${browser_targets[@]}"; do
            if [ -e "$path" ]; then
                echo "Clearing cache: $path"
                rm -rf "$path"
            fi
        done
    fi

    if $do_downloads; then
        echo ""
        echo "--- Deleting Downloads and Trash items older than 1 week ---"
        _delete_targets "${downloads_targets[@]}"
    fi
    if $do_download_installers; then
        echo ""
        echo "--- Deleting old installer binaries from Downloads ---"
        _delete_targets "${download_installer_targets[@]}"
    fi

    if $do_containers; then
        echo ""
        echo "--- Deleting container/VM caches ---"
        for path in "${container_targets[@]}"; do
            if [ -e "$path" ]; then
                echo "Deleting $path"
                rm -rf "$path"
            fi
        done
    fi

    local main_free_after=0
    if [ -n "$main_mount" ]; then
        main_free_after=$(df -B1 --output=avail "$main_mount" 2>/dev/null | tail -n 1 | tr -d ' ')
    fi
    [ -n "$main_free_after" ] || main_free_after=0
    local saved=$(( main_free_after - main_free_before ))
    [ "$saved" -lt 0 ] 2>/dev/null && saved=0
    echo ""
    echo "Cleanup finished. Restart is recommended."
    echo "Free space after:  $(_format_bytes "$main_free_after")"
    echo "Approximate disk space saved on ${main_mount:-main drive}: $(_format_bytes "$saved")"
}

_get_main_mount() {
    df -P "$HOME" 2>/dev/null | awk 'NR==2 {print $NF}'
}

_format_bytes() {
    local bytes="$1"
    if command -v numfmt >/dev/null 2>&1; then
        numfmt --to=iec --suffix=B "$bytes" 2>/dev/null || echo "${bytes}B"
    else
        echo "${bytes}B"
    fi
}

# ---------------------- ENTRY POINT ----------------------
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run_cleanup
fi
# ======================================================================

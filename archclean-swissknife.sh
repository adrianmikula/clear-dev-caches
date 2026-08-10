#!/usr/bin/env bash
# ======================================================================
# INTERACTIVE FULL CLEANUP – SAFE VERSION WITH CLI + PIXELDRAIN BACKUP
# Arch Linux edition
# Created by @LizzieNya
# ======================================================================
set -uo pipefail

# ---------------------- HELPERS ----------------------
ask_yn() {
    local msg="$1"
    local ans
    read -rp "$msg (y/n) " ans
    [[ "$ans" =~ ^[Yy] ]]
}

create_backup() {
    local workdir="/tmp/winclean-backups"
    mkdir -p "$workdir"
    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    local archive="$workdir/cleanup-backup-$timestamp.tar.gz"
    local existing=()
    for p in "$@"; do
        [ -e "$p" ] && existing+=("$p")
    done
    if [ ${#existing[@]} -eq 0 ]; then
        echo "No existing paths to backup."
        return 1
    fi
    if tar -czf "$archive" -C / "${existing[@]/#/}"; then
        echo "$archive"
        return 0
    else
        echo "Failed to create backup archive." >&2
        return 1
    fi
}

upload_pixeldrain() {
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
    if [ -n "$resp" ]; then
        echo "$resp"
        return 0
    else
        echo "Pixeldrain upload failed." >&2
        return 1
    fi
}

save_backup_metadata() {
    local resp="$1"
    local archive="$2"
    [ -n "$resp" ] || return
    local metafile
    metafile="${archive%.tar.gz}.pixeldrain.json"
    cat > "$metafile" <<EOF
{
  "uploaded_at": "$(date -Iseconds)",
  "archive_path": "$archive",
  "pixeldrain": $resp
}
EOF
    echo "Metadata saved to $metafile"
}

# ---------------------- TARGET SETS ----------------------
get_dev_cache_targets() {
    local home="$HOME"
    local targets=(
        "$home/.cache"
        "$home/.npm"
        "$home/npm-cache"
        "$home/.bun"
        "$home/.gradle"
        "$home/.flutter"
        "$home/.m2"
        "$home/.matplotlib"
        "$home/.idea"
        "$home/.vs"
        "$home/.vs-kubernetes"
        "$home/.cursor"
        "$home/.ollama"
        "$home/.bito"
        "$home/.llama"
        "$home/.VirtualBox"
        "$home/.docker"
    )
    while IFS= read -r -d '' dir; do
        targets+=("$dir")
    done < <(find "$home" -type d -name node_modules -print0 2>/dev/null)
    for t in "${targets[@]}"; do
        [ -e "$t" ] && echo "$t"
    done
}

get_system_temp_targets() {
    local targets=(
        "/tmp/*"
        "/var/tmp/*"
        "$HOME/.cache/thumbnails"
    )
    for t in "${targets[@]}"; do
        echo "$t"
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

# ---------------------- MAIN CLEANUP LOGIC ----------------------
run_cleanup() {
    echo ""
    echo "=== INTERACTIVE CLEANUP ==="
    echo ""

    local do_dev=false
    local do_system=false
    local do_search=false
    local restart_search=false
    local do_browser=false
    local do_backup=false
    local pixeldrain_key=""

    ask_yn "Delete developer caches and build artifacts (npm, pip, conda, docker, gradle, flutter, etc.)?" && do_dev=true
    ask_yn "Clear system temp files, thumbnails, and Pacman package cache?" && do_system=true
    ask_yn "Rebuild search index (GNOME Tracker / KDE Baloo)?" && do_search=true
    if $do_search; then
        ask_yn "Turn search service back on after cleanup?" && restart_search=true
    fi
    ask_yn "Clear browser caches (keep sessions/logins)?" && do_browser=true
    ask_yn "Create tar.gz backup before deleting?" && do_backup=true
    if $do_backup; then
        read -rsp "Pixeldrain API key (leave blank for anonymous upload): " pixeldrain_key
        echo ""
    fi

    local all_targets=()
    local dev_targets=()
    local system_targets=()
    local search_targets=()
    local browser_targets=()

    if $do_dev; then
        while IFS= read -r line; do dev_targets+=("$line"); done < <(get_dev_cache_targets)
        all_targets+=("${dev_targets[@]}")
    fi
    if $do_system; then
        while IFS= read -r line; do system_targets+=("$line"); done < <(get_system_temp_targets)
        all_targets+=("${system_targets[@]}")
    fi
    if $do_search; then
        while IFS= read -r line; do search_targets+=("$line"); done < <(get_search_index_targets)
        all_targets+=("${search_targets[@]}")
    fi
    if $do_browser; then
        while IFS= read -r line; do browser_targets+=("$line"); done < <(get_browser_cache_targets)
        all_targets+=("${browser_targets[@]}")
    fi

    local backup_archive=""
    if $do_backup && [ ${#all_targets[@]} -gt 0 ]; then
        echo ""
        echo "--- Creating backup archive ---"
        backup_archive=$(create_backup "${all_targets[@]}") || backup_archive=""
        if [ -n "$backup_archive" ] && [ -f "$backup_archive" ]; then
            echo "Backup created: $backup_archive"
            local resp
            resp=$(upload_pixeldrain "$backup_archive" "$pixeldrain_key") || resp=""
            if [ -n "$resp" ]; then
                save_backup_metadata "$resp" "$backup_archive"
                local id link
                id=$(echo "$resp" | python3 -c "import sys, json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null || true)
                link=$(echo "$resp" | python3 -c "import sys, json; print(json.load(sys.stdin).get('link',''))" 2>/dev/null || true)
                echo "Backup uploaded. ID: ${id:-unknown}  Link: ${link:-unknown}"
            fi
        fi
    fi

    if $do_dev; then
        echo ""
        echo "--- Deleting developer caches ---"
        for path in "${dev_targets[@]}"; do
            if [ -e "$path" ]; then
                echo "Deleting $path"
                rm -rf "$path"
            fi
        done
        # LM Studio partial cleanup
        local lm_path="$HOME/.lmstudio"
        if [ -d "$lm_path" ]; then
            echo ""
            echo "Cleaning LM Studio cache (keeping history & settings)"
            find "$lm_path" -mindepth 1 -maxdepth 1 | while IFS= read -r item; do
                local name
                name=$(basename "$item")
                if [ "$name" != "history" ] && [ "$name" != "settings.json" ]; then
                    rm -rf "$item"
                fi
            done
        fi
        # Tool-specific cache purges
        command -v pip >/dev/null 2>&1 && { echo "Purging pip cache..."; pip cache purge 2>/dev/null || true; }
        command -v conda >/dev/null 2>&1 && { echo "Cleaning conda..."; conda clean --all -y 2>/dev/null || true; }
        command -v npm >/dev/null 2>&1 && { echo "Cleaning npm cache..."; npm cache clean --force 2>/dev/null || true; }
        # Find all python executables and purge their pip caches
        while IFS= read -r -d '' py; do
            echo "Purging pip cache for $py"
            "$py" -m pip cache purge 2>/dev/null || true
        done < <(find "$HOME" -type f -name python -print0 2>/dev/null)
        while IFS= read -r -d '' py; do
            echo "Purging pip cache for $py"
            "$py" -m pip cache purge 2>/dev/null || true
        done < <(find "$HOME" -type f -name python3 -print0 2>/dev/null)
    fi

    if $do_system; then
        echo ""
        echo "--- Deleting system temp files ---"
        rm -rf /tmp/* 2>/dev/null || true
        rm -rf /var/tmp/* 2>/dev/null || true
        rm -rf "$HOME/.cache/thumbnails" 2>/dev/null || true
        # Pacman package cache
        if command -v pacman >/dev/null 2>&1; then
            echo "Cleaning Pacman package cache..."
            sudo pacman -Sc --noconfirm 2>/dev/null || pacman -Sc --noconfirm 2>/dev/null || true
            echo "Removing unused Pacman packages..."
            sudo pacman -Qdtq | sudo pacman -Rs - --noconfirm 2>/dev/null || true
        fi
        # systemd journal
        if command -v journalctl >/dev/null 2>&1; then
            echo "Vacuuming systemd journals..."
            sudo journalctl --vacuum-time=3d 2>/dev/null || journalctl --vacuum-time=3d 2>/dev/null || true
        fi
    fi

    if $do_search; then
        echo ""
        echo "--- Rebuilding search index ---"
        # GNOME Tracker
        if command -v tracker3 >/dev/null 2>&1; then
            echo "Resetting GNOME Tracker index..."
            tracker3 reset --hard 2>/dev/null || true
        elif command -v tracker >/dev/null 2>&1; then
            echo "Resetting Tracker index..."
            tracker reset --hard 2>/dev/null || true
        fi
        # KDE Baloo
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

    echo ""
    echo "Cleanup finished. Restart is recommended."
}

# ---------------------- ENTRY POINT ----------------------
run_cleanup
# ======================================================================

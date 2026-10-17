#!/usr/bin/env bash

set -euo pipefail

# ==========================================
# 1. VARIABLES & ENVIRONMENT
# ==========================================
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(realpath "$SCRIPT_DIR/..")"

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

INSTALL_LAPTOP_POWER=false
for arg in "$@"; do
    case "$arg" in
        --laptop-power)
            INSTALL_LAPTOP_POWER=true
            ;;
        -h|--help)
            echo "Usage: $0 [--laptop-power]"
            echo "  --laptop-power  Install and enable this laptop's CPU/GPU/display power settings."
            exit 0
            ;;
        *)
            echo "Unknown option: $arg" >&2
            echo "Usage: $0 [--laptop-power]" >&2
            exit 2
            ;;
    esac
done

# ==========================================
# 2. PACKAGE INSTALLATION
# ==========================================
# Other package managers
sudo pacman -Sy --needed paru flatpak

# Install packages from standard Arch repositories
sudo pacman -S --needed $(grep -vE '^\s*(#|$)' "$SCRIPT_DIR/_packages/pacman.txt")

# Install AUR packages using paru
paru -S --needed $(grep -vE '^\s*(#|$)' "$SCRIPT_DIR/_packages/aur.txt")

# Run any custom installation commands (e.g., rustup, nvm, etc.)
while read -r cmd; do
    [[ -z "$cmd" || "$cmd" =~ ^# ]] && continue

    tmpdir=$(mktemp -d)
    (
        cd "$tmpdir"
        eval "$cmd"
    )
    rm -rf "$tmpdir"
done < "$SCRIPT_DIR/_packages/external.txt"

# ==========================================
# 3. MANUAL INSTALLATIONS
# ==========================================
echo
echo "==========================="
echo "The following apps cannot be installed automatically:"
echo

# Display instructions for apps that require manual installation
while IFS='|' read -r name type url; do
    [[ -z "$name" || "$name" =~ ^# ]] && continue

    echo "$name ($type)"
    echo "  Visit: $url"
    echo
done < "$SCRIPT_DIR/_packages/manual.txt"

echo "==========================="
echo

# ==========================================
# 4. LINKING & DEPLOYMENT
# ==========================================
# Helper: Expand ~ to the user's home directory
expand_path() {
    local path="$1"
    printf '%s\n' "${path/#\~/$HOME}"
}

# Helper: Run command with sudo if the destination is a protected system directory
run() {
    if [[ "$dst" == /etc/* || "$dst" == /usr/* || "$dst" == /boot/* ]]; then
        sudo "$@"
    else
        "$@"
    fi
}

# Parse apps.txt to link, copy, or merge dotfiles into their correct locations
while IFS='|' read -r src dst method; do
    # Skip comments and empty lines
    [[ -z "${src// }" || "$src" =~ ^[[:space:]]*# ]] && continue

    # Default to symlink if no method is specified
    method="${method:-symlink}"

    src="$DOTFILES_ROOT/$src"

    if [[ ! -e "$src" ]]; then
        echo "[ERROR] Source not found: %s\n" "${src#$DOTFILES_ROOT/}" >&2
        continue
    fi

    src="$(realpath "$src")"

    # Default destination is ~/.config/<basename> if not specified
    if [[ -z "$dst" ]]; then
        dst="$CONFIG_HOME/$(basename "$src")"
    else
        dst="$(expand_path "$dst")"
    fi

    # Ensure the parent directory of the destination exists
    run mkdir -p "$(dirname "$dst")"

    case "$method" in
        symlink)
            run rm -rf "$dst"
            run ln -sfn "$src" "$dst"
            printf "[LINK]  %-30s -> %s\n" "${src#$DOTFILES_ROOT/}" "$dst"
            ;;

        copy)
            run rm -rf "$dst"
            run cp -a "$src" "$dst"
            printf "[COPY]  %-30s -> %s\n" "${src#$DOTFILES_ROOT/}" "$dst"
            ;;

        merge)
            run mkdir -p "$dst"
            run cp -a "$src/." "$dst/"
            printf "[MERGE] %-30s -> %s\n" "${src#$DOTFILES_ROOT/}" "$dst"
            ;;

        *)
            echo "[ERROR] Unknown method '%s' for '%s'\n" "$method" "${src#$DOTFILES_ROOT/}"
            ;;
    esac
done < "$SCRIPT_DIR/apps.txt"

# ==========================================
# 5. LAPTOP POWER (OPTIONAL)
# ==========================================
if [[ "$INSTALL_LAPTOP_POWER" == true ]]; then
    sudo bash "$SCRIPT_DIR/_scripts/laptop-power/install.sh"
fi

# ==========================================
# 6. FINALIZATION
# ==========================================
# Change default shell to zsh
chsh -s $(which zsh)

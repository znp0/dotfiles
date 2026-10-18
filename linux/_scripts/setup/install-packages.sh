#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$SCRIPT_DIR/../../_packages"

if [[ $# -ne 0 ]]; then
    echo "Usage: $0" >&2
    exit 2
fi

read_packages() {
    local line
    while IFS= read -r line || [[ -n $line ]]; do
        [[ $line =~ ^[[:space:]]*(#|$) ]] && continue
        printf '%s\n' "$line"
    done < "$1"
}

for manifest in pacman aur external manual; do
    if [[ ! -r $PACKAGE_DIR/$manifest.txt ]]; then
        echo "Error: Cannot read package manifest: $PACKAGE_DIR/$manifest.txt" >&2
        exit 1
    fi
done
mapfile -t pacman_packages < <(read_packages "$PACKAGE_DIR/pacman.txt")
mapfile -t aur_packages < <(read_packages "$PACKAGE_DIR/aur.txt")

# Keep package installation separate from config and command deployment.
sudo pacman -S --needed paru flatpak
if [[ ${#pacman_packages[@]} -gt 0 ]]; then
    sudo pacman -S --needed "${pacman_packages[@]}"
fi

if [[ ${#aur_packages[@]} -gt 0 ]]; then
    paru -S --needed "${aur_packages[@]}"
fi

while IFS= read -r command_line || [[ -n $command_line ]]; do
    [[ $command_line =~ ^[[:space:]]*(#|$) ]] && continue
    (
        work_dir=$(mktemp -d)
        trap 'rm -rf -- "$work_dir"' EXIT
        cd -- "$work_dir"
        bash -o pipefail -c "$command_line"
    )
done < "$PACKAGE_DIR/external.txt"

echo "The following apps require manual installation:"
while IFS='|' read -r name type url || [[ -n $name ]]; do
    [[ $name =~ ^[[:space:]]*(#|$) ]] && continue
    printf '  %s (%s): %s\n' "$name" "$type" "$url"
done < "$PACKAGE_DIR/manual.txt"

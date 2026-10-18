#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
COMMAND_DIR="$(realpath -- "$SCRIPT_DIR/../../_bin")"
BIN_DIR="$HOME/.local/bin"
DEPLOY_PRIVILEGED=false
source "$SCRIPT_DIR/_deploy.sh"

if [[ $# -ne 0 ]]; then
    echo "Usage: $0" >&2
    exit 2
fi

# Validate all commands before changing any installed entry.
for command_path in "$COMMAND_DIR"/*; do
    [[ -e $command_path || -L $command_path ]] || continue
    if [[ ! -f $command_path || ! -x $command_path ]]; then
        echo "Error: Command must be an executable file: $command_path" >&2
        exit 1
    fi
done

for command_path in "$COMMAND_DIR"/*; do
    [[ -f $command_path ]] || continue
    deploy_link "$command_path" "$BIN_DIR/${command_path##*/}"
done

case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *) echo "Add $BIN_DIR to PATH, or start a new login session after shell setup." ;;
esac

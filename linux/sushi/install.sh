#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
DEPLOY_PRIVILEGED=false
source "$SCRIPT_DIR/../_scripts/setup/_deploy.sh"

if [[ $# -ne 0 ]]; then
    echo "Usage: $0" >&2
    exit 2
fi

for file in onlyoffice.js onlyoffice-convert.mjs; do
    deploy_link "$SCRIPT_DIR/plugins-1/$file" "$DATA_HOME/sushi/plugins-1/$file"
done

echo "OnlyOffice previews installed. Close any Sushi preview and allow its service to exit before previewing an Office file."

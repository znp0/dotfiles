#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 0 ]]; then
    echo "Usage: $0" >&2
    exit 2
fi

if ! zsh_path=$(command -v zsh); then
    echo "Error: Install zsh before setting up the login shell." >&2
    exit 1
fi
current_shell=$(getent passwd "$(id -un)" | cut -d: -f7)
if [[ $current_shell == "$zsh_path" ]]; then
    echo "Login shell is already zsh."
else
    chsh -s "$zsh_path"
fi

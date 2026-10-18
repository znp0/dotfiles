#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

INSTALL_LAPTOP_POWER=false
HOST_PROFILE=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --host)
            if [[ $# -lt 2 || -z ${2:-} || -n $HOST_PROFILE ]]; then
                echo "Error: Supply --host <profile> exactly once." >&2
                exit 2
            fi
            HOST_PROFILE=$2
            shift 2
            ;;
        --laptop-power) INSTALL_LAPTOP_POWER=true; shift ;;
        -h|--help)
            echo "Usage: $0 [--host <profile>] [--laptop-power]"
            echo "  --host          Select a profile from linux/_hosts/."
            echo "  --laptop-power  Install power settings from the selected host profile."
            echo "Individual setup steps are available in linux/_scripts/setup/."
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 2
            ;;
    esac
done

if [[ -n $HOST_PROFILE ]]; then
    if [[ ! $HOST_PROFILE =~ ^[[:alnum:]][[:alnum:]_.-]*$ || ! -d $SCRIPT_DIR/_hosts/$HOST_PROFILE ]]; then
        echo "Error: Unknown host profile: $HOST_PROFILE" >&2
        exit 1
    fi
fi
if [[ $INSTALL_LAPTOP_POWER == true ]]; then
    if [[ -z $HOST_PROFILE ]]; then
        echo "Error: --laptop-power requires --host <profile>." >&2
        exit 2
    fi
    # Reject invalid profiles before installing packages or deploying configs.
    source "$SCRIPT_DIR/_scripts/laptop-power/_profile.sh"
    load_laptop_profile "$SCRIPT_DIR" "$HOST_PROFILE"
fi

bash "$SCRIPT_DIR/_scripts/setup/install-packages.sh"
bash "$SCRIPT_DIR/_scripts/setup/link-configs.sh"
bash "$SCRIPT_DIR/_scripts/setup/install-commands.sh"

if [[ $INSTALL_LAPTOP_POWER == true ]]; then
    sudo bash "$SCRIPT_DIR/_scripts/laptop-power/install.sh" --host "$HOST_PROFILE"
fi

bash "$SCRIPT_DIR/_scripts/setup/setup-shell.sh"

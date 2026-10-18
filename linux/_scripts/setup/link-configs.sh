#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(realpath -- "$SCRIPT_DIR/../../..")"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
source "$SCRIPT_DIR/_deploy.sh"

if [[ $# -ne 0 ]]; then
    echo "Usage: $0" >&2
    exit 2
fi

# Validate every entry before deploying any config.
sources=() destinations=() methods=()
while IFS='|' read -r source_path destination method extra || [[ -n $source_path ]]; do
    [[ $source_path =~ ^[[:space:]]*(#|$) ]] && continue
    method=${method:-symlink}
    source_path="$DOTFILES_ROOT/$source_path"
    if [[ ! -e $source_path || -n $extra ]]; then
        echo "Error: Invalid config source or manifest entry: $source_path" >&2
        exit 1
    fi
    source_path=$(realpath -- "$source_path")
    if [[ -z $destination ]]; then
        destination="$CONFIG_HOME/$(basename -- "$source_path")"
    elif [[ $destination == '~/'* ]]; then
        destination="$HOME/${destination:2}"
    fi
    if [[ $destination != /* ]]; then
        echo "Error: Config destination must be absolute: $destination" >&2
        exit 1
    fi
    # Normalize dot segments and the parent without following the final symlink.
    destination=$(realpath -ms -- "$destination")
    if [[ $destination == / ]]; then
        echo "Error: Refusing unsafe config destination: $destination" >&2
        exit 1
    fi
    destination="$(realpath -m -- "$(dirname -- "$destination")")/$(basename -- "$destination")"
    if [[ $destination == "$HOME" ||
          $DOTFILES_ROOT == "$destination" || $DOTFILES_ROOT == "$destination/"* ||
          $destination == "$DOTFILES_ROOT/"* || $HOME == "$destination/"* ]]; then
        echo "Error: Refusing unsafe config destination: $destination" >&2
        exit 1
    fi
    case "$method" in
        symlink|copy) ;;
        merge)
            if [[ ! -d $source_path || -L $destination ]]; then
                echo "Error: Merge requires a source directory and a destination without a symlink: $destination" >&2
                exit 1
            fi ;;
        *) echo "Error: Unknown deployment method: $method" >&2; exit 1 ;;
    esac
    for previous in "${destinations[@]}"; do
        if [[ $destination == "$previous" || $destination == "$previous/"* || $previous == "$destination/"* ]]; then
            echo "Error: Overlapping config destinations: $previous and $destination" >&2
            exit 1
        fi
    done
    sources+=("$source_path") destinations+=("$destination") methods+=("$method")
done < "$SCRIPT_DIR/../../apps.txt"

for index in "${!sources[@]}"; do
    destination=${destinations[index]}
    DEPLOY_PRIVILEGED=false
    case "$destination" in
        /etc/*|/usr/*|/boot/*|/var/*) DEPLOY_PRIVILEGED=true ;;
    esac
    if [[ ${methods[index]} == symlink ]]; then
        deploy_link "${sources[index]}" "$destination"
    else
        deploy_copy "${sources[index]}" "$destination" "${methods[index]}"
    fi
done

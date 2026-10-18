#!/usr/bin/bash
set -euo pipefail

source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
linux_dir=$(cd -- "$source_dir/../.." && pwd)
unit="$linux_dir/systemd/laptop-power.service"
source "$source_dir/_profile.sh"

host=""
check_only=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --host)
            if [[ $# -lt 2 || -z ${2:-} || -n $host ]]; then
                echo "Error: Supply --host <profile> exactly once." >&2
                exit 2
            fi
            host=$2
            shift 2
            ;;
        --check) check_only=true; shift ;;
        -h|--help)
            echo "Usage: $0 --host <profile> [--check]"
            echo "  --check  Validate the host profile, hardware, and service without installing."
            exit 0
            ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
    esac
done
if [[ -z $host ]]; then
    echo "Error: Laptop power installation requires --host <profile>." >&2
    exit 2
fi
load_laptop_profile "$linux_dir" "$host"
check_laptop_hardware
/usr/bin/systemd-analyze verify "$unit"
if [[ $check_only == true ]]; then
    echo "Laptop power profile '$host' and hardware checks passed."
    exit 0
fi
if [[ $EUID -ne 0 ]]; then
    echo "Run this installer with sudo, or use --check for read-only validation." >&2
    exit 1
fi

/usr/bin/install -d -o root -g root -m 0755 /etc/laptop-power
/usr/bin/install -o root -g root -m 0644 "$linux_dir/_hosts/$host/laptop-power.env" /etc/laptop-power/config.env
/usr/bin/install -d -o root -g root -m 0755 /usr/local/lib/laptop-power
/usr/bin/install -o root -g root -m 0644 "$source_dir/laptop-power.sh" /usr/local/lib/laptop-power/laptop-power.sh
/usr/bin/install -o root -g root -m 0644 "$unit" /etc/systemd/system/laptop-power.service
/usr/bin/systemctl daemon-reload
/usr/bin/systemctl enable laptop-power.service
/usr/bin/systemctl restart laptop-power.service
/usr/bin/systemctl --no-pager --full status laptop-power.service

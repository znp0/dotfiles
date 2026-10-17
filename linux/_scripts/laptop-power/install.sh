#!/usr/bin/bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Run this installer with sudo." >&2
    exit 1
fi

source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
linux_dir=$(cd -- "$source_dir/../.." && pwd)
unit="$linux_dir/systemd/laptop-power.service"
/usr/bin/systemd-analyze verify "$unit"
/usr/bin/install -d -o root -g root -m 0755 /usr/local/lib/laptop-power
/usr/bin/install -o root -g root -m 0644 "$source_dir/laptop-power.sh" /usr/local/lib/laptop-power/laptop-power.sh
/usr/bin/install -o root -g root -m 0644 "$unit" /etc/systemd/system/laptop-power.service
/usr/bin/systemctl daemon-reload
/usr/bin/systemctl enable laptop-power.service
/usr/bin/systemctl restart laptop-power.service
/usr/bin/systemctl --no-pager --full status laptop-power.service

#!/usr/bin/bash
set -u

# Settings come from linux/systemd/laptop-power.service.
online="/sys/class/power_supply/$AC_ADAPTER/online"
gpu="/sys/bus/pci/devices/$GPU"

cpu=/sys/devices/system/cpu/intel_pstate/max_perf_pct
runtime="/run/user/$(id -u "$DESKTOP_USER")"
last_state=
last_uptime=0

apply_settings() {
    local ac=$1 socket
    if [[ "$ac" == 1 ]]; then
        [[ -d "$gpu" ]] || printf '1\n' > /sys/bus/pci/rescan || return
        printf 'auto\n' > "$gpu/power/control" || return
    fi

    for socket in "$runtime"/niri.*.sock; do
        [[ -S "$socket" ]] || continue
        local mode=(custom-mode "$BATTERY_MODE")
        [[ "$ac" == 1 ]] && mode=(mode auto)
        timeout 10 runuser -u "$DESKTOP_USER" -- env \
            XDG_RUNTIME_DIR="$runtime" NIRI_SOCKET="$socket" \
            /usr/bin/niri msg output "$OUTPUT" "${mode[@]}" || return
    done

    # Lower the refresh rate first; leave the GPU attached if niri fails.
    if [[ "$ac" == 0 && "$(< "$online")" == 0 && -e "$gpu/remove" ]]; then
        printf '1\n' > "$gpu/remove" || return
    fi
    return 0
}

while true; do
    if [[ "$(< "$cpu")" != "$CPU_CAP" ]]; then
        printf '%s\n' "$CPU_CAP" > "$cpu"
    fi
    read -r ac < "$online" || { sleep 2; continue; }
    [[ "$ac" == 0 || "$ac" == 1 ]] || { sleep 2; continue; }
    sockets=("$runtime"/niri.*.sock)
    state="$ac:${sockets[*]}"

    # /proc/uptime includes suspend time. Reapply after waking up.
    read -r uptime _ < /proc/uptime
    uptime=${uptime%%.*}
    (( uptime - last_uptime > 5 )) && last_state=
    last_uptime=$uptime

    if [[ "$state" != "$last_state" ]]; then
        if apply_settings "$ac"; then
            last_state=$state
        else
            echo "Failed to apply power settings; retrying in two seconds." >&2
        fi
    fi
    sleep 2
done

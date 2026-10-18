# Internal profile loading and read-only hardware checks; source from setup.

load_laptop_profile() {
    local linux_dir=$1 host=$2 profile line key value required
    local -A seen=()
    if [[ ! $host =~ ^[[:alnum:]][[:alnum:]_.-]*$ ]]; then
        echo "Error: Invalid host profile name: $host" >&2
        return 1
    fi
    profile="$linux_dir/_hosts/$host/laptop-power.env"
    if [[ ! -f $profile || ! -r $profile ]]; then
        echo "Error: Cannot read laptop power profile: $profile" >&2
        return 1
    fi

    # Parse plain KEY=VALUE assignments without executing profile contents.
    while IFS= read -r line || [[ -n $line ]]; do
        [[ $line =~ ^[[:space:]]*(#|$) ]] && continue
        if [[ ! $line =~ ^([A-Z_]+)=([^[:space:]]+)$ ]]; then
            echo "Error: Expected an unquoted KEY=VALUE assignment in $profile: $line" >&2
            return 1
        fi
        key=${BASH_REMATCH[1]} value=${BASH_REMATCH[2]}
        case "$key" in
            DESKTOP_USER|CPU_CAP|AC_ADAPTER|GPU|OUTPUT|BATTERY_MODE) ;;
            *) echo "Error: Unknown laptop power setting: $key" >&2; return 1 ;;
        esac
        if [[ -v seen[$key] ]]; then
            echo "Error: Duplicate laptop power setting: $key" >&2
            return 1
        fi
        seen[$key]=1
        printf -v "$key" '%s' "$value"
    done < "$profile"
    for required in DESKTOP_USER CPU_CAP AC_ADAPTER GPU OUTPUT BATTERY_MODE; do
        if [[ ! -v seen[$required] ]]; then
            echo "Error: Missing laptop power setting: $required" >&2
            return 1
        fi
    done
    if [[ ! $DESKTOP_USER =~ ^[a-zA-Z_][a-zA-Z0-9_.-]*\$?$ ||
          ! $CPU_CAP =~ ^([1-9][0-9]?|100)$ ||
          ! $AC_ADAPTER =~ ^[[:alnum:]][[:alnum:]_.-]*$ ||
          ! $GPU =~ ^[[:xdigit:]]{4}:[[:xdigit:]]{2}:[[:xdigit:]]{2}\.[0-7]$ ||
          ! $OUTPUT =~ ^[[:alnum:]][[:alnum:]_.-]*$ ||
          ! $BATTERY_MODE =~ ^[1-9][0-9]*x[1-9][0-9]*@[1-9][0-9]*([.][0-9]+)?$ ]]; then
        echo "Error: Invalid laptop power values in $profile" >&2
        return 1
    fi
}

check_laptop_hardware() {
    local sys_root=${1:-/sys} dependency online gpu_class connector
    local found_output=false
    for dependency in /usr/bin/niri /usr/bin/runuser /usr/bin/timeout; do
        if [[ ! -x $dependency ]]; then
            echo "Error: Required executable is missing: $dependency" >&2
            return 1
        fi
    done
    if ! /usr/bin/id -u "$DESKTOP_USER" >/dev/null 2>&1; then
        echo "Error: Desktop user does not exist: $DESKTOP_USER" >&2
        return 1
    fi
    for dependency in "$sys_root/devices/system/cpu/intel_pstate/max_perf_pct" \
                      "$sys_root/class/power_supply/$AC_ADAPTER/online" \
                      "$sys_root/bus/pci/rescan"; do
        if [[ ! -e $dependency ]]; then
            echo "Error: Required hardware control is missing: $dependency" >&2
            return 1
        fi
    done
    if ! read -r online < "$sys_root/class/power_supply/$AC_ADAPTER/online" ||
        [[ $online != 0 && $online != 1 ]]; then
        echo "Error: Cannot read AC adapter state for $AC_ADAPTER" >&2
        return 1
    fi
    if [[ -d $sys_root/bus/pci/devices/$GPU ]]; then
        if ! read -r gpu_class < "$sys_root/bus/pci/devices/$GPU/class" ||
            [[ $gpu_class != 0x03* ||
               ! -e $sys_root/bus/pci/devices/$GPU/remove ||
               ! -e $sys_root/bus/pci/devices/$GPU/power/control ]]; then
            echo "Error: $GPU must be a PCI display controller with removal and power controls." >&2
            return 1
        fi
    elif [[ $online == 0 ]]; then
        echo "GPU $GPU is absent on battery; it will be checked after rescan on AC."
    else
        echo "Error: Configured GPU $GPU is missing while on AC power." >&2
        return 1
    fi
    for connector in "$sys_root"/class/drm/card*-"$OUTPUT"; do
        if [[ -d $connector ]]; then
            found_output=true
            break
        fi
    done
    if [[ $found_output == false ]]; then
        echo "Error: Configured display output is missing: $OUTPUT" >&2
        return 1
    fi
}

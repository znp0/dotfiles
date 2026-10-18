# Shared deployment helpers. Source this file from a setup script.

deploy_run() {
    if [[ $DEPLOY_PRIVILEGED == true ]]; then
        sudo "$@"
    else
        "$@"
    fi
}

deploy_backup() {
    local destination=$1 backup_dir
    backup_dir=$(deploy_run mktemp -d -- "$destination.dotfiles-backup.$(date -u +%Y%m%dT%H%M%SZ).XXXXXX")
    deploy_run mv -- "$destination" "$backup_dir/"
    printf '[BACKUP] %s -> %s/\n' "$destination" "$backup_dir"
}

deploy_link() {
    local source=$1 destination=$2
    if [[ -L $destination && $(realpath -m -- "$destination") == "$source" ]]; then
        printf '[SKIP] %s already points to %s\n' "$destination" "$source"
        return
    fi
    deploy_run mkdir -p -- "$(dirname -- "$destination")"
    if [[ -e $destination || -L $destination ]]; then
        deploy_backup "$destination"
    fi
    deploy_run ln -sT -- "$source" "$destination"
    printf '[LINK] %s -> %s\n' "$destination" "$source"
}

# Return success if any source entry differs. Extra destination entries are kept.
deploy_merge_changed() {
    local source=$1 destination=$2 entry
    if [[ -L $source ]]; then
        [[ ! -L $destination ]] || [[ $(readlink -- "$source") != "$(readlink -- "$destination")" ]]
    elif [[ -d $source ]]; then
        [[ -d $destination && ! -L $destination ]] || return 0
        for entry in "$source"/* "$source"/.[!.]* "$source"/..?*; do
            [[ -e $entry || -L $entry ]] || continue
            if deploy_merge_changed "$entry" "$destination/${entry##*/}"; then
                return 0
            fi
        done
        return 1
    else
        [[ -f $destination && ! -L $destination ]] || return 0
        ! cmp -s -- "$source" "$destination" ||
            [[ $(stat -c %a -- "$source") != "$(stat -c %a -- "$destination")" ]]
    fi
}

# Only called on a temporary copy: remove conflicts before cp so destination
# symlinks cannot redirect writes into files outside that temporary tree.
deploy_prepare_overlay() {
    local source=$1 staged=$2 entry target
    for entry in "$source"/* "$source"/.[!.]* "$source"/..?*; do
        [[ -e $entry || -L $entry ]] || continue
        target="$staged/${entry##*/}"
        if [[ -d $entry && ! -L $entry && -d $target && ! -L $target ]]; then
            deploy_prepare_overlay "$entry" "$target"
        elif [[ -e $target || -L $target ]]; then
            deploy_run rm -rf -- "$target"
        fi
    done
}

deploy_copy() {
    local source=$1 destination=$2 method=$3 stage
    if [[ $method == merge && -L $destination ]]; then
        echo "Error: Refusing to merge into a symlink: $destination" >&2
        return 1
    fi
    if [[ $method == merge ]] && ! deploy_merge_changed "$source" "$destination"; then
        printf '[SKIP] %s already contains the requested config\n' "$destination"
        return
    fi
    if [[ $method == copy && ! -L $destination && -e $destination ]] &&
        ! deploy_merge_changed "$source" "$destination" &&
        ! deploy_merge_changed "$destination" "$source"; then
        printf '[SKIP] %s already matches the requested config\n' "$destination"
        return
    fi
    deploy_run mkdir -p -- "$(dirname -- "$destination")"
    stage=$(deploy_run mktemp -d -- "$(dirname -- "$destination")/.dotfiles-stage.XXXXXX")
    if [[ $method == merge && -d $destination ]]; then
        deploy_run cp -aT -- "$destination" "$stage/config"
        deploy_prepare_overlay "$source" "$stage/config"
        deploy_run cp -a -- "$source/." "$stage/config/"
    else
        deploy_run cp -aT -- "$source" "$stage/config"
    fi
    if [[ -e $destination || -L $destination ]]; then
        deploy_backup "$destination"
    fi
    deploy_run mv -T -- "$stage/config" "$destination"
    deploy_run rmdir -- "$stage"
    printf '[%s] %s -> %s\n' "${method^^}" "$source" "$destination"
}

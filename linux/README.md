# CachyOS setup

## Dual-booting with Windows

For more details, see `_docs/dual-boot/CachyOS_Windows.md`.

## Bootstrap

Run bootstrap as your normal user for package installation, config deployment,
command installation, and login-shell setup. Individual steps use `sudo` when
needed.

```bash
linux/bootstrap.sh
```

You can rerun any step independently, without installing packages or changing
your login shell when you only want to update configs or commands:

```bash
linux/_scripts/setup/install-packages.sh
linux/_scripts/setup/link-configs.sh
linux/_scripts/setup/install-commands.sh
linux/_scripts/setup/setup-shell.sh
```

`link-configs.sh` reads `apps.txt`, validates all entries, and skips existing
symlinks that already point to the right source. Conflicting destinations are
moved into timestamped `<destination>.dotfiles-backup.*` directories alongside
the destination; the backup path is printed. Copy and merge operations prepare
the replacement before backing up the original. Merge preserves unrelated files
and skips configs whose supplied files already match. System destinations,
including `/var/lib/noctalia-greeter`, are deployed with `sudo`.

To restore a deployment backup, move the current destination aside and move its
original entry out of the printed backup directory. Use `sudo` for system paths.

To also install this laptop's CPU cap and automatic AC/battery GPU and display
settings, explicitly select its host profile:

```bash
linux/bootstrap.sh --host zen --laptop-power
```

The power settings can also be installed separately without running the full bootstrap:

```bash
sudo bash linux/_scripts/laptop-power/install.sh --host zen
```

## Organization and commands

Directories without a leading `_` contain application configurations.
Supporting files are grouped in:

- `_bin/`: executable commands you use day to day, installed individually as
  symlinks in `~/.local/bin` without the `.sh` extension.
- `_scripts/setup/`: setup steps and their shared `_deploy.sh` helper.
  The leading `_` marks a helper that is sourced, rather than run directly.
- `_scripts/laptop-power/`: the power service helper and installer.
- `_hosts/`: device-specific configuration, selected explicitly with `--host`.
- `_packages/`: package lists and external installation commands.
- `_themes/`: theme bundles selected by `set-theme`.
- `_fonts/`: bundled font files.

Run `linux/_scripts/setup/install-commands.sh` after adding a command to `_bin/`. It
backs up conflicting command names and preserves other files in `~/.local/bin`.
The Zsh config already includes that directory in `PATH`. Other shells and
desktop sessions need it on their own `PATH` as well.

## Laptop power

Host settings live in [`_hosts/zen/laptop-power.env`](./_hosts/zen/laptop-power.env).
Edit that file to change the desktop user, CPU cap, AC adapter, GPU address,
display output, or battery display mode. Use plain, unquoted `KEY=VALUE` lines;
the installer validates the six supported settings without executing the file.
The service definition lives in
[`systemd/laptop-power.service`](./systemd/laptop-power.service), while the helper
and installer live in [`_scripts/laptop-power/`](./_scripts/laptop-power/).

Validate a profile and its hardware without installing or changing power settings:

```bash
bash linux/_scripts/laptop-power/install.sh --host zen --check
```

The checks require the configured user, Niri, Intel `intel_pstate` CPU controls,
AC adapter, and DRM display output. When present, the GPU must be a PCI display
controller with removal and power controls. An absent GPU is allowed on battery
because the service removes it there; its class is checked after rescan on AC.
These checks do not establish whether detaching a GPU is appropriate for a
different machine or whether its display supports the selected custom mode.

To configure another compatible machine, add
`_hosts/<profile>/laptop-power.env` with that machine's values and install using
`--host <profile>`. Profiles are never selected automatically from the hostname,
and laptop power remains opt-in with `--laptop-power` during bootstrap.

- CPU cap: `max_perf_pct=60` on AC and battery.
- Battery: set `eDP-1` to `2560x1600@60`, then remove GPU `0000:03:00.0`.
- AC: restore the GPU, set `power/control=auto`, then select the automatic display mode.

The helper checks AC every two seconds and applies changes at boot, when AC changes,
when a niri session starts, and after resume gaps longer than five seconds. Niri
commands run as `zen`; sysfs writes run as root. Failed commands are retried.

The installer copies the selected host profile to `/etc/laptop-power/config.env`
as a root-owned file. The service loads it through `EnvironmentFile=`. It also
copies the helper to `/usr/local/lib/laptop-power/` and the unit to
`/etc/systemd/system/`, then enables and restarts the service. Rerun the installer
after changing the profile, helper, or unit. The environment file is required;
there are no fallback hardware settings in the service definition.

```bash
systemctl status laptop-power.service
journalctl -u laptop-power.service -b
sudo systemctl disable --now laptop-power.service
```

Disabling leaves the current settings in place. To restore the defaults:

```bash
echo 100 | sudo tee /sys/devices/system/cpu/intel_pstate/max_perf_pct
echo 1 | sudo tee /sys/bus/pci/rescan
echo auto | sudo tee /sys/bus/pci/devices/0000:03:00.0/power/control
niri msg output eDP-1 mode auto
```

PCI removal detaches the GPU and may interrupt applications or displays using it.
It does not guarantee physical power-off; see the
[kernel documentation](https://docs.kernel.org/PCI/sysfs-pci.html).

## Set theme

After command installation, run `set-theme <theme_name>` from any directory to
recreate the symbolic links for theme configs:

```bash
set-theme boreal
```

You can also run `linux/_bin/set-theme boreal` directly from the repository.
The command resolves its installed symlink to locate the theme bundles.

When a theme includes a Noctalia config, switching (or reapplying) it backs up and
clears **all GUI overrides**, so settings from the previous theme do not carry
over. Noctalia reloads immediately when running; otherwise, the config is prepared
for its next launch. Later GUI changes can create new overrides.

Backups are timestamped files in `noctalia/theme-switch-backups/` under
`${NOCTALIA_STATE_HOME:-${XDG_STATE_HOME:-$HOME/.local/state}}`. The script prints
the backup path. Other Noctalia state is preserved.

To restore a backup, replace the example path below with the printed backup path:

```bash
state_root="${NOCTALIA_STATE_HOME:-${XDG_STATE_HOME:-$HOME/.local/state}}"
cp -- /path/to/settings.TIMESTAMP.UNIQUE.toml "$state_root/noctalia/settings.toml"
noctalia msg config-reload # Only needed if Noctalia is running.
```

Restoring brings back GUI overrides; the next theme switch backs them up and
clears them again.

## Font and Cursor

> [!TIP]
>
> Use `nwg-look` for easier GTK settings tweaking.

### Font

#### Installation

Place fonts in `~/.local/share/fonts` then run:

```bash
fc-cache -fv
```

> [!TIP]
>
> Dank Mono P is my patched version of Dank Mono, with added Vietnamese glyphs and Nerd Font icons, and fixes for ligature rendering issues.

#### Other fonts I use

- Inter: https://fonts.google.com/specimen/Inter
- Maple Mono: https://github.com/subframe7536/maple-font.
- More nerd fonts: https://github.com/ryanoasis/nerd-fonts.

### Cursor

#### Installation

Place cursor themes in `/usr/share/icons` then config your DE/WM.

#### Awesome cursor themes

- Bibata: https://github.com/ful1e5/Bibata_Cursor.
- Google Dot: https://github.com/ful1e5/Google_Cursor.
- More cursor themes: https://www.gnome-look.org/browse?cat=107&ord=latest.

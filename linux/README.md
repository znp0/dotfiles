# CachyOS setup

## Dual-booting with Windows

For more details, see `_docs/dual-boot/CachyOS_Windows.md`.

## Bootstrap

Run `bootstrap.sh` for app installation and config setup.

```bash
chmod +x linux/bootstrap.sh
linux/bootstrap.sh
```

To also install this laptop's CPU cap and automatic AC/battery GPU and display
settings, run:

```bash
linux/bootstrap.sh --laptop-power
```

The power settings can also be installed separately without running the full bootstrap:

```bash
sudo bash linux/_scripts/laptop-power/install.sh
```

## Laptop power

The service configuration lives in [`systemd/laptop-power.service`](./systemd/laptop-power.service).
Edit its `Environment=` settings to change the desktop user, CPU cap, AC adapter,
GPU address, display output, or battery display mode. The helper and installer
live together in [`_scripts/laptop-power/`](./_scripts/laptop-power/).

- CPU cap: `max_perf_pct=60` on AC and battery.
- Battery: set `eDP-1` to `2560x1600@60`, then remove GPU `0000:03:00.0`.
- AC: restore the GPU, set `power/control=auto`, then select the automatic display mode.

The helper checks AC every two seconds and applies changes at boot, when AC changes,
when a niri session starts, and after resume gaps longer than five seconds. Niri
commands run as `zen`; sysfs writes run as root. Failed commands are retried.

The installer copies the helper to `/usr/local/lib/laptop-power/` and the unit to
`/etc/systemd/system/`, then enables and restarts the service. Rerun the installer
after changing either file. These settings are specific to this laptop, so bootstrap
installs them only with `--laptop-power`.

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

Run `set-theme.sh` to recreate the symbolic links for theme configs.

```bash
chmod +x linux/set-theme.sh
linux/set-theme.sh boreal
```

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

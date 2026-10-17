# Reduce battery drain on the Lenovo Slim 7 16IAH7

Tested on my **Lenovo Slim 7 16IAH7** (Intel Iris Xe + Arc A370M, CachyOS + Niri). The steps may help on other laptops, but the results below are from this model only.

If your laptop drains quickly, try these changes one at a time. Keep the same brightness and apps open while comparing results.

## Check power use

Unplug the charger, then find your battery with `upower -e`. Use the path it shows with `upower -i`, and look for `energy-rate`. Watch for a few minutes; one reading can be misleading. Lower watts mean less battery drain under the same workload.

## Things to try

1. **Use Power Saver:** `powerprofilesctl set power-saver` if your system supports it. Switch back to your usual profile when plugged in.
2. **Dim the screen** to a comfortable level. Disconnect an external monitor or USB devices you do not need.
3. **Try 60 Hz** if your screen supports it. You can use your desktop's display settings or, in Niri:

   ```bash
   niri msg outputs                          # find your screen and available modes
   niri msg output eDP-1 mode '2560x1600@60' # use your screen's name and mode
   niri msg output eDP-1 mode auto           # restore the preferred mode
   ```

   My screen did not list 60 Hz, but `niri msg output eDP-1 custom-mode '2560x1600@60'` worked for me. Try a custom mode only if you can restore the screen if it goes black or flickers.

4. **Check the dedicated GPU.** On this Lenovo, the BIOS setting is **`Graphic Device`**. Choose **`UMA Graphics`** to disable the Arc, or **`Switchable Graphics`** to use it again; changing this setting requires a reboot. Other laptops may offer similar options under different names.

On my Lenovo, the Arc GPU reported that it was asleep, but the laptop still used about **27 W**. Temporarily removing it from Linux's device list brought the same test to about **18 W**.

### Temporarily remove and restore the Arc A370M card

Use this only with BIOS **`Switchable Graphics`** selected. Disconnect external displays and close apps using the Arc. On my tested boot, it was at `03:00.0`, and its DRM nodes were `/dev/dri/card0` and `/dev/dri/renderD129`. Check yours before running the removal command:

```bash
lspci -nnk -s 03:00.0                         # must show Arc A370M [8086:5693]
ls -l /sys/class/drm/{card*,renderD*}/device  # find nodes pointing to 03:00.0
fuser -v /dev/dri/card0 /dev/dri/renderD129   # should show no Arc users
echo 1 | sudo tee /sys/bus/pci/devices/0000:03:00.0/remove # remove Arc A370M
```

The DRM node numbers can change after reboot. Use `fuser` on the nodes that point to `03:00.0`; stop if an app is using them. To restore the Arc:

```bash
echo 1 | sudo tee /sys/bus/pci/rescan
echo auto | sudo tee /sys/bus/pci/devices/0000:03:00.0/power/control
lspci -nnk -s 03:00.0                         # confirm Arc and i915 returned
```

This does not change the BIOS setting. Apps that need the Arc may need a restart after rescan; if rescan fails, reboot.

Some MSI laptops can switch graphics modes from Linux using model-specific tools; [MControlCenter points to supergfxctl](https://github.com/dmitry-s93/MControlCenter) for models with a GPU switch. I have not found a way to change this Lenovo's `Graphic Device` BIOS setting at runtime.

Keep the changes that improve *your* battery life. You do not need to change your window manager or shell to try these steps.

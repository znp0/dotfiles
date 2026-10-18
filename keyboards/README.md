# Keyboards

## Owned Keyboards

1. [**FL-Esports CMK75**](https://flesportsglobal.com/products/flesports-cmk75-tri-mode-mechanical-keyboard?variant=46139163410646) — my first mechanical keyboard.
2. [**Wobkey Zen65**](https://www.wobkey.com/products/wobkey-zen-65-quick-release-tri-mode-mechanical-keyboard)

## QMK/VIA

> [!NOTE]
>
> Some Chinese vendors, including WOBKEY, have been listed by QMK for license violations related to incomplete source-code releases. The current list of offending vendors is available here: https://docs.qmk.fm/license_violations#offending-vendors.

### VIA Setup

To configure the keyboard using VIA:

1. Open https://usevia.app.
2. Navigate to **Settings**.
3. Enable **Show Design tab**.
4. Open the **Design** tab.
5. Click **Load** and select `definition.via.json`.
6. Switch to the **Configure** tab.
7. Open the **Save + Load** menu.
8. Click **Load** and select `layout.via.json`.

After loading both files, VIA will recognize the keyboard definition and restore the current layout configuration.

## Notes

- Most customization is performed through VIA.
- Advanced QMK features that require firmware compilation may not be available.
- Firmware source code for the Zen65 has not been publicly released at the time of writing.
- Future QMK compatibility depends on WOBKEY releasing the required source code and complying with QMK licensing requirements.

## Wobkey Zen65

> [!NOTE]
>
> Although marketed as a "QMK/VIA" keyboard, the Zen65 does not ship with the full QMK source code needed for complete QMK support. In practice, it mainly relies on VIA configuration files and does not offer the same level of customization as fully open-source QMK boards.

> [!NOTE]
>
> The official driver software is completely unusable. While it can save settings to the keyboard, the firmware entirely ignores those settings. Use VIA for keymaps instead.

### Sleeping time

- Sleeping time on different colors (press `Fn + Y` or `KbPrSlp` to cycle through):
  - Red: 1 min
  - Green: 3 mins
  - Blue: 10 mins
  - White: 30 mins

- There is also a custom keycode `KbSeSlp` for deep sleeping time, which likewise has 4 levels, though the exact value of each level is unknown.

- Default sleep timings:
  - Primary sleeping time: 180 s
  - Secondary sleeping time (deep sleep): 800 s

> [!TIP]
>
> Leaving the sleep timings at their defaults is recommended over tweaking them.

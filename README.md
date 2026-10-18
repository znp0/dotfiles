# Dotfiles

This repository contains my personal dotfiles and configurations. It is structured into different directories to keep OS-specific and shared configurations organized.

If you need help or want to chat, message me at my Discord [server](https://discord.gg/SZntdmMsUW).

## Structure

- [`linux/`](./linux/) — Linux-specific configurations and bootstrap scripts.
- [`windows/`](./windows/) — Windows-specific tools, environments, and customizations (e.g., PowerShell, Windows Terminal, Komorebi).
- [`shared/`](./shared/) — Cross-platform configurations including Neovim, Zed, kanata, etc.
- [`keyboards/`](./keyboards/) — Settings, notes, and layouts for the keyboards I own.

Within `linux/`, application configuration directories have plain names.
Supporting directories use a leading `_`: `_bin` for commands, `_scripts/setup` for
setup, `_packages` for package lists, `_themes` for theme bundles, `_fonts`
for fonts, and `_hosts` for device-specific settings. Commands are linked
individually into `~/.local/bin` so they can be used from any directory. See the [Linux setup instructions](./linux/README.md).

> [!NOTE]
>
> For installation, usage, and update instructions, please refer to the README or documentation inside each respective folder. If you want to customize or reuse parts of this repo, browse the folder(s) you're interested in and follow the instructions there.

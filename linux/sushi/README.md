# OnlyOffice previews in Sushi

The user plugin converts Office documents with the `x2t` converter bundled in `onlyoffice-bin`, then displays the PDF with Sushi's existing Papers viewer and page controls. It does not require LibreOffice or change your default Office app.

Requires Sushi 51.2's plugin API and the native OnlyOffice installation at `/opt/onlyoffice/desktopeditors`. Open OnlyOffice once to initialize its font cache before previewing documents.

`plugins-1` is the directory Sushi's loader uses for version 1 user plugins, under `${XDG_DATA_HOME:-~/.local/share}/sushi/`.

Install only this plugin:

```sh
bash linux/sushi/install.sh
```

The normal config deployment also installs the two plugin files:

```sh
linux/_scripts/setup/link-configs.sh
```

Sushi loads plugins when its service starts. Close any preview before updating. The service exits automatically after a short idle period; the next preview loads the plugin. To restart it immediately:

```sh
pkill -f '^/usr/bin/gjs -m /usr/lib/org.gnome.NautilusPreviewer$'
```

Select a DOC/DOCX, XLS/XLSX, PPT/PPTX, ODT/ODS/ODP or RTF file in Nautilus and press `Space`. Conversion runs locally, with a 30-second timeout. Closing the preview or selecting another file cancels a conversion in progress.

PDFs are stored in `${XDG_CACHE_HOME:-~/.cache}/sushi/onlyoffice/`. Changes to the source document, converter or font index invalidate the corresponding preview. The cache retains at most 64 PDFs; previews older than seven days are removed when another document is previewed. Temporary input copies are deleted after conversion, including failures and cancellation. Delete the cache directory to clear saved previews.

Password-protected files and files unsupported by OnlyOffice's converter show Sushi's error page. The plugin also relies on Sushi's internal PDF renderer; check it after major Sushi upgrades.


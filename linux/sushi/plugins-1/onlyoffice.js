import Adw from "gi://Adw";
import Gio from "gi://Gio";
import GLib from "gi://GLib";
import GObject from "gi://GObject";

import { Renderer } from "resource:///org/gnome/NautilusPreviewer/plugin-api-1.js";
import { Klass as PdfRenderer } from "resource:///org/gnome/NautilusPreviewer/js/viewers/pdf.js";

import { convertToPdf } from "./onlyoffice-convert.mjs";

export const contentTypes = [
  "application/msword",
  "application/vnd.ms-excel",
  "application/vnd.ms-powerpoint",
  "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
  "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
  "application/vnd.openxmlformats-officedocument.presentationml.presentation",
  "application/vnd.ms-word.document.macroEnabled.12",
  "application/vnd.ms-excel.sheet.macroEnabled.12",
  "application/vnd.ms-powerpoint.presentation.macroEnabled.12",
  "application/vnd.oasis.opendocument.text",
  "application/vnd.oasis.opendocument.spreadsheet",
  "application/vnd.oasis.opendocument.presentation",
  "application/rtf",
];

export const Klass = class OnlyOfficeRenderer extends Adw.Bin {
  static {
    GObject.registerClass({
      GTypeName: "DotfilesOnlyOfficeRenderer",
      Implements: [Renderer],
    }, this);
  }

  constructor(file) {
    super();

    this.markInitialized();

    this._load(file).catch((error) => {
      if (this.cancellable.is_cancelled()) {
        return;
      }

      const wrapped =
        error instanceof GLib.Error
          ? error
          : new GLib.Error(
              Gio.io_error_quark(),
              Gio.IOErrorEnum.FAILED,
              error.message,
            );

      this.markFailed(wrapped);
    });
  }

  async _load(file) {
    const pdf = await convertToPdf(file, this.cancellable);

    if (this.cancellable.is_cancelled()) {
      return;
    }

    const info = new Gio.FileInfo();
    info.set_content_type("application/pdf");

    this._viewer = new PdfRenderer(pdf, info);
    this._viewer.connect("ready", () => this.markReady());
    this._viewer.connect("failed", (_viewer, error) => this.markFailed(error));

    this.set_child(this._viewer);
  }

  stop() {
    this._viewer?.cancellable.cancel();
    this._viewer?.stop();
  }

  cleanup() {
    this._viewer?.cleanup();

    this.set_child(null);
    this._viewer = null;
  }

  get toolbar() {
    return this._viewer?.toolbar ?? null;
  }

  get topBarStyle() {
    return Adw.ToolbarStyle.RAISED_BORDER;
  }
};

import Gio from "gi://Gio";
import GLib from "gi://GLib";

const installation = "/opt/onlyoffice/desktopeditors";
const converter = `${installation}/converter/x2t`;

const cacheLifetime = 7 * 24 * 60 * 60;
const cacheLimit = 64;
const conversionTimeout = 30;

function ioError(code, message) {
  return new GLib.Error(Gio.io_error_quark(), code, message);
}

function checkCancelled(cancellable) {
  if (cancellable.is_cancelled()) {
    throw ioError(Gio.IOErrorEnum.CANCELLED, "Office preview cancelled");
  }
}

function queryInfo(file, cancellable) {
  return new Promise((resolve, reject) => {
    file.query_info_async(
      "standard::size,etag::value,time::modified,time::modified-usec",
      Gio.FileQueryInfoFlags.NONE,
      GLib.PRIORITY_DEFAULT,
      cancellable,
      (source, result) => {
        try {
          resolve(source.query_info_finish(result));
        } catch (error) {
          reject(error);
        }
      },
    );
  });
}

function copyFile(source, target, cancellable) {
  return new Promise((resolve, reject) => {
    source.copy_async(
      target,
      Gio.FileCopyFlags.NONE,
      GLib.PRIORITY_DEFAULT,
      cancellable,
      null,
      (file, result) => {
        try {
          resolve(file.copy_finish(result));
        } catch (error) {
          reject(error);
        }
      },
    );
  });
}

function isPdf(file) {
  try {
    const stream = file.read(null);

    try {
      const header = stream.read_bytes(5, null).get_data();

      return new TextDecoder().decode(header) === "%PDF-";
    } finally {
      stream.close(null);
    }
  } catch {
    return false;
  }
}

function removeTree(file) {
  // Only used on our own private conversion directory, without following symlinks.
  try {
    if (
      file.query_file_type(Gio.FileQueryInfoFlags.NOFOLLOW_SYMLINKS, null) ===
      Gio.FileType.DIRECTORY
    ) {
      const entries = file.enumerate_children(
        "standard::name",
        Gio.FileQueryInfoFlags.NOFOLLOW_SYMLINKS,
        null,
      );

      try {
        let info;

        while ((info = entries.next_file(null))) {
          removeTree(file.get_child(info.get_name()));
        }
      } finally {
        entries.close(null);
      }
    }

    file.delete(null);
  } catch (error) {
    if (!error.matches(Gio.io_error_quark(), Gio.IOErrorEnum.NOT_FOUND)) {
      console.warn(
        `Cannot clean Office preview temporary file: ${error.message}`,
      );
    }
  }
}

function pruneCache(directory, keep) {
  const entries = directory.enumerate_children(
    "standard::name,time::modified",
    Gio.FileQueryInfoFlags.NONE,
    null,
  );
  const files = [];

  try {
    let info;

    while ((info = entries.next_file(null))) {
      if (/^[a-f0-9]{64}\.pdf$/.test(info.get_name())) {
        files.push([
          info.get_name(),
          info.get_attribute_uint64("time::modified"),
        ]);
      }
    }
  } finally {
    entries.close(null);
  }

  const otherFiles = files
    .filter(([name]) => name !== keep)
    .sort((a, b) => b[1] - a[1]);
  const cutoff = GLib.get_real_time() / 1000000 - cacheLifetime;

  for (let i = 0; i < otherFiles.length; i++) {
    const [name, modified] = otherFiles[i];

    if (i >= cacheLimit - 1 || modified < cutoff) {
      try {
        directory.get_child(name).delete(null);
      } catch {
        // Another preview may have removed it already.
      }
    }
  }
}

function runConverter(params, directory, cancellable) {
  checkCancelled(cancellable);

  const launcher = new Gio.SubprocessLauncher({
    flags: Gio.SubprocessFlags.STDOUT_SILENCE | Gio.SubprocessFlags.STDERR_PIPE,
  });
  launcher.set_cwd(directory);

  const process = launcher.spawnv([converter, params]);

  let timedOut = false;
  const cancelId = cancellable.connect(() => process.force_exit());
  const timeoutId = GLib.timeout_add_seconds(
    GLib.PRIORITY_DEFAULT,
    conversionTimeout,
    () => {
      timedOut = true;
      process.force_exit();

      return GLib.SOURCE_REMOVE;
    },
  );

  return new Promise((resolve, reject) => {
    // Wait without the cancellable so a killed child is reaped before cleanup.
    process.communicate_utf8_async(null, null, (child, result) => {
      if (!timedOut) {
        GLib.source_remove(timeoutId);
      }

      if (cancelId) {
        cancellable.disconnect(cancelId);
      }

      try {
        const [, , stderr] = child.communicate_utf8_finish(result);
        checkCancelled(cancellable);

        if (timedOut) {
          throw ioError(
            Gio.IOErrorEnum.TIMED_OUT,
            "Office preview conversion exceeded 30 seconds",
          );
        }

        if (!child.get_successful()) {
          throw ioError(
            Gio.IOErrorEnum.FAILED,
            `OnlyOffice conversion failed: ${stderr.trim().slice(-1000) || "unsupported, encrypted or damaged document"}`,
          );
        }

        resolve();
      } catch (error) {
        reject(error);
      }
    });
  });
}

/** Convert an Office document to a private, cached PDF. */
export async function convertToPdf(file, cancellable) {
  checkCancelled(cancellable);

  if (!GLib.file_test(converter, GLib.FileTest.IS_EXECUTABLE)) {
    throw ioError(
      Gio.IOErrorEnum.NOT_FOUND,
      "Install OnlyOffice Desktop Editors to preview Office documents",
    );
  }

  const fonts = GLib.build_filenamev([
    GLib.get_user_data_dir(),
    "onlyoffice",
    "desktopeditors",
    "data",
    "fonts",
  ]);
  const allFonts = Gio.File.new_for_path(`${fonts}/AllFonts.js`);

  if (
    !allFonts.query_exists(cancellable) ||
    !GLib.file_test(`${fonts}/font_selection.bin`, GLib.FileTest.IS_REGULAR)
  ) {
    throw ioError(
      Gio.IOErrorEnum.NOT_FOUND,
      "Open OnlyOffice once to initialize its fonts, then retry the preview",
    );
  }

  const [info, converterInfo, fontInfo] = await Promise.all([
    queryInfo(file, cancellable),
    queryInfo(Gio.File.new_for_path(converter), cancellable),
    queryInfo(allFonts, cancellable),
  ]);

  const signature = (metadata) => [
    metadata.get_size(),
    metadata.get_etag(),
    metadata.get_attribute_uint64("time::modified"),
    metadata.get_attribute_uint32("time::modified-usec"),
  ];

  const key = GLib.compute_checksum_for_string(
    GLib.ChecksumType.SHA256,
    JSON.stringify([
      1,
      file.get_uri(),
      signature(info),
      signature(converterInfo),
      signature(fontInfo),
    ]),
    -1,
  );

  const cachePath = GLib.build_filenamev([
    GLib.get_user_cache_dir(),
    "sushi",
    "onlyoffice",
  ]);

  if (GLib.mkdir_with_parents(cachePath, 0o700) !== 0) {
    throw ioError(Gio.IOErrorEnum.FAILED, "Cannot create Office preview cache");
  }

  const cache = Gio.File.new_for_path(cachePath);
  const pdf = cache.get_child(`${key}.pdf`);
  pruneCache(cache, pdf.get_basename());
  checkCancelled(cancellable);

  if (isPdf(pdf)) {
    return pdf;
  }

  const work = Gio.File.new_for_path(
    GLib.dir_make_tmp("sushi-onlyoffice-XXXXXX"),
  );

  try {
    const extension = file.get_basename()?.match(/\.[a-z0-9]+$/i)?.[0] ?? "";
    const input = work.get_child(`input${extension}`);
    const output = work.get_child("preview.pdf");

    await copyFile(file, input, cancellable);

    const fields = {
      m_sFileFrom: input.get_path(),
      m_sFileTo: output.get_path(),
      m_nFormatTo: "513",
      m_sFontDir: fonts,
      m_sAllFontsPath: allFonts.get_path(),
      m_sThemeDir: `${installation}/editors/sdkjs/slide/themes`,
      m_sTempDir: work.get_path(),
      m_bIsNoBase64: "true",
    };

    const xml =
      "<TaskQueueDataConvert>" +
      Object.entries(fields)
        .map(
          ([name, value]) =>
            `<${name}>${GLib.markup_escape_text(value, -1)}</${name}>`,
        )
        .join("") +
      "</TaskQueueDataConvert>";
    const params = work.get_child("params.xml").get_path();
    GLib.file_set_contents(params, xml);

    await runConverter(params, work.get_path(), cancellable);

    if (!isPdf(output)) {
      throw ioError(
        Gio.IOErrorEnum.FAILED,
        "OnlyOffice did not produce a valid PDF",
      );
    }

    checkCancelled(cancellable);
    output.move(pdf, Gio.FileCopyFlags.OVERWRITE, cancellable, null);
    pruneCache(cache, pdf.get_basename());

    return pdf;
  } finally {
    removeTree(work);
  }
}

# 0006. Run the AppImage in an FHS env with the host libs it expects

- Status: Accepted
- Date: 2026-11-12

## Context

The AppImage only bundles part of its runtime (the slicer binary, the Agora RTM SDK,
zlib, lzma, expat, libmspack). The rest is expected from the host: GTK3, WebKitGTK
4.1, libsoup 3, GStreamer, GL/EGL/GLU, libsecret, D-Bus, Wayland/X11. Its launcher
(`libexec/elegoo-slicer-env`) checks for `libOpenGL.so.0` and
`libwebkit2gtk-4.1.so.0` in `/usr/lib` (or `ldconfig -p`) and exits otherwise.

## Decision

Use `appimageTools.wrapType2`, which runs the AppImage inside a bwrap-based FHS
environment, and add to its default library set (`extraPkgs`) what it lacks:

- `webkitgtk_4_1`, `libsoup_3`, `glib-networking` (TLS for libsoup / GIO);
- `gst_all_1.gst-plugins-good` and `-bad` (camera / video streams);
- `libmspack`.

GTK theme assets are SVG and the FHS env sets no gdk-pixbuf loader cache, so the
profile exports `GDK_PIXBUF_MODULE_FILE` to librsvg's cache (it lists every loader,
SVG included).

The desktop entry is installed with `Exec=elegoo-slicer` and `Icon=elegoo-slicer`
instead of upstream's `AppRun` / `ElegooSlicer`.

## Consequences

- Upstream's launcher and runtime checks run unmodified; we do not patch the binary.
- The smoke test (`elegoo-slicer --help` inside the FHS env, no display) fails as soon
  as a `NEEDED` library is missing, which is the main risk on upstream bumps.
- bwrap needs unprivileged user namespaces. Ubuntu 24.04 runners restrict them via
  AppArmor (`bwrap: setting up uid map: Permission denied`), so CI sets
  `kernel.apparmor_restrict_unprivileged_userns=0` before `nix flake check`.
- The closure is large (WebKitGTK, GStreamer), as with any WebKit-based app.

## Alternatives considered

- **Extract and `autoPatchelf` the binary** (as artcraft-nixos does for its tarballs):
  would drop bwrap, but the launcher's `/usr/lib` checks, GIO modules, GStreamer
  plugin paths and WebKit helpers would all need patching or re-implementing.
  Rejected.

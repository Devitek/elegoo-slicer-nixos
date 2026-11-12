# ElegooSlicer, packaged from the upstream Linux AppImage.
#
# The AppImage bundles the slicer binary but expects WebKitGTK 4.1, GStreamer, GL and
# friends from the host: its launcher (`libexec/elegoo-slicer-env`) refuses to start
# when `libOpenGL.so.0` or `libwebkit2gtk-4.1.so.0` are missing. appimageTools runs it
# inside an FHS environment; `runtimePkgs` adds what the default FHS set lacks.
# See docs/adr/0006-fhs-runtime.md.
{
  lib,
  appimageTools,
  librsvg,
  python3,
  runCommand,
  source,
}:

let
  pname = "elegoo-slicer";
  inherit (source) version src;

  extracted = appimageTools.extract { inherit pname version src; };

  # The binary exports its statically linked FreeType, which hijacks the system
  # fontconfig and segfaults on variable fonts. Hide those exports (docs/adr/0009).
  patched = runCommand "${pname}-${version}-patched" { nativeBuildInputs = [ python3 ]; } ''
    cp -a ${extracted} "$out"
    chmod -R u+w "$out"
    python3 ${./unexport-freetype.py} "$out/bin/elegoo-slicer"
  '';

  # On top of appimageTools' default FHS set (GTK3, GStreamer base, libglvnd, GLU,
  # libsecret, Wayland/X11, Mesa...).
  runtimePkgs =
    pkgs: with pkgs; [
      webkitgtk_4_1 # embedded web views (device pages, login, guides)
      libsoup_3
      glib-networking # TLS for libsoup / GIO
      gst_all_1.gst-plugins-good # camera / video streams
      gst_all_1.gst-plugins-bad
      libmspack
    ];
in
appimageTools.wrapAppImage {
  inherit pname version;
  src = patched;

  extraPkgs = runtimePkgs;

  # GTK theme assets are SVG: point gdk-pixbuf at a loader cache that includes the
  # librsvg loader (the FHS env does not set one).
  profile = ''
    export GDK_PIXBUF_MODULE_FILE=${librsvg}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache
  '';

  extraInstallCommands = ''
    install -Dm444 ${extracted}/usr/share/applications/com.orcaslicer.ElegooSlicer.desktop \
      "$out/share/applications/elegoo-slicer.desktop"
    substituteInPlace "$out/share/applications/elegoo-slicer.desktop" \
      --replace-fail 'Exec=AppRun' 'Exec=elegoo-slicer' \
      --replace-fail 'Icon=ElegooSlicer' 'Icon=elegoo-slicer'
    for icon in ${extracted}/usr/share/icons/hicolor/*/apps/*.png; do
      size="$(basename "$(dirname "$(dirname "$icon")")")"
      install -Dm444 "$icon" "$out/share/icons/hicolor/$size/apps/elegoo-slicer.png"
    done
  '';

  passthru = {
    inherit extracted patched runtimePkgs;
  };

  meta = {
    description = "Open-source FDM slicer by Elegoo (OrcaSlicer fork)";
    homepage = "https://github.com/elegooofficial/ElegooSlicer";
    changelog = "https://github.com/elegooofficial/ElegooSlicer/releases/tag/v${version}";
    license = lib.licenses.agpl3Only;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "elegoo-slicer";
  };
}

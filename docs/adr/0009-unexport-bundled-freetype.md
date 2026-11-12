# 0009. Hide the bundled FreeType exported by the binary

- Status: Accepted
- Date: 2026-11-13

## Context

`nix run` of 0.1.x exited silently with a segfault (code 139) right after start-up.
The core dump shows `tt_apply_mvar` (in the ElegooSlicer binary) called from the
system `FT_Set_Named_Instance`, called from fontconfig while it scans a variable font.

The binary links FreeType statically and **exports** 71 of its `FT_*` functions. The
executable comes first in the dynamic symbol lookup scope, so the system fontconfig
uses Elegoo's `FT_New_Face` but the system `FT_Set_Named_Instance` (not part of
Elegoo's copy). A face built by one FreeType is handed to another one with a different
internal layout, and it crashes. It only happens when fontconfig has to scan a
variable font that is not in its cache, which is why it looked environment-dependent
(fontconfig 2.18 rescans more often than 2.17).

The headless smoke test (`--help`) never initialises fonts, so CI stayed green.

## Decision

Patch the extracted AppImage before wrapping it: `pkgs/unexport-freetype.py` renames
the exported `FT_*` names in `.dynstr` to `XT_*` (same length). The binary has no
relocation against these symbols (it calls its copy directly), so the exports only
served interposition: after renaming, lookups for `FT_*` skip the executable and resolve
to the system libfreetype, consistently. The script refuses to patch when the binary
imports an `FT_*` symbol, when a name string is shared, or when there is nothing to
rename, so an upstream change fails the build instead of shipping a half-patched binary.

Add a GUI check (`checks.<sys>.elegoo-slicer-gui`): the app runs for 30 s under Xvfb
with a variable font (Inter) to scan, and must still be alive. Without the patch it
fails with exit code 139.

## Consequences

- Works on current nixpkgs (fontconfig 2.18) without pinning an older channel.
- The app keeps using its own FreeType internally; only fontconfig / Pango / cairo go
  through the system one.
- We now modify the upstream binary (symbol names only). Documented here and guarded
  by the script's refusals and the GUI check.

## Alternatives considered

- **Pin nixpkgs to nixos-26.05 (fontconfig 2.17)**: hides the symptom on machines with
  a warm font cache, but the same crash reproduces with 2.17 when a variable font has
  to be scanned. Rejected.
- **Ship a FreeType matching the bundled version**: the bundled version is unknown and
  would drift with every upstream release. Rejected.
- **LD_PRELOAD the system FreeType**: the executable still wins over preloaded
  libraries in the lookup order. Does not work.

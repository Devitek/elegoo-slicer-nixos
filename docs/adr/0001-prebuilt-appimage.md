# 0001. Package the upstream AppImage, not from source

- Status: Accepted
- Date: 2026-11-12

## Context

ElegooSlicer is an OrcaSlicer fork: a large C++ application (wxWidgets/GTK3,
OpenGL, WebKitGTK, OpenCV, CGAL, OCCT...). For Linux, upstream only publishes a
ready-to-run **AppImage**, one per release. Releases come every few weeks.

## Decision

Package the **official AppImage** with `appimageTools.wrapType2`. We do **not**
build from source.

## Consequences

- The package is exactly what upstream ships and tests, including their bundled
  network stack (ElegooLink, cloud services).
- Updates are cheap: fetch one file and record its hash. A bump builds in seconds.
- `meta.sourceProvenance = [ binaryNativeCode ]` documents the binary nature.
- We depend on upstream keeping a stable asset name (see ADR-0003) and on the
  AppImage's host expectations (see ADR-0006).

## Alternatives considered

- **Build from source** (like `orca-slicer` in nixpkgs): would allow `aarch64-linux`,
  but means a heavy C++ build (tens of minutes), a long list of pinned dependencies to
  maintain, and patches that can break on every upstream release. Disproportionate
  for a packaging repository. Rejected.

# AGENTS.md — vx11

## Project
Unix libX11 bindings for V. There is a generated raw API and a handwritten native
convenience layer. Module `vx11`, MIT, no V package dependencies. Installed X11
headers are the source of truth; `legacy/` is historical reference only.

## Commands
Compiler: `/home/diviocity/.local/bin/v` (V 0.5.2; compiler checkout is
`/home/diviocity/git/v/v`).

- Regenerate: `v run tools/generate.v` (requires Clang; `CLANG` overrides it).
- Format generated output: `v fmt -w types.c.v functions.c.v constants.v methods.v`.
- Check library: `v -check -shared .` (this is not a main module).
- Compile every binding: `v -shared -o /tmp/libvx11.so .`.
- Unit tests: `v test bindings_test.v`.
- Integration: `v -path '..|@vlib|@vmodules' -o /tmp/vx11-integration tests/integration.v`,
  then `xvfb-run -a /tmp/vx11-integration`.
- Examples use the same `-path` argument when built from this checkout.
- Optional extensions: build `tests/extensions.v` with the same `-path`, then run
  on Xvfb with `-screen 0 640x480x24 -screen 1 800x600x24 +xinerama`.
  Also run with `-xinerama -extension RANDR -extension MIT-SCREEN-SAVER` and the test's
  `--unavailable` argument. See README for full commands.

## Structure
- `tools/generate.v`: V-only Clang AST generator. No Python.
- `types.c.v`, `functions.c.v`, `constants.v`, `methods.v`, `vx11_bridge.h`,
  `api.json`: generated; change the generator, then regenerate.
- `vx11.v`: C includes and linker configuration; `abi.v`: native C long aliases.
- `image.c.v`: XImage operation macros and XUniqueContext.
- `connection.v`, `window.v`, `graphics.v`, `events.v`, `property.v`: native helpers.
- `examples/`: runnable window and bound-method event-handler examples.
- `bindings_test.v`, `tests/integration.v`: offline and Xvfb coverage.
- `xinerama/`, `shape/`, `screensaver/`: handwritten optional submodules, each
  with complete public raw header coverage plus native borrowed-connection
  helpers. Extension linkage belongs only in that submodule, never in the core.
- `tests/abi.h`: actual C long pointer/size probes; `tests/extensions.v`: extension
  behavior, availability, ownership, and lifetime tests.

## ABI and ownership rules
C int is `i32`; C long/unsigned long are `CLong`/`CULong`. XIDs are native C
unsigned longs, not always u32. Property format 32 uses C long slots in Xlib.
CLong/CULong use explicit i64/u64 or i32/u32 according to Unix target bitness.
Do not alias them to V int/uint: C interop can adapt int pointers to 32-bit C int.
Use C-backed typedef structs/unions; do not recreate layouts as ordinary V structs.
Preserve case-distinct keysyms. Callbacks must use exact C-width argument types.

Native handles share ownership state by reference and must be released in order:
GC, window, display. Close/destroy is idempotent. Returned V strings/arrays copy
and free the C allocation. Raw calls retain Xlib ownership and asynchronous error
semantics. New helpers should validate local inputs and document lifetime rules.

Do not edit `.crush/` session data. Do not delegate to other agents by default.

## Optional text libraries
- `fontconfig/` and `xft/`: C-backed types and native ownership helpers. Keep
  `#pkgconfig fontconfig`/`#pkgconfig xft` confined to these optional imports.
- `tools/generate_text.v`: V/Clang generator for 50 selected Fontconfig functions
  and all non-variadic Xft functions. Generated `raw.c.v`, `bridge.h`, and
  `api.json` files belong to this generator; types/helpers remain handwritten.
- Fontconfig enum output pointers cross typed C adapters; do not substitute an
  int pointer directly for FcResult* in a C prototype.
- Unit tests: `v -path '..|@vlib|@vmodules' test fontconfig`.
- Integration: build `tests/text.v` with that path, then run it under Xvfb.
- `examples/xft_text.v`: antialiased rendering and positioned glyph showcase.
- Close Xft draw contexts and fonts before the drawable and display. Native
  open_pattern copies requests; raw XftFontOpenPattern consumes on success.
  Fontconfig global FcFini must not run while any Xft user remains active.

# vx11

UNIX X11 bindings for V, with generated raw APIs and native helpers for windows,
events, drawing, properties, and resource ownership. No V package dependencies.

## Coverage

The core maps public function declarations from `Xlib.h`, `Xutil.h`,
`Xresource.h`, and `XKBlib.h`, including XKB, resource databases, input methods,
font sets, images, and keysyms. It also wraps XImage operation macros.
Bindings are generated from installed headers; `api.json` maps C names to V names.

Native helpers provide connections, windows, graphics contexts, checked event
accessors, copied properties, and event loops accepting functions, closures, or
bound methods. Generated connection methods also expose advanced Xlib calls.

Optional imports add their own library dependencies:

| Import | Coverage |
| --- | --- |
| `vx11.xinerama` | Complete public Xinerama API; monitor snapshots and activity checks |
| `vx11.shape` | Complete public SHAPE API; window regions and shape events |
| `vx11.screensaver` | Complete public MIT-SCREEN-SAVER API; idle time, state, and notifications |
| `vx11.composite` | Public XComposite calls and cached window previews ([details](composite/README.md)) |
| `vx11.render` | Selected XRender picture, compositing, transform, filter, and clipping APIs ([details](render/README.md)) |
| `vx11.xft` | All non-variadic Xft calls; native UTF-8 text, positioned glyphs, and font helpers |
| `vx11.fontconfig` | Selected font matching, pattern, charset, and font-list APIs |

XRandR, XInput2, full XRender, and full Fontconfig coverage are not provided.
Text shaping, bidi ordering, and automatic fallback layout remain application
responsibilities.

## Getting started

Install V, a C compiler, libX11, and its development headers. Optional modules
need their corresponding development libraries; Xft/Fontconfig also use
`pkg-config` and FreeType headers. Core `vx11` links only libX11.

Try some examples:

```sh
v -path '..|@vlib|@vmodules' run examples/hello.v
v -path '..|@vlib|@vmodules' run examples/events.v
v -path '..|@vlib|@vmodules' run examples/xft_text.v
```

See the [example gallery](examples/README.md) for runnable demos and screenshots.

Native handles share ownership state and close idempotently. Release graphics
contexts, Xft draw contexts, and fonts before windows, then close the connection.
Native returned strings and arrays are copied V values. Raw calls retain Xlib's
ownership rules and asynchronous errors; native helpers validate local inputs
but do not catch every server error. C-backed types preserve the UNIX ABI,
including C `long` widths for XIDs and property storage.

## Development

Clang is required only for regeneration; generated files are committed.

```sh
v run tools/generate.v
v fmt -w types.c.v functions.c.v constants.v methods.v
v -check -shared .
v test bindings_test.v
v -path '..|@vlib|@vmodules' -o /tmp/vx11-integration tests/integration.v
xvfb-run -a /tmp/vx11-integration
```

`tools/generate_text.v` regenerates the Xft and Fontconfig raw APIs. Additional
integration coverage lives in `tests/` and `composite/tests/`. See
[AGENTS.md](AGENTS.md) for extension and text test commands. Tested on Linux x86-64.

MIT licensed; bundled X11-derived material retains its accompanying notices.

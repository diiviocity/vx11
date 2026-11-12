# XRender

Optional `vx11.render` import, linked with libXrender. Includes availability and
version queries, borrowed format lookup, owned picture creation/freeing,
compositing, transforms, filters and clip rectangles. This is a selected picture
API, not full coverage of glyph sets and gradients in Xrender.h. Raw arguments
and errors follow Xlib; use `fixed(value)` for 16.16 transform coefficients.

`dimmed_snapshot(connection, x, y, width, height)` copies a visible root region
and applies a dark tint for an overlay backdrop. Capture before mapping the
overlay. The returned pixmap uses the default screen visual/depth and belongs
to the caller: free with `vx11.free_pixmap` before closing the connection.
A compositor process is not required. Core vx11 does not link to XRender unless
this submodule or another optional consumer is imported.

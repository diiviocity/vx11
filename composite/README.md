# XComposite

Optional `vx11.composite` import, linked with libXcomposite and libXrender.
Provides the raw Xcomposite.h entry points and a cached `Preview` helper.
Previews require server-side XComposite 0.2 and XRender; no compositor process
is necessary. Core vx11 applications do not acquire these dependencies.

```v
import vx11
import vx11.composite

mut c := vx11.connect('')!
defer { c.close() }
mut preview := composite.new_preview(c, window_id)!
defer { preview.close() }
if preview.update(320, 200)! {
    preview.draw(destination, 10, 10, 320, 200)!
}
```

`Preview` borrows the connection, owns an automatic redirect request and its
cached server pixmap, and closes idempotently. Close before closing the display.
The source window is never moved, mapped or resized. `update` scales the entire
source; callers calculate the desired aspect ratio. `draw` uses the default
screen's visual and depth for its destination. A hidden or destroyed source
retains its last good image; a source never captured returns false. Raw naming
returns an owned pixmap that callers release with `vx11.free_pixmap`.

Capture and close use temporary, synchronous Xlib error traps to tolerate
windows disappearing. Use from a single Xlib thread; do not issue concurrent
requests on other displays while these helpers run. Raw calls retain normal
asynchronous Xlib error semantics. Other extension APIs remain in their own
optional submodules.

Regression fixture (from the vx11 checkout):

```sh
v -path '..|@vlib|@vmodules' -o /tmp/vx11-composite composite/tests/integration.v
xvfb-run -a -s '-screen 0 640x480x24' /tmp/vx11-composite
xvfb-run -a -s '-screen 0 640x480x24 -extension Composite' /tmp/vx11-composite --unavailable
```

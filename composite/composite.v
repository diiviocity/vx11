// Optional XComposite window previews. Requires XComposite 0.2 and XRender.
module composite

import vx11
import vx11.render

#include "@VMODROOT/composite/bridge.h"

@[typedef]
struct C.Vx11CompositePreview {}

fn C.vx11_comp_extensions(&vx11.Display) int
fn C.vx11_comp_preview_new(&vx11.Display, vx11.Window) &C.Vx11CompositePreview
fn C.vx11_comp_preview_free(&vx11.Display, &C.Vx11CompositePreview)
fn C.vx11_comp_preview_update(&vx11.Display, &C.Vx11CompositePreview, int, int) int
fn C.vx11_comp_preview_draw(&vx11.Display, &C.Vx11CompositePreview, vx11.Drawable, int, int, int, int) int

// Preview owns its redirect request and cached server-side thumbnail, borrowing
// connection. Close before the connection. All methods run on one Xlib thread;
// capture uses a scoped synchronous X error trap for disappearing windows.
@[heap; noinit]
pub struct Preview {
	connection &vx11.Connection
mut:
	handle &C.Vx11CompositePreview = unsafe { nil }
}

pub fn available(c &vx11.Connection) !bool {
	// Keep XRender linkage confined to the optional extension modules.
	if !render.available(c)! { return false }
	return C.vx11_comp_extensions(c.raw()!) != 0
}

pub fn new_preview(c &vx11.Connection, window vx11.Window) !&Preview {
	if !available(c)! { return error('window previews require XComposite 0.2 and XRender') }
	if window == 0 { return error('invalid preview window') }
	handle := C.vx11_comp_preview_new(c.raw()!, window)
	if handle == unsafe { nil } { return error('cannot allocate preview') }
	return &Preview{ connection: c, handle: handle }
}

// update retains the last good image when a window is unmapped or gone.
// False means no image has ever been captured, so draw a placeholder.
pub fn (p &Preview) update(width int, height int) !bool {
	if p.handle == unsafe { nil } { return error('preview is closed') }
	if width < 1 || height < 1 || width > 65535 || height > 65535 {
		return error('invalid preview dimensions')
	}
	return C.vx11_comp_preview_update(p.connection.raw()!, p.handle, width, height) != 0
}

// draw scales the cached image into a drawable of the default screen visual/depth.
// This does not refresh the source. Returns false when no cached image exists.
pub fn (p &Preview) draw(target vx11.Drawable, x int, y int, width int, height int) !bool {
	if p.handle == unsafe { nil } { return error('preview is closed') }
	if width < 1 || height < 1 || width > 65535 || height > 65535 {
		return error('invalid preview dimensions')
	}
	return C.vx11_comp_preview_draw(p.connection.raw()!, p.handle, target, x, y, width, height) != 0
}

pub fn (mut p Preview) close() {
	if p.handle != unsafe { nil } {
		if d := p.connection.raw() { C.vx11_comp_preview_free(d, p.handle) }
		p.handle = unsafe { nil }
	}
}

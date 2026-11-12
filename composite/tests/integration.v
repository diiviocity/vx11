module main

import os
import vx11
import vx11.composite
import vx11.render

fn pixel(c &vx11.Connection, drawable vx11.Drawable) !u64 {
	image := vx11.get_image(c.raw()!, drawable, 40, 30, 1, 1, vx11.CULong(0xffffffff), vx11.z_pixmap)
	assert image != unsafe { nil }
	defer { vx11.destroy_image(image) }
	return u64(vx11.get_pixel(image, 0, 0))
}

fn main() {
	mut c := vx11.connect('')!
	defer { c.close() }
	if '--unavailable' in os.args {
		assert !composite.available(c)!
		if _ := composite.new_preview(c, c.root()!) {
			assert false
		}
		println('Composite unavailable: OK')
		return
	}
	assert composite.available(c)! && render.available(c)!
	mut source := c.new_window(width: 320, height: 240, background: c.color('#bc4010')!)!
	defer { source.destroy() }
	source.show()!
	// Coexist with a manual redirect, as used by an external compositor.
	composite.redirect_window(c.raw()!, source.id, composite.redirect_manual)
	c.sync()!
	mut preview := composite.new_preview(c, source.id)!
	defer { preview.close() }
	target := vx11.create_pixmap(c.raw()!, vx11.Drawable(c.root()!), 80, 60, u32(vx11.default_depth(c.raw()!, c.screen_number()!)))
	defer { vx11.free_pixmap(c.raw() or { unsafe { nil } }, target) }
	assert preview.update(80, 60)!
	assert preview.draw(vx11.Drawable(target), 0, 0, 80, 60)!
	c.sync()!
	assert pixel(c, vx11.Drawable(target))! == u64(c.color('#bc4010')!)
	source.resize(400, 300)!
	vx11.set_window_background(c.raw()!, source.id, c.color('#2090cc')!)
	source.clear()!
	c.sync()!
	assert preview.update(80, 60)!
	assert preview.draw(vx11.Drawable(target), 0, 0, 80, 60)!
	c.sync()!
	assert pixel(c, vx11.Drawable(target))! == u64(c.color('#2090cc')!)
	source.destroy()
	c.sync()!
	assert preview.update(80, 60)!
	assert preview.draw(vx11.Drawable(target), 0, 0, 80, 60)!
	c.sync()!
	assert pixel(c, vx11.Drawable(target))! == u64(c.color('#2090cc')!)
	preview.close()
	preview.close()
	if _ := preview.update(80, 60) {
		assert false
	}
	if _ := render.dimmed_snapshot(c, -1, 0, 100, 100) {
		assert false
	}
	backdrop := render.dimmed_snapshot(c, 0, 0, 100, 100)!
	vx11.free_pixmap(c.raw()!, backdrop)
	println('Composite/Render OK: existing compositor, scaled pixels, resize, destroyed source cache, idempotent close, snapshot bounds')
}

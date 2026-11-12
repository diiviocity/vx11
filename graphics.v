module vx11

// Graphics owns a GC and borrows its window. Free it before destroying the window.
@[heap; noinit]
pub struct Graphics {
mut:
	window &WindowHandle = unsafe { nil }
	handle GC
	closed bool
}

pub fn (w &WindowHandle) graphics() !&Graphics {
	gc := create_gc(w.display()!, Drawable(w.id), 0, unsafe { nil })
	if gc == unsafe { nil } { return error('cannot create graphics context') }
	return &Graphics{ window: w, handle: gc }
}

fn (g &Graphics) display() !&Display {
	if g.closed { return error('graphics context is closed') }
	return g.window.display()
}

pub fn (mut g Graphics) close() {
	if !g.closed {
		if g.window.connection.display != unsafe { nil } {
			free_gc(g.window.connection.display, g.handle)
		}
		g.closed = true
	}
}

pub fn (g &Graphics) foreground(pixel CULong) ! { set_foreground(g.display()!, g.handle, pixel) }

pub fn (g &Graphics) background(pixel CULong) ! { set_background(g.display()!, g.handle, pixel) }

pub fn (g &Graphics) line(x1 int, y1 int, x2 int, y2 int) ! {
	draw_line(g.display()!, Drawable(g.window.id), g.handle, i32(x1), i32(y1), i32(x2), i32(y2))
}

pub fn (g &Graphics) rectangle(x int, y int, width int, height int, filled bool) ! {
	if width < 0 || height < 0 || width > 65535 || height > 65535 {
		return error('invalid rectangle dimensions')
	}
	d := g.display()!
	if filled {
		fill_rectangle(d, Drawable(g.window.id), g.handle, i32(x), i32(y), u32(width), u32(height))
	} else {
		draw_rectangle(d, Drawable(g.window.id), g.handle, i32(x), i32(y), u32(width), u32(height))
	}
}

// text draws bytes using the GC's core font. For Unicode use XFontSet/Xutf8DrawString.
pub fn (g &Graphics) text(x int, y int, text string) ! {
	if text.len > 0x7fffffff { return error('text is too long') }
	draw_string(g.display()!, Drawable(g.window.id), g.handle, i32(x), i32(y), &char(text.str), i32(text.len))
}

pub fn (g &Graphics) points(points []XPoint) ! {
	if points.len > 0x7fffffff { return error('too many points') }
	draw_points(g.display()!, Drawable(g.window.id), g.handle, points.data, i32(points.len), coord_mode_origin)
}

// color allocates a named color in the default colormap. Release allocated colors
// with free_colors when using a mutable/limited colormap.
pub fn (c &Connection) color(name string) !CULong {
	if name.contains('\x00') { return error('color name contains NUL') }
	d := c.raw()!
	mut screen := XColor{}
	mut exact := XColor{}
	if alloc_named_color(d, default_colormap(d, default_screen(d)), &char(name.str), &screen, &exact) == 0 {
		return error('cannot allocate color "${name}"')
	}
	return screen.pixel
}

// Small drawing helpers for the examples: an off-screen pixmap prevents flicker.
module demo

import vx11
import os

@[heap]
pub struct Canvas {
	connection &vx11.Connection
	window     &vx11.WindowHandle
	gc         vx11.GC
	small      &vx11.XFontStruct
mut:
	pixmap    vx11.Pixmap
	colors    map[string]vx11.CULong
	lettering map[string][]vx11.XRectangle
pub mut:
	width  int
	height int
}

pub fn new_canvas(connection &vx11.Connection, window &vx11.WindowHandle, width int, height int) !&Canvas {
	d := connection.raw()!
	small := vx11.load_query_font(d, c'6x13')
	// Every X server supplies the alias "fixed"; optional fonts fall back to it.
	s := if small == unsafe { nil } { vx11.load_query_font(d, c'fixed') } else { small }
	if s == unsafe { nil } { return error('X server has no fixed font') }
	gc := vx11.create_gc(d, vx11.Drawable(window.id), 0, unsafe { nil })
	vx11.set_graphics_exposures(d, gc, 0)
	mut canvas := &Canvas{ connection: connection, window: window, gc: gc, small: s }
	canvas.resize(width, height)!
	return canvas
}

pub fn (mut c Canvas) resize(width int, height int) ! {
	d := c.connection.raw()!
	if width <= 0 || height <= 0 { return }
	if c.pixmap != 0 { vx11.free_pixmap(d, c.pixmap) }
	c.width = width
	c.height = height
	depth := vx11.default_depth(d, vx11.default_screen(d))
	c.pixmap = vx11.create_pixmap(d, vx11.Drawable(c.window.id), u32(width), u32(height), u32(depth))
}

fn (mut c Canvas) ink(color string) ! {
	if color !in c.colors { c.colors[color] = c.connection.color(color)! }
	vx11.set_foreground(c.connection.raw()!, c.gc, c.colors[color])
}

pub fn (mut c Canvas) rect(x int, y int, w int, h int, color string) ! {
	if w <= 0 || h <= 0 { return }
	c.ink(color)!
	vx11.fill_rectangle(c.connection.raw()!, vx11.Drawable(c.pixmap), c.gc, i32(x), i32(y), u32(w), u32(h))
}

pub fn (mut c Canvas) circle(x int, y int, diameter int, color string) ! {
	if diameter <= 0 { return }
	c.ink(color)!
	vx11.fill_arc(c.connection.raw()!, vx11.Drawable(c.pixmap), c.gc, i32(x), i32(y), u32(diameter), u32(diameter), 0, 360 * 64)
}

pub fn (mut c Canvas) round_rect(x int, y int, w int, h int, r int, color string) ! {
	c.rect(x + r, y, w - 2 * r, h, color)!
	c.rect(x, y + r, w, h - 2 * r, color)!
	c.circle(x, y, 2 * r, color)!
	c.circle(x + w - 2 * r, y, 2 * r, color)!
	c.circle(x, y + h - 2 * r, 2 * r, color)!
	c.circle(x + w - 2 * r, y + h - 2 * r, 2 * r, color)!
}

pub fn (mut c Canvas) line(x1 int, y1 int, x2 int, y2 int, color string) ! {
	c.ink(color)!
	vx11.draw_line(c.connection.raw()!, vx11.Drawable(c.pixmap), c.gc, i32(x1), i32(y1), i32(x2), i32(y2))
}

pub fn (mut c Canvas) text(x int, y int, text string, color string, big bool) ! {
	if big {
		c.scaled_text(x, y, text, color, 2)!
		return
	}
	c.ink(color)!
	font := c.small
	vx11.set_font(c.connection.raw()!, c.gc, font.fid)
	vx11.draw_string(c.connection.raw()!, vx11.Drawable(c.pixmap), c.gc, i32(x), i32(y), &char(text.str), i32(text.len))
}

pub fn (c &Canvas) present() ! {
	d := c.connection.raw()!
	vx11.copy_area(d, vx11.Drawable(c.pixmap), vx11.Drawable(c.window.id), c.gc, 0, 0, u32(c.width), u32(c.height), 0, 0)
	c.connection.flush()!
}

pub fn (mut c Canvas) close() {
	if d := c.connection.raw() {
		vx11.free_gc(d, c.gc)
		vx11.free_pixmap(d, c.pixmap)
		vx11.free_font(d, c.small)
	}
}

// Screenshot the actual off-screen X drawable, including its rendered core fonts.
// --screenshot writes PPM and exits; --smoke draws and exits without a file.
pub fn (c &Canvas) finish_preview() !bool {
	if '--smoke' in os.args {
		c.connection.sync()!
		return true
	}
	at := os.args.index('--screenshot')
	if at < 0 { return false }
	if at + 1 >= os.args.len { return error('--screenshot requires an output .ppm path') }
	c.connection.sync()!
	image := vx11.get_image(c.connection.raw()!, vx11.Drawable(c.pixmap), 0, 0, u32(c.width), u32(c.height), vx11.x_all_planes, vx11.z_pixmap)
	if image == unsafe { nil } { return error('cannot read screenshot') }
	defer { vx11.destroy_image(image) }
	visual := c.window.attributes()!.visual
	mut pixels := []u8{cap: c.width * c.height * 3}
	for y in 0 .. c.height {
		for x in 0 .. c.width {
			pixel := vx11.get_pixel(image, i32(x), i32(y))
			for mask in [visual.red_mask, visual.green_mask, visual.blue_mask] {
				mut m := mask
				mut value := pixel & mask
				if m == 0 { return error('screenshots require a TrueColor visual') }
				for m & 1 == 0 {
					m >>= 1
					value >>= 1
				}
				pixels << u8(value * 255 / m)
			}
		}
	}
	mut file := os.create(os.args[at + 1])!
	defer { file.close() }
	file.write_string('P6\n${c.width} ${c.height}\n255\n')!
	file.write(pixels)!
	return true
}

pub fn (mut c Canvas) arc(x int, y int, diameter int, extent int, color string) ! {
	if extent == 0 { return }
	c.ink(color)!
	d := c.connection.raw()!
	vx11.set_line_attributes(d, c.gc, 6, vx11.line_solid, vx11.cap_round, vx11.join_round)
	vx11.draw_arc(d, vx11.Drawable(c.pixmap), c.gc, i32(x), i32(y), u32(diameter), u32(diameter), 90 * 64, i32(-extent * 64))
	vx11.set_line_attributes(d, c.gc, 0, vx11.line_solid, vx11.cap_butt, vx11.join_miter)
}

pub fn (mut c Canvas) centered(cx int, y int, text string, color string, big bool) ! {
	font := c.small
	width := vx11.text_width(font, &char(text.str), i32(text.len))
	c.text(cx - int(width) * (if big { 2 } else { 1 }) / 2, y, text, color, big)!
}

pub fn minimum_size(connection &vx11.Connection, window &vx11.WindowHandle, width int, height int) ! {
	hints := vx11.XSizeHints{ flags: vx11.p_min_size, min_width: i32(width), min_height: i32(height) }
	vx11.set_wm_normal_hints(connection.raw()!, window.id, &hints)
}

// Cache server-rendered bitmap glyph runs and scale them with XFillRectangles.
// This keeps headings readable even on a server with only the built-in font.
pub fn (mut c Canvas) scaled_text(x int, y int, text string, color string, scale int) ! {
	if text.len == 0 { return }
	d := c.connection.raw()!
	if text !in c.lettering {
		// Interactive examples can generate many distinct display strings.
		if c.lettering.len >= 256 { c.lettering.clear() }
		width := vx11.text_width(c.small, &char(text.str), i32(text.len))
		height := c.small.ascent + c.small.descent
		bitmap := vx11.create_pixmap(d, vx11.Drawable(c.window.id), u32(width), u32(height), 1)
		defer { vx11.free_pixmap(d, bitmap) }
		gc := vx11.create_gc(d, vx11.Drawable(bitmap), 0, unsafe { nil })
		defer { vx11.free_gc(d, gc) }
		vx11.set_foreground(d, gc, 0)
		vx11.fill_rectangle(d, vx11.Drawable(bitmap), gc, 0, 0, u32(width), u32(height))
		vx11.set_foreground(d, gc, 1)
		vx11.set_font(d, gc, c.small.fid)
		vx11.draw_string(d, vx11.Drawable(bitmap), gc, 0, c.small.ascent, &char(text.str), i32(text.len))
		image := vx11.get_image(d, vx11.Drawable(bitmap), 0, 0, u32(width), u32(height), 1, vx11.z_pixmap)
		if image == unsafe { nil } { return error('cannot rasterize heading') }
		defer { vx11.destroy_image(image) }
		mut runs := []vx11.XRectangle{}
		for row in 0 .. int(height) {
			mut col := 0
			for col < int(width) {
				if vx11.get_pixel(image, i32(col), i32(row)) == 0 {
					col++
					continue
				}
				start := col
				for col < int(width) && vx11.get_pixel(image, i32(col), i32(row)) != 0 { col++ }
				runs << vx11.XRectangle{ x: i16(start), y: i16(row), width: u16(col - start), height: 1 }
			}
		}
		c.lettering[text] = runs
	}
	mut rectangles := []vx11.XRectangle{}
	for run in c.lettering[text] {
		rectangles << vx11.XRectangle{ x: i16(x + int(run.x) * scale), y: i16(y - int(c.small.ascent) * scale + int(run.y) * scale), width: u16(int(run.width) * scale), height: u16(scale) }
	}
	c.ink(color)!
	vx11.fill_rectangles(d, vx11.Drawable(c.pixmap), c.gc, rectangles.data, i32(rectangles.len))
}

// Borrow the backing drawable for another renderer, such as Xft. A resize
// replaces it: close that renderer first, then bind a new one after resizing.
pub fn (c &Canvas) drawable() !vx11.Drawable {
	c.connection.raw()!
	if c.pixmap == 0 { return error('canvas has no backing pixmap') }
	return vx11.Drawable(c.pixmap)
}

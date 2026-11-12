module main

import vx11
import vx11.xft
import vx11.fontconfig

fn main() {
	mut connection := vx11.connect('')!
	defer { connection.close() }
	mut window := connection.new_window(width: 640, height: 300, title: 'Xft integration')!
	defer { window.destroy() }
	mut request := fontconfig.parse('monospace:pixelsize=22')!
	defer { request.close() }
	mut font := xft.open_pattern(connection, request)!
	defer { font.close() }
	assert request.string_value(fontconfig.family)! == 'monospace'
	assert font.metrics()!.height > 0
	assert font.extents('Hello Ω')!.x_advance > 0
	assert font.contains(`A`)!
	assert font.glyph(`A`)! > 0
	mut fallback := font.fallback(`Ω`)!
	defer { fallback.close() }
	assert fallback.contains(`Ω`)!
	mut draw := xft.for_window(connection, window)!
	defer { draw.close() }
	window.show()!
	draw.rectangle(0, 0, 640, 300, '#10151d')!
	draw.text(font, 20, 45, 'Hello Ω — Xft', '#eef4f7')!
	draw.glyphs([xft.Glyph{ font: font, index: font.glyph(`A`)!, x: 20, y: 90 },
		xft.Glyph{ font: fallback, index: fallback.glyph(`Ω`)!, x: 50, y: 90 }], '#9becb7')!
	draw.clip([vx11.XRectangle{ x: 100, y: 100, width: 20, height: 20 }])!
	draw.rectangle(0, 0, 640, 300, '#ff0000')!
	draw.clear_clip()!
	connection.sync()!
	image := vx11.get_image(connection.raw()!, vx11.Drawable(window.id), 0, 0, 640, 300, vx11.x_all_planes, vx11.z_pixmap)
	assert image != unsafe { nil }
	background := vx11.get_pixel(image, 0, 0)
	assert vx11.get_pixel(image, 105, 105) != background
	assert vx11.get_pixel(image, 95, 105) == background
	mut ink := 0
	for y in 15 .. 50 {
		for x in 20 .. 220 { if vx11.get_pixel(image, i32(x), i32(y)) != background { ink++ } }
	}
	assert ink > 20
	vx11.destroy_image(image)
	// Re-target a backing pixmap, as a terminal does on resize.
	raw := connection.raw()!
	screen := vx11.default_screen(raw)
	pixmap := vx11.create_pixmap(raw, vx11.Drawable(window.id), 80, 80, u32(vx11.default_depth(raw, screen)))
	draw.change(vx11.Drawable(pixmap))!
	draw.rectangle(0, 0, 80, 80, '#223344')!
	draw.text(font, 0, 30, 'abc', '#ffffff')!
	draw.change(vx11.Drawable(window.id))!
	vx11.free_pixmap(raw, pixmap)
	mut other := vx11.connect('')!
	mut other_font := xft.open_font(other, 'monospace:pixelsize=12')!
	mut mismatch := false
	draw.text(other_font, 0, 0, 'wrong display', '#ffffff') or { mismatch = true }
	assert mismatch
	other_font.close()
	other.close()
	font.close()
	font.close()
	mut closed_font := false
	draw.text(font, 0, 0, 'closed', '#ffffff') or { closed_font = true }
	assert closed_font
	draw.close()
	draw.close()
	mut closed_draw := false
	draw.clear_clip() or { closed_draw = true }
	assert closed_draw
	fallback.close()
	window.destroy()
	connection.close()
	mut closed_connection := false
	xft.open_font(connection, 'monospace') or { closed_connection = true }
	assert closed_connection
	println('PASS: pattern ownership, Xft fonts, Unicode, fallback, glyph batches, clipping, pixmaps, and lifetimes')
}

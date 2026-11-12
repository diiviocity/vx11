// Antialiased UTF-8 text and positioned terminal glyphs, with explicit ownership.
module main

import vx11
import vx11.xft
import vx11.fontconfig
import vx11.examples.demo

fn text_draw(connection &vx11.Connection, window &vx11.WindowHandle, canvas &demo.Canvas) !&xft.Draw {
	attrs := window.attributes()!
	return xft.new_draw(connection, canvas.drawable()!, attrs.visual, attrs.colormap)
}

fn render_text(mut canvas demo.Canvas, mut draw xft.Draw, heading &xft.Font, body &xft.Font, mono &xft.Font) ! {
	canvas.rect(0, 0, canvas.width, canvas.height, '#10151d')!
	draw.text(body, 32, 40, 'VX11 / TEXT LAB', '#9becb7')!
	draw.text(heading, 32, 93, 'Type, without the pixels.', '#eef4f7')!
	draw.text(body, 32, 127, 'Antialiased fonts, Unicode, and terminal-style glyph placement.', '#91a3b4')!
	canvas.round_rect(32, 156, canvas.width - 64, 112, 12, '#1a2430')!
	draw.text(body, 52, 190, 'UTF-8 / XftDrawStringUtf8', '#9becb7')!
	draw.text(heading, 52, 235, 'Café · Ελληνικά · Кириллица', '#eef4f7')!
	canvas.round_rect(32, 286, canvas.width - 64, 125, 12, '#1a2430')!
	draw.text(body, 52, 322, 'POSITIONED GLYPHS / one batch, explicit cell coordinates', '#9becb7')!
	line := 'user@vx11 ~ $ printf "hello, terminal"'
	cell := mono.extents('M')!.x_advance
	mut glyphs := []xft.Glyph{}
	for i, r in line.runes() {
		glyphs << xft.Glyph{ font: mono, index: mono.glyph(r)!, x: 52 + i * cell, y: 371 }
	}
	draw.glyphs(glyphs, '#eef4f7')!
	canvas.round_rect(32, 429, canvas.width - 64, 105, 12, '#1a2430')!
	mut pattern := mono.pattern()!
	defer { pattern.close() }
	family := pattern.string_value(fontconfig.family)!
	draw.text(body, 52, 465, 'FONTCONFIG MATCH / ${family}', '#9becb7')!
	if mut fallback := mono.fallback(`界`) {
		defer { fallback.close() }
		draw.text(fallback, 52, 510, '界', '#eef4f7')!
		draw.text(body, 92, 510, 'A separate font selected for this character.', '#91a3b4')!
	} else {
		draw.text(body, 52, 510, 'Install a CJK font to see the fallback sample.', '#91a3b4')!
	}
	draw.text(body, 32, canvas.height - 28, 'Q / Esc  Close    Resize to reflow    Complex-script shaping needs HarfBuzz.', '#76889c')!
	canvas.present()!
}

fn main() {
	mut connection := vx11.connect('')!
	defer { connection.close() }
	mut window := connection.new_window(
		title:  'VX11 Text Lab - Xft and Fontconfig'
		width:  960
		height: 600
	)!
	defer { window.destroy() }
	demo.minimum_size(connection, window, 900, 600)!
	mut canvas := demo.new_canvas(connection, window, 960, 600)!
	defer { canvas.close() }
	mut heading := xft.open_font(connection, 'sans:pixelsize=30')!
	defer { heading.close() }
	mut body := xft.open_font(connection, 'sans:pixelsize=16')!
	defer { body.close() }
	mut mono := xft.open_font(connection, 'monospace:pixelsize=18')!
	defer { mono.close() }
	mut draw := text_draw(connection, window, canvas)!
	defer { draw.close() }
	window.show()!
	render_text(mut canvas, mut draw, heading, body, mono)!
	if canvas.finish_preview()! { return }
	for {
		event := connection.next_event()!
		if window.should_close(event) { break }
		if event.kind == vx11.key_press && connection.key_text(event)! in ['q', 'Q', '\x1b'] {
			break
		}
		if size := event.configure() {
			draw.close()
			canvas.resize(size.width, size.height)!
			draw = text_draw(connection, window, canvas)!
		}
		render_text(mut canvas, mut draw, heading, body, mono)!
	}
}

// Interactive generative art, using a deterministic formula rather than assets.
module main

import math
import vx11
import vx11.examples.demo

fn poster(mut c demo.Canvas, variant int) ! {
	palettes := [['#f2eadb', '#d15b39', '#e4ab63', '#243c46'],
		['#e3e9ed', '#406486', '#e8a087', '#172c48'], ['#e9e7d9', '#74805a', '#d4ad65', '#333b30']]
	p := palettes[variant % 3]
	c.rect(0, 0, c.width, c.height, p[0])!
	margin := 48
	c.text(margin, 48, 'FIELD NOTES                  V / X11', p[3], false)!
	c.line(margin, 68, c.width - margin, 68, p[3])!
	c.text(margin, 112, 'HARMONIC FIELDS', p[3], true)!
	c.text(margin, 139, 'A study in repetition, interference, and color.', p[3], false)!
	artx := margin
	arty := 170
	aw := c.width - margin * 2
	ah := c.height - 280
	c.rect(artx, arty, aw, ah, p[3])!
	// Concentric ripples are drawn as offset ribbons. All geometry is generated.
	for row in 0 .. 72 {
		mut lastx := artx
		mut lasty := arty
		for col in 0 .. 180 {
			x := f64(col) / 179
			wave := math.sin(x * 9.4 + f64(variant) * 0.7 + f64(row) * 0.045)
			envelope := math.sin(x * math.pi)
			y := f64(row) / 71 + wave * envelope * 0.12
			px := artx + int(x * f64(aw))
			py := arty + int(ah / 6) + int(y * f64(ah * 2 / 3))
			color := if row % 9 < 3 {
				p[1]
			} else if row % 9 < 6 {
				p[2]
			} else {
				p[0]
			}
			if col > 0 { c.line(lastx, lasty, px, py, color)! }
			lastx = px
			lasty = py
		}
	}
	c.circle(artx + aw - 98, arty + 28, 42, p[2])!
	c.text(margin, c.height - 71, 'No. 0${variant + 1} / THREE COLORWAYS', p[3], false)!
	c.text(margin, c.height - 43, 'Space / click  Next palette    Q / Esc  Close', p[3], false)!
	c.text(c.width - 180, c.height - 43, '100% XLIB', p[3], false)!
	c.present()!
}

fn main() {
	mut display := vx11.connect('')!
	defer { display.close() }
	mut window := display.new_window(
		title:  'Harmonic Fields - generative poster'
		width:  760
		height: 820
		events: vx11.exposure_mask | vx11.structure_notify_mask | vx11.key_press_mask | vx11.button_press_mask
	)!
	defer { window.destroy() }
	demo.minimum_size(display, window, 600, 640)!
	mut canvas := demo.new_canvas(display, window, 760, 820)!
	defer { canvas.close() }
	mut variant := 0
	window.show()!
	poster(mut canvas, variant)!
	if canvas.finish_preview()! { return }
	for {
		event := display.next_event()!
		if window.should_close(event) { break }
		if event.kind == vx11.key_press {
			key := display.key_text(event)!
			if key in ['q', 'Q', '\x1b'] { break }
			if key == ' ' { variant = (variant + 1) % 3 }
		}
		if event.kind == vx11.button_press { variant = (variant + 1) % 3 }
		if size := event.configure() { canvas.resize(size.width, size.height)! }
		poster(mut canvas, variant)!
	}
}

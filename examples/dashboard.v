// A deliberately styled UI made from core Xlib drawing and native event helpers.
module main

import math
import vx11
import vx11.examples.demo

fn dashboard(mut c demo.Canvas, selected int, dimensions string, extensions int) ! {
	c.rect(0, 0, c.width, c.height, '#10151d')!
	c.rect(0, 0, 176, c.height, '#171e29')!
	c.circle(24, 27, 24, '#9becb7')!
	c.text(60, 45, 'VX / DESK', '#edf4f7', false)!
	c.text(24, 105, 'YOUR WORKSPACE', '#76889c', false)!
	for i, label in ['Overview', 'Activity', 'Connections'] {
		y := 126 + i * 48
		if i == 0 { c.round_rect(12, y, 152, 36, 8, '#273748')! }
		c.text(28, y + 23, label, if i == 0 { '#a5f1c1' } else { '#99a9ba' }, false)!
	}
	c.text(24, c.height - 52, 'BUILT WITH V', '#9becb7', false)!
	c.text(24, c.height - 30, 'libX11 / native UI', '#76889c', false)!
	x := 208
	right := c.width - 32
	w := right - x
	c.text(x, 44, 'DESKTOP / OVERVIEW', '#8b9eaf', false)!
	c.text(x, 83, 'A little closer to the metal.', '#eef4f7', true)!
	c.text(x, 110, 'Real display information. Illustrative traffic data.', '#91a3b4', false)!
	cardw := (w - 32) / 3
	for i, label in ['CONNECTION', 'DISPLAY SIZE', 'EXTENSIONS'] {
		cx := x + i * (cardw + 16)
		c.round_rect(cx, 140, cardw, 106, 12, '#1a2430')!
		c.text(cx + 20, 167, label, '#8b9eaf', false)!
		value := if i == 0 {
			'Connected'
		} else if i == 1 {
			dimensions
		} else {
			'${extensions} available'
		}
		c.text(cx + 20, 204, value, if i == 0 { '#9becb7' } else { '#edf4f7' }, true)!
		c.text(cx + 20, 229, if i == 0 {
			'X server responding'
		} else if i == 1 {
			'Root window geometry'
		} else {
			'Advertised by server'
		}, '#76889c', false)!
	}
	cy := 270
	ch := c.height - 360
	c.round_rect(x, cy, w, ch, 12, '#1a2430')!
	c.text(x + 24, cy + 35, 'REQUEST ACTIVITY', '#edf4f7', false)!
	for i, label in ['Traffic', 'Latency'] {
		tx := right - 206 + i * 92
		c.round_rect(tx, cy + 15, 84, 28, 6, if i == selected { '#365349' } else { '#263340' })!
		c.text(tx + 12, cy + 34, label, if i == selected { '#b8f5ce' } else { '#91a3b4' }, false)!
	}
	gx := x + 52
	gy := cy + 66
	gw := w - 84
	gh := ch - 112
	for i in 0 .. 5 {
		yy := gy + i * gh / 4
		c.line(gx, yy, gx + gw, yy, '#2b3847')!
		c.text(x + 18, yy + 4, '${(4 - i) * 25}', '#708397', false)!
	}
	mut lastx := gx
	mut lasty := gy + gh
	for i in 0 .. 100 {
		px := gx + i * gw / 99
		wave := math.sin(f64(i) * 0.11 + f64(selected)) * 0.19 + math.sin(f64(i) * 0.39) * 0.07
		value := 0.48 + wave + f64(i) * 0.002
		py := gy + gh - int(value * f64(gh))
		c.line(px, py, px, gy + gh, '#243c3b')!
		if i > 0 { c.line(lastx, lasty, px, py, '#9becb7')! }
		lastx = px
		lasty = py
	}
	c.circle(lastx - 4, lasty - 4, 8, '#b9ffd0')!
	c.text(gx, cy + ch - 20, '09:00', '#76889c', false)!
	c.text(gx + gw / 2 - 16, cy + ch - 20, '12:00', '#76889c', false)!
	c.text(gx + gw - 30, cy + ch - 20, '15:00', '#76889c', false)!
	c.circle(x, c.height - 62, 8, '#9becb7')!
	c.text(x + 18, c.height - 54, 'Rendered with Xlib primitives + an off-screen pixmap.', '#91a3b4', false)!
	c.text(x, c.height - 28, '1 / 2  Switch chart     Q / Esc  Close     Resize to reflow', '#76889c', false)!
	c.present()!
}

fn main() {
	mut display := vx11.connect('')!
	defer { display.close() }
	mut window := display.new_window(
		title:  'VX Desk - X11 dashboard'
		width:  1000
		height: 660
		events: vx11.exposure_mask | vx11.structure_notify_mask | vx11.key_press_mask | vx11.button_press_mask
	)!
	defer { window.destroy() }
	demo.minimum_size(display, window, 840, 580)!
	mut canvas := demo.new_canvas(display, window, 1000, 660)!
	defer { canvas.close() }
	dw, dh := display.dimensions()!
	dimensions := '${dw} x ${dh}'
	extensions := display.extension_names()!.len
	mut selected := 0
	window.show()!
	dashboard(mut canvas, selected, dimensions, extensions)!
	if canvas.finish_preview()! { return }
	for {
		event := display.next_event()!
		if window.should_close(event) { break }
		if key := event.key() {
			_ = key
			text := display.key_text(event)!
			if text in ['q', 'Q', '\x1b'] { break }
			if text in ['1', '2'] { selected = if text == '1' { 0 } else { 1 } }
		}
		if button := event.button() {
			if button.y >= 285 && button.y <= 313 {
				if button.x >= canvas.width - 238 && button.x < canvas.width - 146 { selected = 0 }
				if button.x >= canvas.width - 146 && button.x < canvas.width - 54 { selected = 1 }
			}
		}
		if size := event.configure() { canvas.resize(size.width, size.height)! }
		dashboard(mut canvas, selected, dimensions, extensions)!
	}
}

// Rounded-window focus timer. SHAPE changes the actual server-side window region.
module main

import time
import vx11
import vx11.shape
import vx11.examples.demo

fn rounded_window(extension &shape.Extension, window vx11.Window, w int, h int) ! {
	mut rectangles := []shape.Rectangle{}
	radius := 24
	// Horizontal scan lines approximate quarter circles without a bitmap mask.
	for y in 0 .. h {
		mut inset := 0
		if y < radius || y >= h - radius {
			dy := if y < radius { radius - y - 1 } else { y - (h - radius) }
			for inset < radius && (radius - inset) * (radius - inset) + dy * dy > radius * radius {
				inset++
			}
		}
		rectangles << shape.Rectangle{ x: inset, y: y, width: w - 2 * inset, height: 1 }
	}
	extension.combine(window, .bounding, rectangles, .set)!
}

fn focus(mut c demo.Canvas, remaining int, running bool) ! {
	c.rect(0, 0, c.width, c.height, '#192c2b')!
	c.text(30, 40, 'STILL / FOCUS', '#b4d0c2', false)!
	c.circle(c.width - 43, 28, 8, if running { '#c8efad' } else { '#d7b77b' })!
	cx := c.width / 2
	c.centered(cx, 83, 'MAKE SOME SPACE', '#7eaa99', false)!
	c.arc(cx - 104, 110, 208, 360, '#344b42')!
	c.arc(cx - 104, 110, 208, (1500 - remaining) * 360 / 1500, '#c8efad')!
	minutes := remaining / 60
	seconds := remaining % 60
	label := '${minutes:02}:${seconds:02}'
	c.scaled_text(cx - 60, 225, label, '#eef5df', 4)!
	c.centered(cx, 241, if running { 'STAY WITH IT' } else { 'READY WHEN YOU ARE' }, '#a5bca8', false)!
	c.round_rect(32, c.height - 124, c.width - 64, 46, 12, '#c8efad')!
	c.centered(cx, c.height - 95, if running { 'PAUSE' } else { 'START' }, '#213a2e', false)!
	c.text(30, c.height - 49, 'Space / click  Start or pause', '#a5bca8', false)!
	c.text(30, c.height - 28, 'R  Reset       Q / Esc  Close', '#729585', false)!
	c.present()!
}

fn main() {
	mut display := vx11.connect('')!
	defer { display.close() }
	shapes := shape.bind(display)!
	mut window := display.new_window(
		title:  'Still - a focus timer'
		width:  360
		height: 470
		events: vx11.exposure_mask | vx11.structure_notify_mask | vx11.key_press_mask | vx11.button_press_mask
	)!
	defer { window.destroy() }
	demo.minimum_size(display, window, 360, 470)!
	mut canvas := demo.new_canvas(display, window, 360, 470)!
	defer { canvas.close() }
	rounded_window(shapes, window.id, 360, 470)!
	mut running := false
	mut remaining := 1500
	mut last := time.now().unix_milli()
	mut dirty := true
	window.show()!
	focus(mut canvas, remaining, running)!
	if canvas.finish_preview()! { return }
	mut quit := false
	for !quit {
		for event in display.poll_events()! {
			if window.should_close(event) { quit = true }
			if event.kind == vx11.key_press {
				key := display.key_text(event)!
				if key in ['q', 'Q', '\x1b'] { quit = true }
				if key == ' ' {
					running = !running
					last = time.now().unix_milli()
					dirty = true
				}
				if key in ['r', 'R'] {
					remaining = 1500
					running = false
					dirty = true
				}
			}
			if button := event.button() {
				if button.y >= canvas.height - 124 && button.y < canvas.height - 78 && button.x >= 32 && button.x < canvas.width - 32 {
					running = !running
					last = time.now().unix_milli()
					dirty = true
				}
			}
			if size := event.configure() {
				canvas.resize(size.width, size.height)!
				rounded_window(shapes, window.id, size.width, size.height)!
				dirty = true
			}
			if event.kind == vx11.expose { dirty = true }
		}
		now := time.now().unix_milli()
		if running && now - last >= 1000 {
			elapsed := int((now - last) / 1000)
			remaining -= elapsed
			if remaining <= 0 {
				remaining = 0
				running = false
			}
			last += i64(elapsed) * 1000
			dirty = true
		}
		if dirty {
			focus(mut canvas, remaining, running)!
			dirty = false
		}
		time.sleep(30 * time.millisecond)
	}
}

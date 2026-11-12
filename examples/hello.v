module main

import vx11

fn main() {
	mut display := vx11.connect('') or {
		eprintln(err)
		return
	}
	defer { display.close() }
	mut window := display.new_window(title: 'Hello from V', width: 640, height: 360) or {
		eprintln(err)
		return
	}
	defer { window.destroy() }
	mut pen := window.graphics() or {
		eprintln(err)
		return
	}
	defer { pen.close() }
	pen.foreground(display.black_pixel()!)!
	window.show()!
	for {
		event := display.next_event()!
		if window.should_close(event) || event.kind == vx11.key_press { break }
		if exposed := event.expose() {
			if exposed.remaining == 0 {
				pen.text(24, 40, 'Hello, X11! Press any key to quit.')!
				pen.rectangle(24, 64, 200, 100, false)!
				pen.line(24, 64, 224, 164)!
				display.flush()!
			}
		}
	}
}

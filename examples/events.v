module main

import vx11

// A bound method can be passed directly to Connection.run.
@[heap]
struct App {
	window &vx11.WindowHandle
}

fn (app &App) on_event(event vx11.Event) bool {
	if app.window.should_close(event) { return false }
	if key := event.key() {
		println('key ${key.code}, modifiers ${key.state}, position ${key.x},${key.y}')
		return false
	}
	if size := event.configure() { println('resized to ${size.width} x ${size.height}') }
	return true
}

fn main() {
	mut display := vx11.connect('')!
	defer { display.close() }
	mut window := display.new_window(title: 'V method callbacks')!
	defer { window.destroy() }
	window.show()!
	app := App{window}
	display.run(app.on_event)!
}

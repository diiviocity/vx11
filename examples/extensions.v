module main

import vx11
import vx11.xinerama
import vx11.shape
import vx11.screensaver

fn main() {
	mut display := vx11.connect('')!
	defer { display.close() }
	if xinerama.available(display)! {
		monitors := xinerama.bind(display)!
		println('Xinerama ${monitors.major}.${monitors.minor}, active: ${monitors.active()!}')
		for screen in monitors.screens()! {
			println('head ${screen.number}: ${screen.width}x${screen.height} at ${screen.x},${screen.y}')
		}
	} else {
		println('Xinerama is unavailable')
	}
	if screensaver.available(display)! {
		saver := screensaver.bind(display)!
		println('Idle for ${saver.idle_ms()!} ms')
	} else {
		println('Screen saver extension is unavailable')
	}
	if shape.available(display)! {
		shapes := shape.bind(display)!
		println('SHAPE ${shapes.major}.${shapes.minor}')
	} else {
		println('SHAPE is unavailable')
	}
}

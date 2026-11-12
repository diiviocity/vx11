module main

import os
import vx11
import vx11.xinerama
import vx11.shape
import vx11.screensaver

fn main() {
	mut display := vx11.connect('')!
	defer { display.close() }
	if '--unavailable' in os.args {
		assert !xinerama.available(display)!
		assert !screensaver.available(display)!
		mut x_rejected := false
		xinerama.bind(display) or { x_rejected = true }
		assert x_rejected
		mut s_rejected := false
		screensaver.bind(display) or { s_rejected = true }
		assert s_rejected
		display.close()
		mut closed := false
		shape.available(display) or { closed = true }
		assert closed
		println('PASS: missing extensions and closed connections')
		return
	}
	assert xinerama.available(display)!
	monitors := xinerama.bind(display)!
	assert monitors.active()!
	heads := monitors.screens()!
	assert heads.len == 2
	assert heads[0].number == 0 && heads[0].width == 640 && heads[0].height == 480
	assert heads[1].number == 1 && heads[1].width == 800 && heads[1].height == 600
	assert shape.available(display)!
	shapes := shape.bind(display)!
	mut window := display.new_window(width: 200, height: 150)!
	defer { window.destroy() }
	shapes.watch(window.id, true)!
	shapes.combine(window.id, .bounding, [shape.Rectangle{ x: 10, y: 20, width: 80, height: 60 }], .set)!
	display.sync()!
	rects := shapes.rectangles(window.id, .bounding)!
	assert rects.len == 1
	assert rects[0].x == 10 && rects[0].y == 20 && rects[0].width == 80 && rects[0].height == 60
	extents := shapes.extents(window.id)!
	assert extents.bounding_shaped
	assert extents.bounding.width == 80 && extents.bounding.height == 60
	events := display.poll_events()!
	mut found := false
	for event in events {
		if notification := shapes.event(event) {
			assert notification.window == window.id
			assert notification.kind == shape.shape_bounding
			assert notification.shaped != 0
			found = true
		}
	}
	assert found
	shapes.combine(window.id, .bounding, [], .set)!
	assert shapes.rectangles(window.id, .bounding)!.len == 0
	shapes.reset(window.id, .bounding)!
	assert !shapes.extents(window.id)!.bounding_shaped
	mut invalid := false
	shapes.combine(window.id, .bounding, [shape.Rectangle{ x: 40000, width: 1, height: 1 }], .set) or { invalid = true }
	assert invalid
	shapes.combine(window.id, .input, [shape.Rectangle{ width: 10, height: 10 }], .set)!
	assert shapes.rectangles(window.id, .input)![0].width == 10
	shapes.reset(window.id, .input)!
	assert screensaver.available(display)!
	saver := screensaver.bind(display)!
	root := vx11.Drawable(display.root()!)
	saver.watch(root, true)!
	info := saver.info(root)!
	assert info.event_mask & screensaver.notify_mask != 0
	assert info.state in [screensaver.off, screensaver.on, screensaver.disabled]
	assert saver.idle_ms()! >= info.idle_ms
	// Use a private test window as the registry resource; no screen saver activation.
	saver.register(0, vx11.XID(window.id), vx11.Atom(vx11.xa_window))!
	registration := saver.registration(0)!
	assert registration.xid == vx11.XID(window.id)
	assert registration.typ == vx11.Atom(vx11.xa_window)
	saver.unregister(0)!
	mut unregistered := false
	saver.registration(0) or { unregistered = true }
	assert unregistered
	saver.watch(root, false)!
	window.destroy()
	display.close()
	// Returned snapshots remain valid; borrowed extension handles reject use.
	assert heads[1].width == 800
	assert rects[0].height == 60
	mut x_closed := false
	monitors.screens() or { x_closed = true }
	assert x_closed
	mut shape_closed := false
	shapes.rectangles(window.id, .bounding) or { shape_closed = true }
	assert shape_closed
	mut saver_closed := false
	saver.idle_ms() or { saver_closed = true }
	assert saver_closed
	println('PASS: two Xinerama heads, shape regions/events, screen saver queries, and lifetimes')
}

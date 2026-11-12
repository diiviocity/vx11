module main

import vx11

fn expected_error(_ &vx11.Display, event &vx11.XErrorEvent) i32 {
	assert event.error_code == vx11.bad_window
	return 0
}

fn client_message_only(_ &vx11.Display, event &vx11.XEvent, _ vx11.XPointer) i32 {
	return if unsafe { event.@type } == vx11.client_message { 1 } else { 0 }
}

fn main() {
	mut c := vx11.connect('')!
	defer { c.close() }
	previous_sync := vx11.synchronize(c.raw()!, 1)
	vx11.set_after_function(c.raw()!, previous_sync)
	mut w := c.new_window(title: 'V X11 integration', width: 200, height: 120)!
	defer { w.destroy() }
	assert w.title()! == 'V X11 integration'
	a := w.attributes()!
	assert a.width == 200 && a.height == 120
	assert c.atom_name(c.atom('VX11_TEST')!)! == 'VX11_TEST'
	assert c.extension_names()!.len > 0
	mut opcode := i32(0)
	mut event_base := i32(0)
	mut error_base := i32(0)
	mut major := i32(1)
	mut minor := i32(0)
	assert c.xkb_query_extension(&opcode, &event_base, &error_base, &major, &minor)! != 0
	mut keyboard := vx11.XkbStateRec{}
	assert c.xkb_get_state(vx11.xkb_use_core_kbd, &keyboard)! == 0
	previous := vx11.set_error_handler(expected_error)
	vx11.destroy_window(c.raw()!, 0)
	c.sync()!
	vx11.set_error_handler(previous)
	// Check the variadic adapter with real XIM attribute input and output.
	vx11.set_locale_modifiers(c'@im=none')
	im := vx11.open_im(c.raw()!, unsafe { nil }, unsafe { nil }, unsafe { nil })
	assert im != unsafe { nil }
	style := vx11.XIMStyle(vx11.xim_preedit_nothing | vx11.xim_status_nothing)
	ic := vx11.create_ic(im, [voidptr(vx11.xn_input_style.str), voidptr(style),
		voidptr(vx11.xn_client_window.str), voidptr(w.id)])!
	assert ic != unsafe { nil }
	mut returned_style := vx11.XIMStyle(0)
	assert vx11.get_ic_values(ic, [voidptr(vx11.xn_input_style.str), voidptr(&returned_style)])! == unsafe { nil }
	assert returned_style == style
	vx11.destroy_ic(ic)
	vx11.close_im(im)
	prop := c.atom('VX11_TEST_DATA')!
	w.set_property_bytes(prop, vx11.Atom(vx11.xa_string), 'hello\x00world'.bytes())!
	assert w.property(prop)!.bytes == 'hello\x00world'.bytes()
	w.set_property_words(prop, vx11.Atom(vx11.xa_cardinal), [u32(0), 0x12345678, 0xffffffff])!
	assert w.property(prop)!.words == [u32(0), 0x12345678, 0xffffffff]
	w.delete_property(prop)!
	mut missing := false
	w.property(prop) or { missing = true }
	assert missing
	mut pen := w.graphics()!
	defer { pen.close() }
	pen.foreground(c.black_pixel()!)!
	w.show()!
	c.sync()!
	events := c.poll_events()!
	assert events.any(it.kind == vx11.map_notify)
	pen.rectangle(0, 0, 32, 32, true)!
	pen.text(40, 40, 'V / Xlib')!
	c.sync()!
	image := vx11.get_image(c.raw()!, vx11.Drawable(w.id), 0, 0, 1, 1, ~vx11.CULong(0), vx11.z_pixmap)
	assert image != unsafe { nil }
	assert vx11.get_pixel(image, 0, 0) == c.black_pixel()!
	vx11.destroy_image(image)
	w.resize(240, 140)!
	c.sync()!
	assert w.attributes()!.width == 240
	assert w.children()!.len == 0
	// Exercise a format-32 WM close message through the server/event queue.
	mut event := vx11.XEvent{}
	unsafe {
		event.xclient.@type = vx11.client_message
		event.xclient.display = c.raw()!
		event.xclient.window = w.id
		event.xclient.message_type = c.atom('WM_PROTOCOLS')!
		event.xclient.format = 32
		event.xclient.data.l[0] = vx11.CLong(c.atom('WM_DELETE_WINDOW')!)
	}
	assert vx11.send_event(c.raw()!, w.id, 0, 0, &event) != 0
	c.sync()!
	mut received := vx11.XEvent{}
	assert vx11.check_if_event(c.raw()!, &received, client_message_only, vx11.XPointer(unsafe { nil })) != 0
	vx11.put_back_event(c.raw()!, &received)
	batch := c.poll_events()!
	assert batch.any(w.should_close(it))
	pen.close()
	pen.close()
	w.destroy()
	w.destroy()
	mut rejected := false
	w.show() or { rejected = true }
	assert rejected
	c.close()
	c.close()
	mut closed := false
	c.pending() or { closed = true }
	assert closed
	println('PASS: window, events, drawing, strings, properties, and resource lifecycle')
}

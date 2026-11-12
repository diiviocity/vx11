module vx11

@[params]
pub struct WindowOptions {
pub:
	title        string = 'V / X11'
	x            int
	y            int
	width        int = 640
	height       int = 480
	border_width int
	background   ?CULong
	border       ?CULong
	events       CLong = exposure_mask | key_press_mask | structure_notify_mask
}

// WindowHandle owns a server window. Keep its Connection open until destroy().
@[heap; noinit]
pub struct WindowHandle {
pub:
	id Window
mut:
	connection     &Connection = unsafe { nil }
	destroyed      bool
	delete_atom    Atom
	protocols_atom Atom
}

fn (w &WindowHandle) display() !&Display {
	if w.destroyed { return error('window is destroyed') }
	return w.connection.raw()
}

pub fn (c &Connection) new_window(options WindowOptions) !&WindowHandle {
	if options.width <= 0 || options.height <= 0 || options.width > 65535 || options.height > 65535 || options.border_width < 0 || options.border_width > 65535 {
		return error('invalid X11 window dimensions')
	}
	if options.title.contains('\x00') { return error('title contains NUL') }
	d := c.raw()!
	screen := default_screen(d)
	id := create_simple_window(d, root_window(d, screen), i32(options.x), i32(options.y), u32(options.width), u32(options.height), u32(options.border_width), options.border or { black_pixel(d, screen) }, options.background or { white_pixel(d, screen) })
	if id == 0 { return error('cannot allocate window') }
	mut w := &WindowHandle{ id: id, connection: c }
	w.set_title(options.title) or {
		w.destroy()
		return err
	}
	w.select_events(options.events) or {
		w.destroy()
		return err
	}
	w.enable_close() or {
		w.destroy()
		return err
	}
	return w
}

pub fn (mut w WindowHandle) destroy() {
	if !w.destroyed {
		if w.connection.display != unsafe { nil } { destroy_window(w.connection.display, w.id) }
		w.destroyed = true
	}
}

pub fn (w &WindowHandle) show() ! {
	map_window(w.display()!, w.id)
	w.connection.flush()!
}

pub fn (w &WindowHandle) hide() ! { unmap_window(w.display()!, w.id) }

pub fn (w &WindowHandle) clear() ! { clear_window(w.display()!, w.id) }

pub fn (w &WindowHandle) raise() ! { raise_window(w.display()!, w.id) }

pub fn (w &WindowHandle) lower() ! { lower_window(w.display()!, w.id) }

pub fn (w &WindowHandle) select_events(mask CLong) ! { select_input(w.display()!, w.id, mask) }

pub fn (w &WindowHandle) resize(width int, height int) ! {
	if width <= 0 || height <= 0 || width > 65535 || height > 65535 {
		return error('invalid X11 window dimensions')
	}
	resize_window(w.display()!, w.id, u32(width), u32(height))
}

pub fn (w &WindowHandle) move(x int, y int) ! { move_window(w.display()!, w.id, i32(x), i32(y)) }

pub fn (w &WindowHandle) set_title(title string) ! {
	if title.contains('\x00') { return error('title contains NUL') }
	d := w.display()!
	store_name(d, w.id, &char(title.str))
	// EWMH title is explicitly UTF-8; also keep the legacy WM_NAME for older WMs.
	w.set_property_bytes(w.connection.atom('_NET_WM_NAME')!, w.connection.atom('UTF8_STRING')!, title.bytes())!
}

pub fn (w &WindowHandle) title() !string {
	d := w.display()!
	mut p := unsafe { &char(nil) }
	if fetch_name(d, w.id, &p) == 0 || p == unsafe { nil } { return error('window has no title') }
	defer { free(p) }
	return unsafe { p.vstring().clone() }
}

pub fn (mut w WindowHandle) enable_close() ! {
	d := w.display()!
	w.delete_atom = w.connection.atom('WM_DELETE_WINDOW')!
	w.protocols_atom = w.connection.atom('WM_PROTOCOLS')!
	mut atom := w.delete_atom
	if set_wm_protocols(d, w.id, &atom, 1) == 0 { return error('cannot install WM_DELETE_WINDOW') }
}

pub fn (w &WindowHandle) should_close(event Event) bool {
	m := event.client_message() or { return false }
	return m.window == w.id && m.message_type == w.protocols_atom && Atom(m.data[0]) == w.delete_atom
}

pub fn (w &WindowHandle) attributes() !XWindowAttributes {
	mut a := XWindowAttributes{}
	if get_window_attributes(w.display()!, w.id, &a) == 0 {
		return error('cannot query window attributes')
	}
	return a
}

pub fn (w &WindowHandle) children() ![]Window {
	mut root := Window(0)
	mut parent := Window(0)
	mut children := unsafe { &Window(nil) }
	mut count := u32(0)
	if query_tree(w.display()!, w.id, &root, &parent, &children, &count) == 0 {
		return error('cannot query window tree')
	}
	defer { if children != unsafe { nil } { free(children) } }
	mut result := []Window{cap: int(count)}
	for i in 0 .. int(count) { result << unsafe { children[i] } }
	return result
}

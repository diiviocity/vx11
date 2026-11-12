module vx11

// Connection owns one Display. Close it after all windows and graphics contexts.
// Returned handles share this pointer, so close/destroy are idempotent.
@[heap; noinit]
pub struct Connection {
mut:
	display &Display = unsafe { nil }
}

// connect uses DISPLAY when name is empty. Strings are copied by XOpenDisplay.
pub fn connect(name string) !&Connection {
	if name.contains('\x00') { return error('display name contains NUL') }
	p := open_display(if name == '' { unsafe { nil } } else { &char(name.str) })
	if p == unsafe { nil } {
		return error('cannot open X display "${name}" (check DISPLAY and X authority)')
	}
	return &Connection{ display: p }
}

// raw exposes a borrowed Display pointer for the complete low-level API.
pub fn (c &Connection) raw() !&Display {
	if c.display == unsafe { nil } { return error('X display is closed') }
	return c.display
}

pub fn (mut c Connection) close() {
	if c.display != unsafe { nil } {
		close_display(c.display)
		c.display = unsafe { nil }
	}
}

pub fn (c &Connection) flush() ! { flush(c.raw()!) }

pub fn (c &Connection) sync() ! { sync(c.raw()!, 0) }

pub fn (c &Connection) screen_number() !int { return int(default_screen(c.raw()!)) }

pub fn (c &Connection) root() !Window { return default_root_window(c.raw()!) }

pub fn (c &Connection) black_pixel() !CULong {
	d := c.raw()!
	return black_pixel(d, default_screen(d))
}

pub fn (c &Connection) white_pixel() !CULong {
	d := c.raw()!
	return white_pixel(d, default_screen(d))
}

pub fn (c &Connection) dimensions() !(int, int) {
	d := c.raw()!
	screen := default_screen(d)
	return int(display_width(d, screen)), int(display_height(d, screen))
}

pub fn (c &Connection) atom(name string) !Atom {
	if name.contains('\x00') { return error('atom name contains NUL') }
	atom := intern_atom(c.raw()!, &char(name.str), 0)
	if atom == 0 { return error('cannot intern atom "${name}"') }
	return atom
}

pub fn (c &Connection) atom_name(atom Atom) !string {
	p := get_atom_name(c.raw()!, atom)
	if p == unsafe { nil } { return error('atom has no name') }
	defer { free(p) }
	return unsafe { p.vstring().clone() }
}

// extension_names copies and frees Xlib's string list.
pub fn (c &Connection) extension_names() ![]string {
	mut count := i32(0)
	p := list_extensions(c.raw()!, &count)
	if p == unsafe { nil } { return []string{} }
	defer { free_extension_list(p) }
	mut names := []string{cap: int(count)}
	for i in 0 .. int(count) { names << unsafe { p[i].vstring().clone() } }
	return names
}

pub fn (c &Connection) pending() !int { return int(pending(c.raw()!)) }

pub fn (c &Connection) next_event() !Event {
	mut raw := XEvent{}
	next_event(c.raw()!, &raw)
	return Event{ kind: int(unsafe { raw.@type }), raw: raw }
}

// poll_events drains the currently pending batch, without waiting for new events.
pub fn (c &Connection) poll_events() ![]Event {
	count := c.pending()!
	mut events := []Event{cap: count}
	for _ in 0 .. count { events << c.next_event()! }
	return events
}

// run calls a V function/closure for each event; returning false stops the loop.
pub fn (c &Connection) run(handler fn (Event) bool) ! {
	for { if !handler(c.next_event()!) { break } }
}

// key_text is the legacy XLookupString encoding (not guaranteed UTF-8).
// Use an input method and utf8_lookup_string for composed/UTF-8 text.
pub fn (c &Connection) key_text(event Event) !string {
	c.raw()!
	if event.kind != key_press && event.kind != key_release { return error('expected a key event') }
	mut key := unsafe { event.raw.xkey }
	mut buffer := [256]char{}
	mut symbol := KeySym(0)
	n := lookup_string(&key, &buffer[0], 256, &symbol, unsafe { nil })
	return unsafe { (&u8(&buffer[0])).vstring_with_len(int(n)).clone() }
}

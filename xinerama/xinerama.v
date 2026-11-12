module xinerama

import vx11

// Screen is a V-owned snapshot of one Xinerama head, in root-window coordinates.
// The number is not necessarily an Xlib screen number or a stable monitor ID.
pub struct Screen {
pub:
	number int
	x      int
	y      int
	width  int
	height int
}

// Extension borrows its connection. It has no resources to close independently.
@[heap; noinit]
pub struct Extension {
	connection &vx11.Connection
pub:
	event_base int
	error_base int
	major      int
	minor      int
}

pub fn available(connection &vx11.Connection) !bool {
	mut event_base := i32(0)
	mut error_base := i32(0)
	return query_extension(connection.raw()!, &event_base, &error_base) != 0
}

// bind fails when the server does not advertise Xinerama. Presence and activity
// are separate: an installed but inactive extension returns an empty screen list.
pub fn bind(connection &vx11.Connection) !&Extension {
	display := connection.raw()!
	mut event_base := i32(0)
	mut error_base := i32(0)
	if query_extension(display, &event_base, &error_base) == 0 {
		return error('Xinerama extension is unavailable')
	}
	mut major := i32(0)
	mut minor := i32(0)
	if query_version(display, &major, &minor) == 0 { return error('cannot query Xinerama version') }
	return &Extension{ connection: connection, event_base: int(event_base), error_base: int(error_base), major: int(major), minor: int(minor) }
}

pub fn (e &Extension) active() !bool { return is_active(e.connection.raw()!) != 0 }

// screens copies the server's list and releases its Xlib allocation. An inactive
// extension returns []; do not cache this list across monitor layout changes.
pub fn (e &Extension) screens() ![]Screen {
	mut count := i32(0)
	p := query_screens(e.connection.raw()!, &count)
	if p == unsafe { nil } {
		if count != 0 { return error('invalid Xinerama screen list') }
		return []Screen{}
	}
	defer { vx11.free(p) }
	if count < 0 { return error('invalid Xinerama screen count') }
	mut screens := []Screen{cap: int(count)}
	for i in 0 .. int(count) {
		s := unsafe { p[i] }
		screens << Screen{ number: int(s.screen_number), x: int(s.x_org), y: int(s.y_org), width: int(s.width), height: int(s.height) }
	}
	return screens
}

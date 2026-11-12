module shape

import vx11

pub enum Kind {
	bounding
	clip
	input
}

pub enum Operation {
	set
	union_
	intersect
	subtract
	invert
}

// Rectangle uses native integers; conversion checks the protocol's 16-bit limits.
pub struct Rectangle {
pub:
	x      int
	y      int
	width  int
	height int
}

pub struct Extents {
pub:
	bounding_shaped bool
	bounding        Rectangle
	clip_shaped     bool
	clip            Rectangle
}

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
	mut events := i32(0)
	mut errors := i32(0)
	return query_extension(connection.raw()!, &events, &errors) != 0
}

pub fn bind(connection &vx11.Connection) !&Extension {
	d := connection.raw()!
	mut events := i32(0)
	mut errors := i32(0)
	if query_extension(d, &events, &errors) == 0 { return error('SHAPE extension is unavailable') }
	mut major := i32(0)
	mut minor := i32(0)
	if query_version(d, &major, &minor) == 0 { return error('cannot query SHAPE version') }
	return &Extension{ connection: connection, event_base: int(events), error_base: int(errors), major: int(major), minor: int(minor) }
}

fn (e &Extension) check_kind(kind Kind) ! {
	if kind == .input && (e.major < 1 || (e.major == 1 && e.minor < 1)) {
		return error('input shapes require SHAPE 1.1')
	}
}

// combine uses unsorted rectangles, so callers need not pre-sort a V slice.
// An empty list is an empty region; use reset to restore the default shape.
pub fn (e &Extension) combine(window vx11.Window, kind Kind, rectangles []Rectangle, op Operation) ! {
	e.check_kind(kind)!
	if rectangles.len > 0x7fffffff { return error('too many shape rectangles') }
	mut raw := []vx11.XRectangle{cap: rectangles.len}
	for r in rectangles {
		if r.x < -32768 || r.x > 32767 || r.y < -32768 || r.y > 32767 || r.width < 0 || r.width > 65535 || r.height < 0 || r.height > 65535 {
			return error('rectangle exceeds X11 shape coordinate limits')
		}
		raw << vx11.XRectangle{ x: i16(r.x), y: i16(r.y), width: u16(r.width), height: u16(r.height) }
	}
	combine_rectangles(e.connection.raw()!, window, i32(kind), 0, 0, raw.data, i32(raw.len), i32(op), vx11.unsorted)
}

pub fn (e &Extension) reset(window vx11.Window, kind Kind) ! {
	e.check_kind(kind)!
	combine_mask(e.connection.raw()!, window, i32(kind), 0, 0, 0, shape_set)
}

pub fn (e &Extension) rectangles(window vx11.Window, kind Kind) ![]Rectangle {
	e.check_kind(kind)!
	mut count := i32(0)
	mut ordering := i32(0)
	p := get_rectangles(e.connection.raw()!, window, i32(kind), &count, &ordering)
	defer { if p != unsafe { nil } { vx11.free(p) } }
	if count < 0 || (p == unsafe { nil } && count != 0) {
		return error('invalid shape rectangle list')
	}
	mut result := []Rectangle{cap: int(count)}
	for i in 0 .. int(count) {
		r := unsafe { p[i] }
		result << Rectangle{ x: int(r.x), y: int(r.y), width: int(r.width), height: int(r.height) }
	}
	return result
}

pub fn (e &Extension) extents(window vx11.Window) !Extents {
	mut bs := i32(0)
	mut bx := i32(0)
	mut by := i32(0)
	mut bw := u32(0)
	mut bh := u32(0)
	mut cs := i32(0)
	mut cx := i32(0)
	mut cy := i32(0)
	mut cw := u32(0)
	mut ch := u32(0)
	if query_extents(e.connection.raw()!, window, &bs, &bx, &by, &bw, &bh, &cs, &cx, &cy, &cw, &ch) == 0 {
		return error('cannot query shape extents')
	}
	return Extents{ bounding_shaped: bs != 0, bounding: Rectangle{int(bx), int(by), int(bw), int(bh)}, clip_shaped: cs != 0, clip: Rectangle{int(cx), int(cy), int(cw), int(ch)} }
}

pub fn (e &Extension) watch(window vx11.Window, enabled bool) ! {
	select_input(e.connection.raw()!, window, if enabled {
		vx11.CULong(notify_mask)
	} else {
		vx11.CULong(0)
	})
}

// event copies the extension event after checking its server-assigned type.
pub fn (e &Extension) event(event vx11.Event) ?XShapeEvent {
	if event.kind != e.event_base + notify { return none }
	return unsafe { *(&XShapeEvent(&event.raw)) }
}

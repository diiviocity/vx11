module vx11

// Property owns V copies. Xlib's format-32 elements are C unsigned longs, even
// on 64-bit hosts; the protocol payload is still 32 bits per element.
pub struct Property {
pub:
	typ    Atom
	format int
	bytes  []u8
	shorts []u16
	words  []u32
}

pub fn (w &WindowHandle) set_property_bytes(property Atom, typ Atom, data []u8) ! {
	if data.len > 0x7fffffff { return error('property is too large') }
	change_property(w.display()!, w.id, property, typ, 8, prop_mode_replace, data.data, i32(data.len))
}

pub fn (w &WindowHandle) set_property_words(property Atom, typ Atom, data []u32) ! {
	if data.len > 0x7fffffff { return error('property is too large') }
	longs := data.map(CULong(it))
	change_property(w.display()!, w.id, property, typ, 32, prop_mode_replace, longs.data, i32(longs.len))
}

pub fn (w &WindowHandle) delete_property(property Atom) ! {
	delete_property(w.display()!, w.id, property)
}

// property copies up to 16 MiB. Larger properties return an error rather than
// silently truncate. Use get_window_property for streaming arbitrary sizes.
pub fn (w &WindowHandle) property(property Atom) !Property {
	mut typ := Atom(0)
	mut format := i32(0)
	mut count := CULong(0)
	mut remaining := CULong(0)
	mut data := unsafe { &u8(nil) }
	status := get_window_property(w.display()!, w.id, property, 0, 4 * 1024 * 1024, 0, 0, &typ, &format, &count, &remaining, &data)
	defer { if data != unsafe { nil } { free(data) } }
	if status != 0 { return error('XGetWindowProperty failed: ${status}') }
	if typ == 0 { return error('property does not exist') }
	if remaining != 0 { return error('property exceeds 16 MiB convenience limit') }
	mut bytes := []u8{}
	mut shorts := []u16{}
	mut words := []u32{}
	match format {
		8 {
			for i in 0 .. int(count) { bytes << unsafe { data[i] } }
		}
		16 {
			p := unsafe { &u16(data) }
			for i in 0 .. int(count) { shorts << unsafe { p[i] } }
		}
		32 {
			p := unsafe { &CULong(data) }
			for i in 0 .. int(count) { words << u32(unsafe { p[i] }) }
		}
		else { return error('unexpected property format ${format}') }
	}
	return Property{typ, int(format), bytes, shorts, words}
}

pub fn (p Property) text() !string {
	if p.format != 8 { return error('property is not byte text') }
	return p.bytes.bytestr()
}
